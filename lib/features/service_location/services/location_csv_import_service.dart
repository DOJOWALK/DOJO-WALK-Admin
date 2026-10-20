import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/service_location_models.dart';
import 'location_csv_import_fingerprint.dart';
import 'location_csv_import_planner.dart';
import 'location_csv_preview_parser.dart';
import 'service_location_service.dart';

/// Validates a caller-owned ID that must remain unchanged across retries
/// of the same logical CSV import.
/// Signals a failure before the durable import run or any hierarchy write exists.
class LocationCsvImportPreflightException implements Exception {
  final Object cause;
  const LocationCsvImportPreflightException(this.cause);

  @override
  String toString() => 'Import preflight failed before any location writes: $cause';
}

String validateLocationCsvImportRunId(String value) {
  final id = value.trim();
  if (!RegExp(r'^[A-Za-z0-9_-]{1,150}$').hasMatch(id)) {
    throw ArgumentError(
      'Import run ID must contain 1–150 letters, numbers, underscores or hyphens.',
    );
  }
  return id;
}

/// Classifies an import failure conservatively when remote callable outcomes
/// may be uncertain. A write attempt is treated as potentially partial even
/// if the client never received a successful response.
/// Prevents a reused immutable audit ID from triggering location writes.
/// A retry with a persisted audit record needs an explicit reconciliation flow.
void ensureLocationCsvImportRunIsNew({required bool auditRecordExists}) {
  if (auditRecordExists) {
    throw StateError(
      'This import run ID already has an audit record. Existing import runs '
      'are immutable; reconcile the prior run before starting another attempt.',
    );
  }
}

String classifyLocationCsvImportFailure({
  required bool allLocationWritesCompleted,
  required bool locationWriteAttempted,
}) {
  if (allLocationWritesCompleted) return 'audit_failed';
  if (locationWriteAttempted) return 'partial_failure';
  return 'failed';
}

/// Executes a validated State → District → City → Area import.
///
/// Existing records are resolved by their complete parent/name path. New IDs
/// are deterministic to reduce duplicate-path risk after interruption, but
/// automatic retries are blocked by immutable audit records until reconciliation
/// is implemented. All writes go through ServiceLocationService,
/// which calls the trusted Firebase callable. This class never activates a
/// location or creates boundaries.
class LocationCsvImportService {
  final FirebaseFirestore _firestore;
  final ServiceLocationService _locations;
  final LocationCsvImportPlanner _planner;
  final String? Function() _currentAdminIdProvider;
  final void Function(Object error, StackTrace stackTrace) _onAuditFailure;

  LocationCsvImportService({
    FirebaseFirestore? firestore,
    ServiceLocationService? locations,
    LocationCsvImportPlanner? planner,
    String? Function()? currentAdminIdProvider,
    void Function(Object error, StackTrace stackTrace)? onAuditFailure,
  })  : _onAuditFailure = onAuditFailure ?? _logAuditFailure,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _currentAdminIdProvider = currentAdminIdProvider ??
            (() => FirebaseAuth.instance.currentUser?.uid),
        _locations = locations ??
            ServiceLocationService(
              currentUserIdProvider: currentAdminIdProvider ??
                  (() => FirebaseAuth.instance.currentUser?.uid),
            ),
        _planner = planner ?? LocationCsvImportPlanner();

  Future<LocationCsvImportResult> importPreview({
    required LocationCsvPreview preview,
    required String countryId,
    required String fileName,
    required String importRunId,
  }) async {
    if (!preview.isSyntacticallyValid) {
      throw ArgumentError('Fix all CSV preview errors before importing.');
    }
    if (preview.rows.isEmpty) {
      throw ArgumentError('CSV contains no data rows to import.');
    }
    final country = countryId.trim();
    if (country.isEmpty) throw ArgumentError('Country ID is required.');
    final sourceFileName = fileName.trim();
    if (sourceFileName.isEmpty) {
      throw ArgumentError('A CSV file name is required for the import audit.');
    }
    // The caller must persist and reuse this ID when retrying the same logical
    // import. Reusing it prevents an ambiguous audit-write timeout from
    // creating a second audit document on retry.
    final runId = validateLocationCsvImportRunId(importRunId);
    final inputFingerprint = locationCsvImportFingerprint(
      countryId: country,
      preview: preview,
    );
    // Complete authorization and read-only preflight before creating a
    // durable run marker. Failures here mean no location write was attempted.
    final actor = _currentAdminId;
    late final List<LocationImportPlannedNode> plan;
    try {
      await _requireSuperAdmin(actor);

      // Existing audit IDs are immutable and cannot be reused for another run.
      final priorRun = await _firestore
          .collection('service_location_imports')
          .doc(runId)
          .get();
      ensureLocationCsvImportRunIsNew(auditRecordExists: priorRun.exists);

      final existing = await _loadExistingPathIds(country);
      plan = _planner.plan(
        preview: preview,
        countryId: country,
        existingIdsByPath: existing,
        allocateId: (pathKey) =>
            LocationImportPlannedNode.stableDocumentId(country, pathKey),
      );
      if (plan.length > 300) {
        throw StateError(
          'This CSV expands to ${plan.length} location records; one import run '
          'supports at most 300. Split the data into smaller, parent-complete '
          'CSV imports and use a new import run ID for each file.',
        );
      }
    } catch (error) {
      throw LocationCsvImportPreflightException(error);
    }

    // Persist a trusted run marker only after read-only preflight passes and
    // before the first plan or hierarchy write. If a callable times out, the
    // run remains visible and a second attempt is blocked until reconciliation.
    await _locations.beginImportRun(
      runId: runId,
      countryId: country,
      fileName: sourceFileName,
      inputFingerprint: inputFingerprint,
    );

    var plannedRecords = plan.length;
    var created = 0;
    var reused = 0;
    var auditWritten = false;
    var locationWriteAttempted = false;
    var allLocationWritesCompleted = false;

    try {
      // Plan and the 300-record bound were validated before run creation.
      // The trusted backend records the complete bounded plan before the first
      // location write. If recording fails or is ambiguous, this run is blocked
      // for manual reconciliation; the importer never auto-resumes it.
      await _locations.recordImportPlan(
        runId: runId,
        inputFingerprint: inputFingerprint,
        nodes: plan
            .map((node) => <String, dynamic>{
                  'id': node.id,
                  'type': node.type.name,
                  'name': node.name,
                  'parentId': node.parentId,
                  'alreadyExists': node.alreadyExists,
                  'sourceLine': node.firstSourceLine,
                })
            .toList(growable: false),
      );
      for (final node in plan) {
        if (node.alreadyExists) {
          reused++;
          continue;
        }
        // A callable can commit on the server and still return a client-side
        // timeout/error. Mark the attempt before awaiting it so the failure
        // audit never falsely claims "failed with no writes" in that case.
        locationWriteAttempted = true;
        switch (node.type) {
          case LocationImportNodeType.state:
            await _locations.saveState(ServiceState(
              id: node.id,
              countryId: country,
              name: node.name,
              isActive: false,
            ));
            break;
          case LocationImportNodeType.district:
            await _locations.saveDistrict(ServiceDistrict(
              id: node.id,
              countryId: country,
              stateId: node.parentId,
              name: node.name,
              isActive: false,
            ));
            break;
          case LocationImportNodeType.city:
            final district = plan.firstWhere((candidate) =>
                candidate.type == LocationImportNodeType.district &&
                candidate.id == node.parentId);
            await _locations.saveCity(ServiceCity(
              id: node.id,
              countryId: country,
              stateId: district.parentId,
              districtId: node.parentId,
              name: node.name,
              isServiceActive: false,
            ));
            break;
          case LocationImportNodeType.area:
            final city = plan.firstWhere((candidate) =>
                candidate.type == LocationImportNodeType.city &&
                candidate.id == node.parentId);
            final district = plan.firstWhere((candidate) =>
                candidate.type == LocationImportNodeType.district &&
                candidate.id == city.parentId);
            await _locations.saveArea(ServiceArea(
              id: node.id,
              countryId: country,
              stateId: district.parentId,
              cityId: node.parentId,
              name: node.name,
              isServiceActive: false,
            ));
            break;
        }
        created++;
      }

      allLocationWritesCompleted = true;

      // The trusted finalization callable atomically commits both the
      // terminal run state and the immutable operator-facing audit record.
      // This avoids a timeout leaving a completed run with a missing/conflicting
      // client-written audit summary.
      await _locations.finishImportRun(
        runId: runId,
        inputFingerprint: inputFingerprint,
        status: 'completed',
        plannedRecords: plan.length,
        createdRecords: created,
        reusedRecords: reused,
      );
      auditWritten = true;

      return LocationCsvImportResult(
        plannedRecords: plan.length,
        createdRecords: created,
        reusedRecords: reused,
        auditWritten: auditWritten,
      );
    } catch (error, stackTrace) {
      // Failure status and audit are written together by the trusted
      // finalization callable. If the response was ambiguous, the server
      // rejects a conflicting terminal state and preserves its original audit.
      try {
        await _locations.finishImportRun(
          runId: runId,
          inputFingerprint: inputFingerprint,
          status: auditWritten
              ? 'completed'
              : classifyLocationCsvImportFailure(
                  allLocationWritesCompleted: allLocationWritesCompleted,
                  locationWriteAttempted: locationWriteAttempted,
                ),
          plannedRecords: plannedRecords,
          createdRecords: created,
          reusedRecords: reused,
        );
      } catch (runStateError, runStateStackTrace) {
        try {
          _onAuditFailure(runStateError, runStateStackTrace);
        } catch (_) {
          // Keep the original import error authoritative.
        }
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  static void _logAuditFailure(Object error, StackTrace stackTrace) {
    debugPrint('DOJO WALK location CSV audit write failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  String get _currentAdminId {
    final id = _currentAdminIdProvider()?.trim() ?? '';
    if (id.isEmpty) {
      throw StateError('Sign in as an admin before importing locations.');
    }
    return id;
  }

  Future<void> _requireSuperAdmin(String actorId) async {
    final actor = await _firestore.collection('admin_users').doc(actorId).get();
    final data = actor.data();
    if (!actor.exists || data == null || data['isActive'] != true ||
        data['role'] != 'super_admin') {
      throw StateError(
        'CSV location import is restricted to an active super_admin account.',
      );
    }
  }

  Future<Map<String, String>> _loadExistingPathIds(String countryId) async {
    final states = await _firestore
        .collection('service_states')
        .where('countryId', isEqualTo: countryId)
        .get();
    final districts = await _firestore
        .collection('service_districts')
        .where('countryId', isEqualTo: countryId)
        .get();
    final cities = await _firestore
        .collection('service_cities')
        .where('countryId', isEqualTo: countryId)
        .get();
    final areas = await _firestore
        .collection('service_areas')
        .where('countryId', isEqualTo: countryId)
        .get();

    final result = <String, String>{};
    final stateNamesById = <String, String>{};
    final districtNamesById = <String, String>{};
    final cityNamesById = <String, String>{};
    final districtStateById = <String, String>{};
    final cityDistrictById = <String, String>{};

    void addUnique(LocationImportNodeType type, List<String> segments, String id) {
      final key = LocationImportPlannedNode.pathKey(type, segments);
      final prior = result[key];
      if (prior != null && prior != id) {
        throw StateError('Ambiguous existing location path detected. Resolve duplicate records before importing: $key');
      }
      result[key] = id;
    }

    for (final doc in states.docs) {
      final name = doc.data()['name']?.toString().trim() ?? '';
      if (name.isEmpty) continue;
      stateNamesById[doc.id] = name;
      addUnique(LocationImportNodeType.state, [name], doc.id);
    }
    for (final doc in districts.docs) {
      final data = doc.data();
      final stateId = data['stateId']?.toString() ?? '';
      final stateName = stateNamesById[stateId];
      final name = data['name']?.toString().trim() ?? '';
      if (stateName == null || name.isEmpty) continue;
      districtNamesById[doc.id] = name;
      districtStateById[doc.id] = stateId;
      addUnique(LocationImportNodeType.district, [stateName, name], doc.id);
    }
    for (final doc in cities.docs) {
      final data = doc.data();
      final stateId = data['stateId']?.toString() ?? '';
      final districtId = data['districtId']?.toString() ?? '';
      final stateName = stateNamesById[stateId];
      final districtName = districtNamesById[districtId];
      final name = data['name']?.toString().trim() ?? '';
      // Only map cities with an explicit district parent. Legacy cities with
      // no districtId must not be silently treated as a match for an import.
      if (stateName == null || districtName == null || name.isEmpty ||
          districtStateById[districtId] != stateId) continue;
      cityNamesById[doc.id] = name;
      cityDistrictById[doc.id] = districtId;
      addUnique(LocationImportNodeType.city, [stateName, districtName, name], doc.id);
    }
    for (final doc in areas.docs) {
      final data = doc.data();
      final cityId = data['cityId']?.toString() ?? '';
      final cityName = cityNamesById[cityId];
      final districtId = cityDistrictById[cityId];
      final districtName = districtNamesById[districtId];
      final stateId = districtStateById[districtId];
      final stateName = stateNamesById[stateId];
      final name = data['name']?.toString().trim() ?? '';
      if (cityName == null || districtName == null ||
          stateName == null || name.isEmpty) continue;
      addUnique(LocationImportNodeType.area,
          [stateName, districtName, cityName, name], doc.id);
    }
    return result;
  }


}

class LocationCsvImportResult {
  final int plannedRecords;
  final int createdRecords;
  final int reusedRecords;
  final bool auditWritten;

  const LocationCsvImportResult({
    required this.plannedRecords,
    required this.createdRecords,
    required this.reusedRecords,
    required this.auditWritten,
  });
}


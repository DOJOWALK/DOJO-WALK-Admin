import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/service_location_models.dart';
import 'location_csv_import_planner.dart';
import 'location_csv_preview_parser.dart';
import 'service_location_service.dart';

/// Validates a caller-owned ID that must remain unchanged across retries
/// of the same logical CSV import.
String validateLocationCsvImportRunId(String value) {
  final id = value.trim();
  if (id.isEmpty || id.contains('/')) {
    throw ArgumentError('A stable, valid import run ID is required.');
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
    // Fail before querying or writing anything if the admin is signed out.
    final actor = _currentAdminId;

    // Firestore Rules intentionally limit direct hierarchy reads and import
    // audit access to super_admin. Enforce that contract before any location
    // reads/writes; do not rely on the later callable to reject an admin role.
    await _requireSuperAdmin(actor);

    // Check the immutable audit ID before any hierarchy reads or writes. This
    // prevents a reused run ID from repeating location writes only to fail on
    // the final append-only audit create. Reconciliation is a separate flow.
    final priorRun = await _firestore
        .collection('service_location_imports')
        .doc(runId)
        .get();
    ensureLocationCsvImportRunIsNew(auditRecordExists: priorRun.exists);

    var created = 0;
    var reused = 0;
    var auditWritten = false;
    var locationWriteAttempted = false;
    var allLocationWritesCompleted = false;

    try {
      // Include hierarchy reads and planning in the guarded import flow. If
      // preflight is denied or finds ambiguous paths, surface the same failure
      // path instead of escaping before import error handling.
      final existing = await _loadExistingPathIds(country);
      final plan = _planner.plan(
        preview: preview,
        countryId: country,
        existingIdsByPath: existing,
        allocateId: (pathKey) =>
            LocationImportPlannedNode.stableDocumentId(country, pathKey),
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

      // Audit records are append-only under the current Firestore rules.
      // Write one immutable final summary instead of trying to update a
      // "started" record later. If this write fails or its outcome is
      // ambiguous, deterministic location IDs reduce duplicate-path risk, but
      // the import is NOT automatically retryable: audit reconciliation is
      // still required before reusing this logical run ID.
      await _locations.saveImport(ServiceLocationImport(
        id: runId,
        source: 'csv',
        fileName: sourceFileName,
        status: 'completed',
        importedBy: actor,
        verificationStatus: 'pending',
      ));
      auditWritten = true;

      return LocationCsvImportResult(
        plannedRecords: plan.length,
        createdRecords: created,
        reusedRecords: reused,
        auditWritten: auditWritten,
      );
    } catch (error, stackTrace) {
      // Record an immutable failure summary after any partial writes. The
      // record does not claim rollback: previously saved locations remain
      // inactive. Deterministic IDs help identify/reuse existing paths, but a
      // prior failure audit blocks this run ID until reconciliation is added.
      try {
        await _locations.saveImport(ServiceLocationImport(
          id: runId,
          source: 'csv',
          fileName: fileName.trim(),
          status: classifyLocationCsvImportFailure(
            allLocationWritesCompleted: allLocationWritesCompleted,
            locationWriteAttempted: locationWriteAttempted,
          ),
          importedBy: actor,
          verificationStatus: 'pending',
        ));
      } catch (auditError, auditStackTrace) {
        // Preserve the original import exception, but do not silently discard
        // the separate audit-write failure. The default handler logs both;
        // tests/hosts may inject a durable telemetry adapter.
        try {
          _onAuditFailure(auditError, auditStackTrace);
        } catch (_) {
          // A broken telemetry adapter must not mask the original import error.
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

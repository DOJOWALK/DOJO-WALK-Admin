import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/service_location_models.dart';
import 'location_csv_import_planner.dart';
import 'location_csv_preview_parser.dart';
import 'service_location_service.dart';

/// Executes a validated State → District → City → Area import.
///
/// Existing records are resolved by their complete parent/name path. New IDs
/// are deterministic so an interrupted import can be retried without creating
/// a second set of documents. All writes go through ServiceLocationService,
/// which calls the trusted Firebase callable. This class never activates a
/// location or creates boundaries.
class LocationCsvImportService {
  final FirebaseFirestore _firestore;
  final ServiceLocationService _locations;
  final LocationCsvImportPlanner _planner;

  LocationCsvImportService({
    FirebaseFirestore? firestore,
    ServiceLocationService? locations,
    LocationCsvImportPlanner? planner,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _locations = locations ?? ServiceLocationService(),
        _planner = planner ?? LocationCsvImportPlanner();

  Future<LocationCsvImportResult> importPreview({
    required LocationCsvPreview preview,
    required String countryId,
    required String fileName,
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
    // Fail before querying or writing anything if the admin is signed out.
    final actor = _currentAdminId;

    var created = 0;
    var reused = 0;
    var auditWritten = false;
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
      // "started" record later. If this write fails, the caller is told the
      // import may have completed without an audit record and can reconcile
      // by retrying the same CSV (deterministic IDs prevent duplicate paths).
      await _locations.saveImport(ServiceLocationImport(
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
    } catch (error) {
      // Record an immutable failure summary after any partial writes. The
      // record does not claim rollback: previously saved locations remain
      // inactive and deterministic IDs make the next attempt reconcilable.
      try {
        await _locations.saveImport(ServiceLocationImport(
          source: 'csv',
          fileName: fileName.trim(),
          status: allLocationWritesCompleted
              ? 'audit_failed'
              : (created > 0 ? 'partial_failure' : 'failed'),
          importedBy: actor,
          verificationStatus: 'pending',
        ));
      } catch (_) {
        // Preserve the original import error. Audit failure is surfaced in
        // logs/operations separately; the PR remains Draft until this is
        // covered by authenticated emulator tests.
      }
      Error.throwWithStackTrace(error, StackTrace.current);
    }
  }

  String get _currentAdminId {
    final id = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    if (id.isEmpty) {
      throw StateError('Sign in as an admin before importing locations.');
    }
    return id;
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

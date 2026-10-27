import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/service_location_zone.dart';

/// Client wrapper for the Zone callables defined by Firebase PR #39.
///
/// This class intentionally does not write Zone workflow fields directly.
/// Trusted callable functions own authorization, name indexes, boundary
/// validation, Founder approval, activation and audit records.
class ServiceLocationZoneService {
  ServiceLocationZoneService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'asia-south1');

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _zones =>
      _firestore.collection('service_zones');

  Stream<List<ServiceLocationZone>> watchZones({
    String? cityId,
  }) {
    Query<Map<String, dynamic>> query = _zones.orderBy('name');
    final normalizedCityId = cityId?.trim();
    if (normalizedCityId != null && normalizedCityId.isNotEmpty) {
      query = query.where('cityId', isEqualTo: normalizedCityId);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ServiceLocationZone.fromMap(doc.id, doc.data()))
          .toList(growable: false);
    });
  }

  Future<String> saveZoneDraft({
    String? zoneId,
    required String name,
    required String stateId,
    required String districtId,
    required String cityId,
  }) async {
    final normalizedName = name.trim();
    final normalizedStateId = stateId.trim();
    final normalizedDistrictId = districtId.trim();
    final normalizedCityId = cityId.trim();
    if (normalizedName.isEmpty ||
        normalizedStateId.isEmpty ||
        normalizedDistrictId.isEmpty ||
        normalizedCityId.isEmpty) {
      throw ArgumentError(
        'Zone name, State/UT, District and City are required.',
      );
    }

    final id = zoneId?.trim().isNotEmpty == true
        ? zoneId!.trim()
        : _zones.doc().id;
    final result = await _functions
        .httpsCallable('saveServiceLocationWithNameIndex')
        .call<Map<String, dynamic>>({
      'locationType': 'zone',
      'locationId': id,
      'payload': {
        'name': normalizedName,
        'stateId': normalizedStateId,
        'districtId': normalizedDistrictId,
        'cityId': normalizedCityId,
      },
    });
    final savedId = result.data['locationId']?.toString();
    if (savedId != id) {
      throw StateError(
        'Firebase returned an unexpected Zone ID; expected $id, got $savedId.',
      );
    }
    return id;
  }

  Future<void> submitForFounderReview(String zoneId) async {
    await _functions.httpsCallable('submitServiceZoneForFounderReview').call({
      'zoneId': _required(zoneId, 'Zone ID'),
    });
  }

  Future<void> decideFounderApproval({
    required String zoneId,
    required String decision,
    required String notes,
  }) async {
    const allowed = {
      'approve',
      'reject',
      'changes_required',
      'deactivate',
      'reactivate',
    };
    if (!allowed.contains(decision)) {
      throw ArgumentError('Unsupported Founder decision: $decision');
    }
    final normalizedNotes = notes.trim();
    if (normalizedNotes.length > 2000 ||
        (decision != 'approve' && normalizedNotes.isEmpty)) {
      throw ArgumentError(
        'A note is required for this decision and must not exceed 2000 characters.',
      );
    }
    await _functions.httpsCallable('decideServiceZoneFounderApproval').call({
      'zoneId': _required(zoneId, 'Zone ID'),
      'decision': decision,
      'notes': normalizedNotes,
    });
  }

  Future<void> activateZone(String zoneId) async {
    await _functions.httpsCallable('activateServiceZone').call({
      'zoneId': _required(zoneId, 'Zone ID'),
    });
  }

  Future<void> requestDeactivation({
    required String zoneId,
    required String notes,
  }) async {
    final normalizedNotes = notes.trim();
    if (normalizedNotes.isEmpty || normalizedNotes.length > 2000) {
      throw ArgumentError(
        'A deactivation reason is required (maximum 2000 characters).',
      );
    }
    await _functions.httpsCallable('requestServiceZoneDeactivation').call({
      'zoneId': _required(zoneId, 'Zone ID'),
      'notes': normalizedNotes,
    });
  }

  Future<void> executeApprovedDeactivation(String zoneId) async {
    await _functions.httpsCallable('setServiceLocationStatus').call({
      'locationType': 'zone',
      'locationId': _required(zoneId, 'Zone ID'),
      'isActive': false,
    });
  }

  Future<void> suspendForEmergency({
    required String zoneId,
    required String reason,
    required String severity,
  }) async {
    const severities = {'SEV-1', 'SEV-2', 'SEV-3', 'SEV-4'};
    final normalizedReason = reason.trim();
    if (normalizedReason.isEmpty || normalizedReason.length > 2000) {
      throw ArgumentError(
        'An emergency suspension reason is required (maximum 2000 characters).',
      );
    }
    if (!severities.contains(severity)) {
      throw ArgumentError('Unsupported emergency severity: $severity');
    }
    await _functions.httpsCallable('suspendServiceZoneForEmergency').call({
      'zoneId': _required(zoneId, 'Zone ID'),
      'reason': normalizedReason,
      'severity': severity,
    });
  }

  String _required(String value, String label) {
    final normalized = value.trim();
    if (normalized.isEmpty) throw ArgumentError('$label is required.');
    return normalized;
  }
}

/// Parent fields sent to the trusted Firebase name-index callable.
///
/// City includes districtId when it is explicitly linked and keeps the
/// backward-compatible two-parent tuple when districtId is absent. Area and
/// Locality send their legacy parent fields; Firebase derives District
/// ancestry from trusted Firestore documents and atomically maintains both
/// legacy and District-aware indexes for District-linked records.
List<String> serviceLocationIndexParentFields(
  String locationType,
  Map<String, dynamic> payload,
) {
  switch (locationType) {
    case 'country':
      return const [];
    case 'state':
      return const ['countryId'];
    case 'district':
      return const ['countryId', 'stateId'];
    case 'city':
      final rawDistrictId = payload['districtId'];
      if (rawDistrictId != null && rawDistrictId is! String) {
        throw ArgumentError.value(
          rawDistrictId,
          'payload.districtId',
          'District ID must be a string when provided.',
        );
      }
      final districtId = (rawDistrictId as String?)?.trim() ?? '';
      return districtId.isNotEmpty
          ? const ['countryId', 'stateId', 'districtId']
          : const ['countryId', 'stateId'];
    case 'area':
      return const ['countryId', 'stateId', 'cityId'];
    case 'locality':
      return const ['countryId', 'stateId', 'cityId', 'areaId'];
    default:
      throw ArgumentError.value(locationType, 'locationType', 'Unsupported service location type.');
  }
}

/// Remove an optional blank City District ID before sending the callable
/// payload. Firebase treats an explicitly present District ID as a parent
/// requirement, so an empty string must be represented as an absent field.
Map<String, dynamic> normalizeServiceLocationIndexPayload(
  String locationType,
  Map<String, dynamic> payload,
) {
  final normalized = Map<String, dynamic>.from(payload);
  if (locationType == 'city' && normalized.containsKey('districtId')) {
    final rawDistrictId = normalized['districtId'];
    if (rawDistrictId != null && rawDistrictId is! String) {
      throw ArgumentError.value(
        rawDistrictId,
        'payload.districtId',
        'District ID must be a string when provided.',
      );
    }
    final districtId = (rawDistrictId as String?)?.trim() ?? '';
    if (districtId.isEmpty) {
      normalized.remove('districtId');
    } else {
      normalized['districtId'] = districtId;
    }
  }
  return normalized;
}

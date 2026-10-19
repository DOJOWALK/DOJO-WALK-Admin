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
      final districtId = payload['districtId']?.toString().trim() ?? '';
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

/// Parent-field contract sent to the trusted Firebase name-index callable.
///
/// City keeps a backward-compatible two-parent tuple when districtId is
/// absent. Area and Locality stay on the legacy tuple until the coordinated
/// dual-index migration is approved and implemented on the server.
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

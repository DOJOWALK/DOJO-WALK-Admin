/// Immutable selection state for the Add Location parent dropdowns.
///
/// Changing a parent clears all selections below it so stale child IDs cannot
/// accidentally be submitted under a different parent.
class LocationSelectionState {
  const LocationSelectionState({
    this.countryId,
    this.stateId,
    this.cityId,
    this.areaId,
  });

  final String? countryId;
  final String? stateId;
  final String? cityId;
  final String? areaId;

  LocationSelectionState selectCountry(String? value) =>
      LocationSelectionState(countryId: value);

  LocationSelectionState selectState(String? value) =>
      LocationSelectionState(countryId: countryId, stateId: value);

  LocationSelectionState selectCity(String? value) => LocationSelectionState(
        countryId: countryId,
        stateId: stateId,
        cityId: value,
      );

  LocationSelectionState selectArea(String? value) => LocationSelectionState(
        countryId: countryId,
        stateId: stateId,
        cityId: cityId,
        areaId: value,
      );
}

/// Returns a selected ID only while it exists in the latest option list.
///
/// This prevents dropdowns from retaining a value whose document was deleted
/// or removed from the current parent-filtered query.
String? retainAvailableSelection(
  String? selectedId,
  Iterable<String> availableIds,
) {
  if (selectedId == null || !availableIds.contains(selectedId)) return null;
  return selectedId;
}

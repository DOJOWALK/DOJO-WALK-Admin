import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/models/location_selection_state.dart';

void main() {
  group('LocationSelectionState', () {
    test('changing country clears state, city, and area', () {
      const current = LocationSelectionState(
        countryId: 'old-country',
        stateId: 'old-state',
        cityId: 'old-city',
        areaId: 'old-area',
      );

      final next = current.selectCountry('new-country');

      expect(next.countryId, 'new-country');
      expect(next.stateId, isNull);
      expect(next.cityId, isNull);
      expect(next.areaId, isNull);
    });

    test('changing state preserves country and clears city and area', () {
      const current = LocationSelectionState(
        countryId: 'country',
        stateId: 'old-state',
        cityId: 'city',
        areaId: 'area',
      );

      final next = current.selectState('new-state');

      expect(next.countryId, 'country');
      expect(next.stateId, 'new-state');
      expect(next.cityId, isNull);
      expect(next.areaId, isNull);
    });

    test('changing city preserves country and state and clears area', () {
      const current = LocationSelectionState(
        countryId: 'country',
        stateId: 'state',
        cityId: 'old-city',
        areaId: 'area',
      );

      final next = current.selectCity('new-city');

      expect(next.countryId, 'country');
      expect(next.stateId, 'state');
      expect(next.cityId, 'new-city');
      expect(next.areaId, isNull);
    });

    test('changing area preserves all parent selections', () {
      const current = LocationSelectionState(
        countryId: 'country',
        stateId: 'state',
        cityId: 'city',
        areaId: 'old-area',
      );

      final next = current.selectArea('new-area');

      expect(next.countryId, 'country');
      expect(next.stateId, 'state');
      expect(next.cityId, 'city');
      expect(next.areaId, 'new-area');
    });

    test('selecting null parent still clears its descendants', () {
      const current = LocationSelectionState(
        countryId: 'country',
        stateId: 'state',
        cityId: 'city',
        areaId: 'area',
      );

      final next = current.selectState(null);

      expect(next.countryId, 'country');
      expect(next.stateId, isNull);
      expect(next.cityId, isNull);
      expect(next.areaId, isNull);
    });
  });
}

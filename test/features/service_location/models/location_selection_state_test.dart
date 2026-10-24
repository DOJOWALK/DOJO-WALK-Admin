import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/models/location_selection_state.dart';

void main() {
  group('LocationSelectionState', () {
    test('changing country clears every descendant selection', () {
      const current = LocationSelectionState(
        countryId: 'old-country',
        stateId: 'old-state',
        districtId: 'old-district',
        cityId: 'old-city',
        areaId: 'old-area',
      );

      final next = current.selectCountry('new-country');

      expect(next.countryId, 'new-country');
      expect(next.stateId, isNull);
      expect(next.districtId, isNull);
      expect(next.cityId, isNull);
      expect(next.areaId, isNull);
    });

    test('changing state preserves country and clears District, City, Area', () {
      const current = LocationSelectionState(
        countryId: 'country',
        stateId: 'old-state',
        districtId: 'district',
        cityId: 'city',
        areaId: 'area',
      );

      final next = current.selectState('new-state');

      expect(next.countryId, 'country');
      expect(next.stateId, 'new-state');
      expect(next.districtId, isNull);
      expect(next.cityId, isNull);
      expect(next.areaId, isNull);
    });

    test('changing District preserves State and clears City and Area', () {
      const current = LocationSelectionState(
        countryId: 'country',
        stateId: 'state',
        districtId: 'old-district',
        cityId: 'city',
        areaId: 'area',
      );

      final next = current.selectDistrict('new-district');

      expect(next.countryId, 'country');
      expect(next.stateId, 'state');
      expect(next.districtId, 'new-district');
      expect(next.cityId, isNull);
      expect(next.areaId, isNull);
    });

    test('changing city preserves its parent hierarchy and clears Area', () {
      const current = LocationSelectionState(
        countryId: 'country',
        stateId: 'state',
        districtId: 'district',
        cityId: 'old-city',
        areaId: 'area',
      );

      final next = current.selectCity('new-city');

      expect(next.countryId, 'country');
      expect(next.stateId, 'state');
      expect(next.districtId, 'district');
      expect(next.cityId, 'new-city');
      expect(next.areaId, isNull);
    });

    test('changing area preserves all parent selections', () {
      const current = LocationSelectionState(
        countryId: 'country',
        stateId: 'state',
        districtId: 'district',
        cityId: 'city',
        areaId: 'old-area',
      );

      final next = current.selectArea('new-area');

      expect(next.countryId, 'country');
      expect(next.stateId, 'state');
      expect(next.districtId, 'district');
      expect(next.cityId, 'city');
      expect(next.areaId, 'new-area');
    });

    test('deleted selected ID is invalidated', () {
      expect(
        retainAvailableSelection('deleted-country', ['country-a', 'country-b']),
        isNull,
      );
    });

    test('available selected ID is preserved', () {
      expect(
        retainAvailableSelection('country-b', ['country-a', 'country-b']),
        'country-b',
      );
    });

    test('null selection remains null', () {
      expect(retainAvailableSelection(null, ['country-a']), isNull);
    });

    test('selecting null parent clears all descendants', () {
      const current = LocationSelectionState(
        countryId: 'country',
        stateId: 'state',
        districtId: 'district',
        cityId: 'city',
        areaId: 'area',
      );

      final next = current.selectState(null);

      expect(next.countryId, 'country');
      expect(next.stateId, isNull);
      expect(next.districtId, isNull);
      expect(next.cityId, isNull);
      expect(next.areaId, isNull);
    });
  });
}

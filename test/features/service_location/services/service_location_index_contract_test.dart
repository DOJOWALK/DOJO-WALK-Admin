import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/services/service_location_index_contract.dart';

void main() {
  group('service location index parent-field contract', () {
    test('District-linked City includes District after State', () {
      expect(
        serviceLocationIndexParentFields('city', {
          'countryId': 'country-1',
          'stateId': 'state-1',
          'districtId': 'district-1',
        }),
        ['countryId', 'stateId', 'districtId'],
      );
    });

    test('legacy City without District keeps two-parent compatibility', () {
      expect(
        serviceLocationIndexParentFields('city', {
          'countryId': 'country-1',
          'stateId': 'state-1',
        }),
        ['countryId', 'stateId'],
      );
    });

    test('blank District ID follows legacy City compatibility path', () {
      expect(
        serviceLocationIndexParentFields('city', {
          'districtId': '  ',
        }),
        ['countryId', 'stateId'],
      );
    });

    test('Area and Locality send legacy parent fields for server-derived dual indexing', () {
      expect(serviceLocationIndexParentFields('area', {}),
          ['countryId', 'stateId', 'cityId']);
      expect(serviceLocationIndexParentFields('locality', {}),
          ['countryId', 'stateId', 'cityId', 'areaId']);
    });

    test('unsupported type fails closed', () {
      expect(
        () => serviceLocationIndexParentFields('unknown', {}),
        throwsArgumentError,
      );
    });
  });
}

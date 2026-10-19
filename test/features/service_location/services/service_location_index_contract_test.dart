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


    test('rejects a non-string District ID instead of coercing it', () {
      expect(
        () => serviceLocationIndexParentFields('city', {
          'countryId': 'country-1',
          'stateId': 'state-1',
          'districtId': 123,
        }),
        throwsArgumentError,
      );
    });


    test('blank optional City District ID is omitted from callable payload', () {
      final normalized = normalizeServiceLocationIndexPayload('city', {
        'countryId': 'country-1',
        'stateId': 'state-1',
        'districtId': '  ',
        'name': 'Legacy City',
      });

      expect(normalized.containsKey('districtId'), isFalse);
      expect(
        serviceLocationIndexParentFields('city', normalized),
        ['countryId', 'stateId'],
      );
    });

    test('nonblank City District ID is trimmed in callable payload', () {
      final normalized = normalizeServiceLocationIndexPayload('city', {
        'countryId': 'country-1',
        'stateId': 'state-1',
        'districtId': ' district-1 ',
        'name': 'District City',
      });

      expect(normalized['districtId'], 'district-1');
      expect(
        serviceLocationIndexParentFields('city', normalized),
        ['countryId', 'stateId', 'districtId'],
      );
    });

    test('non-string optional City District ID fails closed', () {
      expect(
        () => normalizeServiceLocationIndexPayload('city', {
          'districtId': 123,
        }),
        throwsArgumentError,
      );
    });

    test('unsupported type fails closed', () {
      expect(
        () => serviceLocationIndexParentFields('unknown', {}),
        throwsArgumentError,
      );
    });

    test('Country State and District use the canonical ancestor fields', () {
      expect(serviceLocationIndexParentFields('country', {}),
          isEmpty);
      expect(serviceLocationIndexParentFields('state', {}),
          ['countryId']);
      expect(serviceLocationIndexParentFields('district', {}),
          ['countryId', 'stateId']);
    });
  });
}

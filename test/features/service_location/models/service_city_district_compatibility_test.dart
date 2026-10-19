import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/models/service_location_models.dart';

void main() {
  group('ServiceCity District compatibility', () {
    test('legacy City without districtId remains readable', () {
      final city = ServiceCity.fromMap('legacy-city', {
        'countryId': 'country-1',
        'stateId': 'state-1',
        'name': 'Legacy City',
        'isServiceActive': false,
      });

      expect(city.id, 'legacy-city');
      expect(city.districtId, isEmpty);
      expect(city.name, 'Legacy City');
      expect(city.toMap().containsKey('districtId'), isFalse);
    });

    test('District-linked City preserves districtId', () {
      final city = ServiceCity.fromMap('linked-city', {
        'countryId': 'country-1',
        'stateId': 'state-1',
        'districtId': 'district-1',
        'name': 'Linked City',
        'isServiceActive': false,
      });

      expect(city.districtId, 'district-1');
      expect(city.toMap()['districtId'], 'district-1');
    });

    test('copyWith can update the District parent explicitly', () {
      const city = ServiceCity(
        countryId: 'country-1',
        stateId: 'state-1',
        name: 'Linked City',
      );

      expect(city.copyWith(districtId: 'district-2').districtId, 'district-2');
    });
  });

  group('ServiceDistrict trusted status field compatibility', () {
    test('reads canonical isServiceActive status written by Firebase', () {
      final district = ServiceDistrict.fromMap('district-1', {
        'countryId': 'country-1',
        'stateId': 'state-1',
        'name': 'Example District',
        'isServiceActive': true,
      });

      expect(district.isActive, isTrue);
      expect(district.toMap()['isServiceActive'], isTrue);
      expect(district.toMap().containsKey('isActive'), isFalse);
    });


    test('canonical inactive status takes precedence over stale legacy active flag', () {
      final district = ServiceDistrict.fromMap('district-1', {
        'countryId': 'country-1',
        'stateId': 'state-1',
        'name': 'Example District',
        'isServiceActive': false,
        'isActive': true,
      });

      expect(district.isActive, isFalse);
      expect(district.toMap()['isServiceActive'], isFalse);
    });

    test('reads legacy isActive field for existing District records', () {
      final district = ServiceDistrict.fromMap('legacy-district', {
        'countryId': 'country-1',
        'stateId': 'state-1',
        'name': 'Legacy District',
        'isActive': true,
      });

      expect(district.isActive, isTrue);
    });
  });


  test('reads legacy active status for City, Area, and Locality when canonical status is absent', () {
    final city = ServiceCity.fromMap('legacy-city', {
      'countryId': 'country-1',
      'stateId': 'state-1',
      'name': 'Legacy City',
      'isActive': true,
    });
    final area = ServiceArea.fromMap('legacy-area', {
      'countryId': 'country-1',
      'stateId': 'state-1',
      'cityId': 'city-1',
      'name': 'Legacy Area',
      'isActive': true,
    });
    final locality = ServiceLocality.fromMap('legacy-locality', {
      'countryId': 'country-1',
      'stateId': 'state-1',
      'cityId': 'city-1',
      'areaId': 'area-1',
      'name': 'Legacy Locality',
      'isActive': true,
    });

    expect(city.isServiceActive, isTrue);
    expect(area.isServiceActive, isTrue);
    expect(locality.isServiceActive, isTrue);
  });

  test('canonical inactive status overrides stale legacy active flags for City, Area, and Locality', () {
    final city = ServiceCity.fromMap('city-1', {
      'countryId': 'country-1',
      'stateId': 'state-1',
      'name': 'City',
      'isServiceActive': false,
      'isActive': true,
    });
    final area = ServiceArea.fromMap('area-1', {
      'countryId': 'country-1',
      'stateId': 'state-1',
      'cityId': 'city-1',
      'name': 'Area',
      'isServiceActive': false,
      'isActive': true,
    });
    final locality = ServiceLocality.fromMap('locality-1', {
      'countryId': 'country-1',
      'stateId': 'state-1',
      'cityId': 'city-1',
      'areaId': 'area-1',
      'name': 'Locality',
      'isServiceActive': false,
      'isActive': true,
    });

    expect(city.isServiceActive, isFalse);
    expect(area.isServiceActive, isFalse);
    expect(locality.isServiceActive, isFalse);
  });
}

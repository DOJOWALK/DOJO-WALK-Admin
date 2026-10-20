import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/data/reference/india_locations/india_districts.dart';
import 'package:dojo_admin/data/reference/india_locations/india_location_filters.dart';
import 'package:dojo_admin/data/reference/india_locations/india_states.dart';
import 'package:dojo_admin/data/reference/india_locations/india_sub_districts.dart';

void main() {
  group('India location reference filters', () {
    test('filters districts by the State LGD code', () {
      final districts = filterDistrictsForStateLgdCode(9);

      expect(districts, isNotEmpty);
      expect(districts.every((item) => item.stateCode == '9'), isTrue);
      expect(districts.every((item) => item.stateName == 'Uttar Pradesh'), isTrue);
    });

    test('returns no districts for an unknown State LGD code', () {
      expect(filterDistrictsForStateLgdCode(-1), isEmpty);
    });

    test('filters sub-districts by both State and District codes', () {
      expect(indiaSubDistricts, isNotEmpty);
      final sample = indiaSubDistricts.first;

      final matches = filterSubDistrictsForStateAndDistrict(
        stateLgdCode: int.parse(sample.stateCode),
        districtLgdCode: sample.districtCode,
      );

      expect(matches, isNotEmpty);
      expect(
        matches.every((item) =>
            item.stateCode == sample.stateCode &&
            item.districtCode == sample.districtCode),
        isTrue,
      );
    });

    test('does not leak sub-districts across a mismatched State code', () {
      expect(indiaSubDistricts, isNotEmpty);
      final sample = indiaSubDistricts.first;
      final otherStateCode = sample.stateCode == '999' ? 998 : 999;

      expect(
        filterSubDistrictsForStateAndDistrict(
          stateLgdCode: otherStateCode,
          districtLgdCode: sample.districtCode,
        ),
        isEmpty,
      );
    });

    test('preserves Census codes with leading zeroes in reference records', () {
      final uttarPradesh = indiaStates.singleWhere((item) => item.lgdCode == 9);
      expect(uttarPradesh.census2011Code, '09');

      final district = indiaDistricts.firstWhere(
        (item) => item.stateCode == '9' && item.stateCensus2011Code == '09',
      );
      expect(district.stateCensus2011Code, '09');
    });
  });
}

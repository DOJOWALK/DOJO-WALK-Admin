import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/data/reference/india_locations/india_districts.dart';
import 'package:dojo_admin/features/service_location/services/location_csv_preview_parser.dart';
import 'package:dojo_admin/features/service_location/services/location_csv_lgd_validator.dart';

void main() {
  group('LGD State/District CSV matching (read-only)', () {
    LocationCsvRow row(String state, String district) => LocationCsvRow(
          lineNumber: 2,
          values: {
            'state': state,
            'district': district,
            'city': 'Sample Service City',
            'area': 'Sample Area',
          },
          errors: const [],
        );

    test('matches a district within its State parent and returns LGD codes', () {
      final source = indiaDistricts.first;
      final result = matchCsvStateDistrictToLgd(
        row(source.stateName, source.districtName),
      );
      expect(result.isMatched, isTrue);
      expect(result.stateLgdCode, int.parse(source.stateCode));
      expect(result.districtLgdCode, source.districtCode);
      expect(result.lineNumber, 2);
    });

    test('rejects an unknown state without guessing a parent', () {
      final result = matchCsvStateDistrictToLgd(
        row('Definitely Unknown State 999', 'Faridabad'),
      );
      expect(result.isMatched, isFalse);
      expect(result.message, contains('State'));
      expect(result.message, contains('not found'));
    });

    test('rejects a district that does not belong to the selected state', () {
      final source = indiaDistricts.first;
      final result = matchCsvStateDistrictToLgd(
        row(source.stateName, 'Definitely Missing District 999'),
      );
      expect(result.isMatched, isFalse);
      expect(result.stateLgdCode, int.parse(source.stateCode));
      expect(result.message, contains('District'));
      expect(result.message, contains('not found'));
    });

    test('requires both State and District values', () {
      final result = matchCsvStateDistrictToLgd(row('', 'Faridabad'));
      expect(result.isMatched, isFalse);
      expect(result.message, contains('both required'));
    });

    test('does not treat reference match as import approval', () {
      final source = indiaDistricts.first;
      final result = matchCsvStateDistrictToLgd(
        row(source.stateName, source.districtName),
      );
      expect(result.isMatched, isTrue);
      expect(result.message, contains('LGD reference match'));
      expect(result.message, isNot(contains('approved')));
    });
  });
}
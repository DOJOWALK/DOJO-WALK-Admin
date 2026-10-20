import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/services/location_csv_import_fingerprint.dart';
import 'package:dojo_admin/features/service_location/services/location_csv_preview_parser.dart';

void main() {
  final parser = LocationCsvPreviewParser();

  group('locationCsvImportFingerprint', () {
    test('is stable across column order, whitespace, and row order', () {
      final first = parser.parse(
        'State,District,City,Area\nUP,Gautam Budh Nagar,Noida,Area B\nUP,Gautam Budh Nagar,Noida,Area A\n',
      );
      final second = parser.parse(
        ' Area , City , District , State \n Area A , Noida , Gautam Budh Nagar , UP \n Area B , Noida , Gautam Budh Nagar , UP \n',
      );

      expect(first.isSyntacticallyValid, isTrue);
      expect(second.isSyntacticallyValid, isTrue);
      expect(
        locationCsvImportFingerprint(countryId: 'IN', preview: first),
        locationCsvImportFingerprint(countryId: ' in ', preview: second),
      );
    });

    test('normalizes repeated internal whitespace in hierarchy values', () {
      final spaced = parser.parse(
        'State,District,City,Area\nUttar   Pradesh,Gautam   Buddha Nagar,Greater  Noida,Gaur   City',
      );
      final normalized = parser.parse(
        'State,District,City,Area\nUttar Pradesh,Gautam Buddha Nagar,Greater Noida,Gaur City',
      );
      expect(spaced.isSyntacticallyValid, isTrue);
      expect(normalized.isSyntacticallyValid, isTrue);
      expect(
        locationCsvImportFingerprint(countryId: 'IN', preview: spaced),
        locationCsvImportFingerprint(countryId: 'IN', preview: normalized),
      );
    });

    test('changes when country or an imported hierarchy value changes', () {
      final first = parser.parse(
        'State,District,City,Area\nUP,Gautam Budh Nagar,Noida,Area A\n',
      );
      final changed = parser.parse(
        'State,District,City,Area\nUP,Gautam Budh Nagar,Noida,Area B\n',
      );

      final original = locationCsvImportFingerprint(
        countryId: 'IN',
        preview: first,
      );
      expect(
        locationCsvImportFingerprint(countryId: 'US', preview: first),
        isNot(original),
      );
      expect(
        locationCsvImportFingerprint(countryId: 'IN', preview: changed),
        isNot(original),
      );
    });

    test('rejects invalid previews and empty country IDs', () {
      final invalid = parser.parse('State,District,City,Area\nUP,,Noida,A\n');
      expect(
        () => locationCsvImportFingerprint(countryId: 'IN', preview: invalid),
        throwsArgumentError,
      );

      final valid = parser.parse(
        'State,District,City,Area\nUP,Gautam Budh Nagar,Noida,A\n',
      );
      expect(
        () => locationCsvImportFingerprint(countryId: ' ', preview: valid),
        throwsArgumentError,
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/services/location_csv_preview_parser.dart';

void main() {
  group('LocationCsvPreviewParser', () {
    final parser = LocationCsvPreviewParser();

    test('marks valid CSV syntax without implying import approval', () {
      final result = parser.parse(
        'State,District,City,Area\nUttar Pradesh,Gautam Buddha Nagar,Greater Noida,Gaur City',
      );
      expect(result.fileErrors, isEmpty);
      expect(result.validRowCount, 1);
      expect(result.invalidRowCount, 0);
      expect(result.isSyntacticallyValid, isTrue);
    });

    test('supports quoted commas and escaped quotes', () {
      final result = parser.parse(
        'State,District,City,Area\nUttar Pradesh,Gautam Buddha Nagar,"Greater Noida, West","Area ""A"""',
      );
      expect(result.rows.single.values['city'], 'Greater Noida, West');
      expect(result.rows.single.values['area'], 'Area "A"');
      expect(result.isSyntacticallyValid, isTrue);
    });

    test('reports missing headers without producing rows', () {
      final result = parser.parse('State,City,Area\nUP,Noida,Sector 1');
      expect(result.fileErrors, contains('Required column missing: DISTRICT.'));
      expect(result.rows, isEmpty);
      expect(result.isSyntacticallyValid, isFalse);
    });

    test('reports missing cells, wrong field counts, and duplicate combinations', () {
      final result = parser.parse(
        'State,District,City,Area\nUP,GBN,Noida,\nUP,GBN,Noida,Sector 1\nUP,GBN,Noida,Sector 1,Extra',
      );
      expect(result.invalidRowCount, 2);
      expect(result.rows[0].errors, contains('Required value missing: AREA.'));
      expect(result.rows[2].errors, contains('Expected 4 columns but found 5.'));
      expect(result.rows[2].errors, contains('Duplicate State/District/City/Area combination in this file.'));
      expect(result.isSyntacticallyValid, isFalse);
    });

    test('rejects duplicate and empty headers', () {
      final duplicate = parser.parse('State,STATE,District,City,Area\na,b,c,d,e');
      expect(duplicate.fileErrors, contains('Header row contains duplicate column names.'));
      final empty = parser.parse('State,,District,City,Area\na,b,c,d,e');
      expect(empty.fileErrors, contains('Header row contains an empty column name.'));
    });

    test('rejects a quote inside an unquoted field', () {
      final result = parser.parse(
        'State,District,City,Area\nUP,GB"N,Noida,Sector 1',
      );
      expect(
        result.fileErrors,
        contains('Malformed CSV near record 2: a quote must begin a field.'),
      );
      expect(result.rows, isEmpty);
      expect(result.isSyntacticallyValid, isFalse);
    });

    test('does not confuse pipe characters across different parent fields', () {
      final result = parser.parse(
        'State,District,City,Area\n'
        'A|B,C,D,E\n'
        'A,B|C,D,E',
      );
      expect(result.fileErrors, isEmpty);
      expect(result.rows, hasLength(2));
      expect(result.invalidRowCount, 0);
      expect(result.rows.every((row) => row.isValid), isTrue);
    });

    test('maps State, District, City, and Area as four distinct source values', () {
      final result = parser.parse(
        'Area,City,State,District\n'
        'Gaur City,Greater Noida,Uttar Pradesh,Gautam Buddha Nagar',
      );

      expect(result.fileErrors, isEmpty);
      expect(result.rows, hasLength(1));
      final values = result.rows.single.values;
      expect(values.keys.toSet(), {'state', 'district', 'city', 'area'});
      expect(values['state'], 'Uttar Pradesh');
      expect(values['district'], 'Gautam Buddha Nagar');
      expect(values['city'], 'Greater Noida');
      expect(values['area'], 'Gaur City');
      expect(values['city'], isNot(values['district']));
      expect(result.isSyntacticallyValid, isTrue);
    });

    test('normalizes required header case spaces underscores and hyphens', () {
      final result = parser.parse(
        ' STATE ,dis trict,ci-ty,Area\n'
        'Uttar Pradesh,Gautam Buddha Nagar,Greater Noida,Gaur City',
      );

      expect(result.fileErrors, isEmpty);
      expect(result.isSyntacticallyValid, isTrue);
      expect(result.rows.single.values['state'], 'Uttar Pradesh');
      expect(result.rows.single.values['district'], 'Gautam Buddha Nagar');
      expect(result.rows.single.values['city'], 'Greater Noida');
      expect(result.rows.single.values['area'], 'Gaur City');
    });

    test('preserves optional source codes and version columns in read-only preview', () {
      final result = parser.parse(
        'State,District,City,Area,State LGD Code,District LGD Code,Source Version\n'
        'Uttar Pradesh,Gautam Buddha Nagar,Greater Noida,Gaur City,09,0123,LGD-2026-10',
      );

      expect(result.isSyntacticallyValid, isTrue);
      final row = result.rows.single;
      // Existing callers still receive exactly the four location-name fields.
      expect(row.values.keys.toSet(), {'state', 'district', 'city', 'area'});
      // Extra source columns survive as strings, including leading zeroes.
      expect(row.sourceValues['State LGD Code'], '09');
      expect(row.sourceValues['District LGD Code'], '0123');
      expect(row.sourceValues['Source Version'], 'LGD-2026-10');
    });

    test('preserves quoted optional source metadata values', () {
      final result = parser.parse(
        'State,District,City,Area,Source Name,Source Note\n'
        'Uttar Pradesh,Gautam Buddha Nagar,Greater Noida,Gaur City,'
        '"LGD, 2026","Source said ""verified""; preview only"',
      );

      expect(result.isSyntacticallyValid, isTrue);
      final row = result.rows.single;
      expect(row.sourceValues['Source Name'], 'LGD, 2026');
      expect(row.sourceValues['Source Note'], 'Source said "verified"; preview only');
      expect(row.values.keys.toSet(), {'state', 'district', 'city', 'area'});
    });

    test('optional source metadata does not bypass duplicate location detection', () {
      final result = parser.parse(
        'State,District,City,Area,Source Code\n'
        'Uttar Pradesh,Gautam Buddha Nagar,Greater Noida,Gaur City,001\n'
        'Uttar Pradesh,Gautam Buddha Nagar,Greater Noida,Gaur City,002',
      );

      expect(result.rows, hasLength(2));
      expect(result.rows.first.errors, isEmpty);
      expect(
        result.rows.last.errors,
        contains('Duplicate State/District/City/Area combination in this file.'),
      );
      expect(result.rows.first.sourceValues['Source Code'], '001');
      expect(result.rows.last.sourceValues['Source Code'], '002');
    });

    test('handles UTF-8 BOM and Windows CRLF while preserving source codes', () {
      final result = parser.parse(
        '\uFEFFState,District,City,Area,State LGD Code\r\n'
        'Uttar Pradesh,Gautam Buddha Nagar,Greater Noida,Gaur City,00123\r\n',
      );

      expect(result.fileErrors, isEmpty);
      expect(result.isSyntacticallyValid, isTrue);
      expect(result.rows, hasLength(1));
      expect(result.rows.single.values['state'], 'Uttar Pradesh');
      expect(result.rows.single.sourceValues['State LGD Code'], '00123');
    });

    test('rejects duplicate optional metadata headers after normalization', () {
      final result = parser.parse(
        'State,District,City,Area,State LGD Code,state_lgd-code\n'
        'Uttar Pradesh,Gautam Buddha Nagar,Greater Noida,Gaur City,09,10',
      );

      expect(
        result.fileErrors,
        contains('Header row contains duplicate column names.'),
      );
      expect(result.rows, isEmpty);
      expect(result.isSyntacticallyValid, isFalse);
    });

    test('rejects empty and malformed CSV input', () {
      expect(parser.parse('  ').fileErrors, contains('CSV file is empty.'));
      expect(
        parser.parse('State,District,City,Area\n"UP,GBN,Noida,Area').fileErrors,
        contains('Malformed CSV: an opening quote was not closed.'),
      );
    });
  });
}

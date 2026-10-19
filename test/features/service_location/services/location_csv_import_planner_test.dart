import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/services/location_csv_import_planner.dart';
import 'package:dojo_admin/features/service_location/services/location_csv_preview_parser.dart';

void main() {
  group('LocationCsvImportPlanner', () {
    final parser = LocationCsvPreviewParser();
    final planner = LocationCsvImportPlanner();

    test('plans parents before children and reuses shared parents', () {
      final preview = parser.parse(
        'State,District,City,Area\n'
        'Uttar Pradesh,Gautam Buddha Nagar,Greater Noida,Gaur City\n'
        'Uttar Pradesh,Gautam Buddha Nagar,Noida,Sector 1',
      );
      var next = 0;
      final plan = planner.plan(
        preview: preview,
        countryId: 'india',
        existingIdsByPath: const {},
        allocateId: (_) => 'new-${next++}',
      );

      expect(plan.map((node) => node.type), [
        LocationImportNodeType.state,
        LocationImportNodeType.district,
        LocationImportNodeType.city,
        LocationImportNodeType.city,
        LocationImportNodeType.area,
        LocationImportNodeType.area,
      ]);
      expect(plan.where((node) => node.type == LocationImportNodeType.state), hasLength(1));
      expect(plan.where((node) => node.type == LocationImportNodeType.district), hasLength(1));
      expect(plan.where((node) => node.type == LocationImportNodeType.city), hasLength(2));
      expect(plan.where((node) => node.type == LocationImportNodeType.area), hasLength(2));
      final state = plan.first;
      final district = plan.firstWhere((node) => node.type == LocationImportNodeType.district);
      expect(district.parentId, state.id);
      expect(plan.every((node) => !node.alreadyExists), isTrue);
    });

    test('reuses supplied existing IDs and marks them as existing', () {
      final preview = parser.parse(
        'State,District,City,Area\nUP,GBN,Greater Noida,Gaur City',
      );
      final stateKey = LocationImportPlannedNode.pathKey(
        LocationImportNodeType.state, ['UP']);
      final plan = planner.plan(
        preview: preview,
        countryId: 'india',
        existingIdsByPath: {stateKey: 'state-existing'},
        allocateId: (key) => 'generated-${key.hashCode.abs()}',
      );

      expect(plan.first.id, 'state-existing');
      expect(plan.first.alreadyExists, isTrue);
      expect(plan.skip(1).every((node) => !node.alreadyExists), isTrue);
      expect(plan.firstWhere((node) => node.type == LocationImportNodeType.district).parentId,
          'state-existing');
    });

    test('rejects invalid previews and missing country IDs', () {
      final invalid = parser.parse('State,City,Area\nUP,Noida,Sector 1');
      expect(
        () => planner.plan(
          preview: invalid,
          countryId: 'india',
          existingIdsByPath: const {},
          allocateId: (_) => 'id',
        ),
        throwsArgumentError,
      );
      final valid = parser.parse('State,District,City,Area\nUP,GBN,Noida,Sector 1');
      expect(
        () => planner.plan(
          preview: valid,
          countryId: ' ',
          existingIdsByPath: const {},
          allocateId: (_) => 'id',
        ),
        throwsArgumentError,
      );
    });

    test('rejects invalid IDs returned by allocator', () {
      final preview = parser.parse('State,District,City,Area\nUP,GBN,Noida,Sector 1');
      expect(
        () => planner.plan(
          preview: preview,
          countryId: 'india',
          existingIdsByPath: const {},
          allocateId: (_) => 'bad/id',
        ),
        throwsArgumentError,
      );
    });



    test('stable IDs are repeatable and isolated by country', () {
      const path = 'state|2:up';
      final indiaFirst =
          LocationImportPlannedNode.stableDocumentId('india', path);
      final indiaRetry =
          LocationImportPlannedNode.stableDocumentId(' india ', path);
      final otherCountry =
          LocationImportPlannedNode.stableDocumentId('other-country', path);

      expect(indiaFirst, startsWith('csv_'));
      expect(indiaFirst, indiaRetry);
      expect(indiaFirst, isNot(otherCountry));
      expect(indiaFirst, hasLength(44));
    });

    test('stable ID rejects missing country or path', () {
      expect(
        () => LocationImportPlannedNode.stableDocumentId(' ', 'state|2:up'),
        throwsArgumentError,
      );
      expect(
        () => LocationImportPlannedNode.stableDocumentId('india', ' '),
        throwsArgumentError,
      );
    });

    test('normalizes repeated internal whitespace in path keys', () {
      expect(
        LocationImportPlannedNode.pathKey(
          LocationImportNodeType.state, ['  Uttar   Pradesh  ']),
        LocationImportPlannedNode.pathKey(
          LocationImportNodeType.state, ['uttar pradesh']),
      );
    });

    test('path keys do not collide when a segment contains a delimiter', () {
      final first = LocationImportPlannedNode.pathKey(
        LocationImportNodeType.city, ['A|B', 'C']);
      final second = LocationImportPlannedNode.pathKey(
        LocationImportNodeType.city, ['A', 'B|C']);
      expect(first, isNot(second));
    });
  });
}

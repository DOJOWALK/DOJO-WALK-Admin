import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/data/reference/india_locations/india_states.dart';
import 'package:dojo_admin/data/reference/india_locations/india_districts.dart';

void main() {
  group('India location reference data integrity', () {
    test('contains 36 unique State/UT LGD codes', () {
      expect(indiaStates, hasLength(36));
      final codes = indiaStates.map((state) => state.lgdCode).toList();
      expect(codes.toSet(), hasLength(codes.length));
    });

    test('district LGD codes are unique', () {
      final codes = indiaDistricts.map((district) => district.districtCode).toList();
      expect(codes, isNotEmpty);
      expect(codes.toSet(), hasLength(codes.length));
    });

    test('every district references an existing State/UT LGD code', () {
      final stateCodes = indiaStates.map((state) => state.lgdCode.toString()).toSet();
      final missingParents = indiaDistricts
          .where((district) => !stateCodes.contains(district.stateCode))
          .map((district) => '${district.stateCode}:${district.districtName}')
          .toList();

      expect(
        missingParents,
        isEmpty,
        reason: 'Districts must reference an existing State/UT code.',
      );
    });

    test('district state names agree with their state-code parent', () {
      final statesByCode = {
        for (final state in indiaStates) state.lgdCode.toString(): state,
      };
      final mismatches = indiaDistricts.where((district) {
        final parent = statesByCode[district.stateCode];
        return parent == null ||
            parent.name.trim().toUpperCase() !=
                district.stateName.trim().toUpperCase();
      }).map((district) =>
          '${district.stateCode}:${district.stateName} / ${district.districtName}')
       .toList();

      expect(
        mismatches,
        isEmpty,
        reason: 'District state names must match the state-code parent.',
      );
    });
  });
}

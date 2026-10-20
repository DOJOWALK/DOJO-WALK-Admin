import '../../../data/reference/india_locations/india_districts.dart';
import '../../../data/reference/india_locations/india_states.dart';
import 'location_csv_preview_parser.dart';

/// Read-only validation of a CSV row's State/District pair against the
/// bundled LGD reference snapshot. This never writes Firestore data.
class LgdStateDistrictMatch {
  const LgdStateDistrictMatch({
    required this.lineNumber,
    required this.isMatched,
    required this.message,
    this.stateLgdCode,
    this.districtLgdCode,
  });

  final int lineNumber;
  final bool isMatched;
  final String message;
  final int? stateLgdCode;
  final String? districtLgdCode;
}

String _normalizeLgdLocationName(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// Matches State and District names within the same parent chain.
/// A match confirms consistency with this bundled reference snapshot only;
/// it is not boundary verification, service-area approval, or import approval.
LgdStateDistrictMatch matchCsvStateDistrictToLgd(LocationCsvRow row) {
  final stateName = row.values['state']?.trim() ?? '';
  final districtName = row.values['district']?.trim() ?? '';
  if (stateName.isEmpty || districtName.isEmpty) {
    return LgdStateDistrictMatch(
      lineNumber: row.lineNumber,
      isMatched: false,
      message: 'State and District are both required for LGD matching.',
    );
  }

  final normalizedState = _normalizeLgdLocationName(stateName);
  final states = indiaStates.where((state) =>
      _normalizeLgdLocationName(state.name) == normalizedState ||
      _normalizeLgdLocationName(state.localName) == normalizedState).toList();

  if (states.length != 1) {
    return LgdStateDistrictMatch(
      lineNumber: row.lineNumber,
      isMatched: false,
      message: states.isEmpty
          ? 'State "$stateName" was not found in the bundled LGD reference.'
          : 'State "$stateName" is ambiguous in the bundled LGD reference.',
    );
  }

  final state = states.single;
  final districts = indiaDistricts.where((district) =>
      district.stateCode.trim() == state.lgdCode.toString() &&
      (_normalizeLgdLocationName(district.districtName) ==
              _normalizeLgdLocationName(districtName) ||
          _normalizeLgdLocationName(district.districtNameLocal) ==
              _normalizeLgdLocationName(districtName))).toList();

  if (districts.length != 1) {
    return LgdStateDistrictMatch(
      lineNumber: row.lineNumber,
      isMatched: false,
      stateLgdCode: state.lgdCode,
      message: districts.isEmpty
          ? 'District "$districtName" was not found under "$stateName" in the bundled LGD reference.'
          : 'District "$districtName" is ambiguous under "$stateName" in the bundled LGD reference.',
    );
  }

  final district = districts.single;
  return LgdStateDistrictMatch(
    lineNumber: row.lineNumber,
    isMatched: true,
    stateLgdCode: state.lgdCode,
    districtLgdCode: district.districtCode,
    message: 'LGD reference match: State code ${state.lgdCode}, District code ${district.districtCode}.',
  );
}
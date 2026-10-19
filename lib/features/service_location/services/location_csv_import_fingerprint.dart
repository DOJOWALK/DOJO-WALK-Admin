import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'location_csv_preview_parser.dart';

/// Creates a deterministic fingerprint for the *validated location rows*
/// that the importer will actually apply.
///
/// Source formatting, column order, blank lines, and row order do not affect
/// the result. Country and all four normalized hierarchy names do. This is
/// deliberately pure; callers must persist the fingerprint in a trusted,
/// immutable import-run record before using it for recovery decisions.
String locationCsvImportFingerprint({
  required String countryId,
  required LocationCsvPreview preview,
}) {
  final country = _normalize(countryId);
  if (country.isEmpty) {
    throw ArgumentError('Country ID is required for an import fingerprint.');
  }
  if (!preview.isSyntacticallyValid) {
    throw ArgumentError(
      'A syntactically valid CSV preview is required for fingerprinting.',
    );
  }

  final rows = preview.rows.map((row) {
    final values = <String>[
      _normalize(row.values['state'] ?? ''),
      _normalize(row.values['district'] ?? ''),
      _normalize(row.values['city'] ?? ''),
      _normalize(row.values['area'] ?? ''),
    ];
    if (values.any((value) => value.isEmpty)) {
      throw ArgumentError(
        'Every import row must contain State, District, City, and Area.',
      );
    }
    // Length-prefix every value to prevent delimiter-based collisions.
    return values.map((value) => '${value.length}:$value').join();
  }).toList()
    ..sort();

  final canonical = <String>[
    'dojo-location-csv-v1',
    '${country.length}:$country',
    ...rows,
  ].map((value) => '${value.length}:$value').join();

  return 'sha256:${sha256.convert(utf8.encode(canonical))}';
}

String _normalize(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\\s+'), ' ');

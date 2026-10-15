/// DOJO WALK Admin
///
/// Validates government village reference data before import.
///
/// This utility does not write to Firestore.
/// It does not generate village codes or map boundaries.

class VillageReferenceRecord {
  final String villageCode;
  final String villageName;
  final String tehsilName;
  final String source;

  const VillageReferenceRecord({
    required this.villageCode,
    required this.villageName,
    required this.tehsilName,
    required this.source,
  });

  Map<String, String> toMap() => {
        'governmentVillageCode': villageCode,
        'name': villageName,
        'tehsilName': tehsilName,
        'source': source,
      };
}

class VillageImportResult {
  final List<VillageReferenceRecord> records;
  final List<String> errors;
  final List<String> warnings;

  const VillageImportResult({
    required this.records,
    required this.errors,
    required this.warnings,
  });

  bool get isValid => errors.isEmpty;

  int get validRecordCount => records.length;
}

class VillageReferenceImporter {
  VillageReferenceImporter._();

  static const Map<String, String> tehsilIds = {
    'dadri': 'gbn_dadri',
    'gautam buddha nagar': 'gbn_sadar',
    'jewar': 'gbn_jewar',
  };

  /// Supports comma-separated CSV and tab-separated TSV.
  ///
  /// Expected columns:
  /// Village Code, Village, Tehsil
  ///
  /// For government exports, map the actual column names
  /// to these fields before using this parser.
  static VillageImportResult parse({
    required String content,
    required String source,
    String delimiter = ',',
  }) {
    final lines = content
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    if (lines.length < 2) {
      return const VillageImportResult(
        records: [],
        errors: ['CSV में header और कम-से-कम एक data row होना चाहिए।'],
        warnings: [],
      );
    }

    final headers = _parseRow(lines.first, delimiter)
        .map(_normalizeHeader)
        .toList();

    final codeIndex = _findHeader(
      headers,
      ['village code', 'villagecode', 'lgd village code'],
    );

    final nameIndex = _findHeader(
      headers,
      ['village', 'village name', 'revenue village'],
    );

    final tehsilIndex = _findHeader(
      headers,
      ['tehsil', 'tehsil name', 'sub district'],
    );

    if (codeIndex < 0 || nameIndex < 0 || tehsilIndex < 0) {
      return VillageImportResult(
        records: const [],
        errors: [
          'Village Code, Village Name और Tehsil के columns नहीं मिले।',
          'पहले सरकारी CSV के header को जाँचें और columns map करें.',
        ],
        warnings: const [],
      );
    }

    final records = <VillageReferenceRecord>[];
    final errors = <String>[];
    final warnings = <String>[];
    final seenCodes = <String>{};

    for (var i = 1; i < lines.length; i++) {
      final rowNumber = i + 1;
      final row = _parseRow(lines[i], delimiter);

      final requiredLength = [
        codeIndex,
        nameIndex,
        tehsilIndex,
      ].reduce((a, b) => a > b ? a : b);

      if (row.length <= requiredLength) {
        errors.add('Row $rowNumber: आवश्यक columns अधूरे हैं।');
        continue;
      }

      final code = row[codeIndex].trim();
      final name = row[nameIndex].trim();
      final tehsil = row[tehsilIndex].trim();

      if (code.isEmpty || name.isEmpty || tehsil.isEmpty) {
        errors.add('Row $rowNumber: Code, Village या Tehsil खाली है।');
        continue;
      }

      if (!RegExp(r'^[0-9]+$').hasMatch(code)) {
        errors.add('Row $rowNumber: Village Code numeric नहीं है।');
        continue;
      }

      if (!seenCodes.add(code)) {
        errors.add('Row $rowNumber: Duplicate Village Code $code.');
        continue;
      }

      final normalizedTehsil = tehsil.toLowerCase().trim();

      if (!tehsilIds.containsKey(normalizedTehsil)) {
        warnings.add(
          'Row $rowNumber: Tehsil "$tehsil" का parent mapping सत्यापित करें।',
        );
      }

      records.add(
        VillageReferenceRecord(
          villageCode: code,
          villageName: name,
          tehsilName: tehsil,
          source: source,
        ),
      );
    }

    return VillageImportResult(
      records: List.unmodifiable(records),
      errors: List.unmodifiable(errors),
      warnings: List.unmodifiable(warnings),
    );
  }

  static int _findHeader(
    List<String> headers,
    List<String> candidates,
  ) {
    for (var i = 0; i < headers.length; i++) {
      if (candidates.contains(headers[i])) {
        return i;
      }
    }

    return -1;
  }

  static String _normalizeHeader(String value) {
    return value
        .replaceAll('\uFEFF', '')
        .trim()
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Handles quoted CSV cells and escaped double quotes.
  static List<String> _parseRow(
    String line,
    String delimiter,
  ) {
    final result = <String>[];
    final buffer = StringBuffer();
    var quoted = false;

    for (var i = 0; i < line.length; i++) {
      final character = line[i];

      if (character == '"') {
        if (quoted &&
            i + 1 < line.length &&
            line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          quoted = !quoted;
        }
      } else if (!quoted && character == delimiter) {
        result.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(character);
      }
    }

    result.add(buffer.toString().trim());
    return result;
  }
}

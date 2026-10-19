/// Pure, side-effect-free planner for a future Service Location CSV importer.
///
/// This file deliberately performs no Firestore writes. The caller must load
/// existing parent IDs, provide a stable ID allocator, review the plan, and
/// persist records through the trusted Service Location service in hierarchy
/// order. New records are planned inactive by default.
import 'location_csv_preview_parser.dart';

enum LocationImportNodeType { state, district, city, area }

class LocationImportPlannedNode {
  final LocationImportNodeType type;
  final String id;
  final String name;
  final String parentId;
  final int firstSourceLine;
  final bool alreadyExists;

  const LocationImportPlannedNode({
    required this.type,
    required this.id,
    required this.name,
    required this.parentId,
    required this.firstSourceLine,
    required this.alreadyExists,
  });

  /// Stable identity for lookup in [existingIdsByPath].
  ///
  /// Path segments are length-prefixed to prevent delimiter collisions.
  static String pathKey(LocationImportNodeType type, List<String> segments) {
    final normalized = segments.map(_normalizeName).toList();
    final encoded = normalized.map((s) => '${s.length}:$s').join();
    return '${type.name}|$encoded';
  }

  static String _normalizeName(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

/// Builds a deterministic hierarchy plan without making any remote writes.
///
/// [existingIdsByPath] keys must be created with [LocationImportPlannedNode.pathKey].
/// [allocateId] must return a stable, valid document ID for the supplied key;
/// the planner calls it only once for each missing path in a single plan.
class LocationCsvImportPlanner {
  List<LocationImportPlannedNode> plan({
    required LocationCsvPreview preview,
    required String countryId,
    required Map<String, String> existingIdsByPath,
    required String Function(String pathKey) allocateId,
  }) {
    if (!preview.isSyntacticallyValid) {
      throw ArgumentError('CSV preview must be syntactically valid before planning.');
    }
    final country = countryId.trim();
    if (country.isEmpty) throw ArgumentError('Country ID is required.');

    final result = <LocationImportPlannedNode>[];
    final idsByPath = <String, String>{};
    final namesByPath = <String, String>{};
    final typesByPath = <String, LocationImportNodeType>{};
    final parentsByPath = <String, String>{};
    final firstLinesByPath = <String, int>{};

    String ensureNode({
      required LocationImportNodeType type,
      required List<String> segments,
      required String name,
      required String parentId,
      required int sourceLine,
    }) {
      final key = LocationImportPlannedNode.pathKey(type, segments);
      final priorParent = parentsByPath[key];
      if (priorParent != null && priorParent != parentId) {
        throw StateError('Conflicting parent mapping for $key.');
      }
      if (idsByPath.containsKey(key)) return idsByPath[key]!;
      final existingId = existingIdsByPath[key]?.trim();
      final id = (existingId != null && existingId.isNotEmpty)
          ? existingId
          : allocateId(key).trim();
      if (id.isEmpty || id.contains('/')) {
        throw ArgumentError('ID allocator returned an invalid document ID for $key.');
      }
      idsByPath[key] = id;
      namesByPath[key] = name.trim();
      typesByPath[key] = type;
      parentsByPath[key] = parentId;
      firstLinesByPath[key] = sourceLine;
      return id;
    }

    for (final row in preview.rows) {
      if (!row.isValid) {
        throw ArgumentError('CSV row ${row.lineNumber} has validation errors.');
      }
      final values = row.values;
      final state = values['state']!.trim();
      final district = values['district']!.trim();
      final city = values['city']!.trim();
      final area = values['area']!.trim();

      final stateId = ensureNode(
        type: LocationImportNodeType.state,
        segments: [state],
        name: state,
        parentId: country,
        sourceLine: row.lineNumber,
      );
      final districtId = ensureNode(
        type: LocationImportNodeType.district,
        segments: [state, district],
        name: district,
        parentId: stateId,
        sourceLine: row.lineNumber,
      );
      final cityId = ensureNode(
        type: LocationImportNodeType.city,
        segments: [state, district, city],
        name: city,
        parentId: districtId,
        sourceLine: row.lineNumber,
      );
      ensureNode(
        type: LocationImportNodeType.area,
        segments: [state, district, city, area],
        name: area,
        parentId: cityId,
        sourceLine: row.lineNumber,
      );
    }

    // Emit parent-first order. Newly planned nodes are inactive by contract;
    // activation and boundary verification are separate workflows.
    final order = <LocationImportNodeType>[
      LocationImportNodeType.state,
      LocationImportNodeType.district,
      LocationImportNodeType.city,
      LocationImportNodeType.area,
    ];
    for (final type in order) {
      for (final entry in idsByPath.entries) {
        if (typesByPath[entry.key] != type) continue;
        result.add(LocationImportPlannedNode(
          type: type,
          id: entry.value,
          name: namesByPath[entry.key]!,
          parentId: parentsByPath[entry.key]!,
          firstSourceLine: firstLinesByPath[entry.key]!,
          alreadyExists: (existingIdsByPath[entry.key]?.trim().isNotEmpty ?? false),
        ));
      }
    }
    return List.unmodifiable(result);
  }
}

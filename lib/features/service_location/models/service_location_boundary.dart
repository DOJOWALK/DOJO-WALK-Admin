import 'package:cloud_firestore/cloud_firestore.dart';

/// DOJO WALK Admin
///
/// Boundary source types supported by the admin screen.
enum BoundarySourceType {
  governmentGis,
  governmentCadastralMap,
  importedGeoJson,
  manuallyDrawn,
}

/// Boundary verification lifecycle.
///
/// Firestore stores the enum name:
/// notAvailable, pending, verified, rejected.
enum BoundaryVerificationStatus {
  notAvailable,
  pending,
  verified,
  rejected,
}

/// Service location polygon boundary model.
///
/// Firestore collection:
/// service_location_boundaries
///
/// Important:
/// - A polygon requires at least three distinct valid points.
/// - Verified boundaries are read-only in the service layer.
/// - Boundary verification does not activate a service location.
class ServiceLocationBoundary {
  final String id;
  final String locationId;
  final String locationType;

  /// Polygon vertices stored as Firestore GeoPoints.
  final List<GeoPoint> points;

  final BoundarySourceType sourceType;
  final String sourceName;
  final String sourceReference;

  final BoundaryVerificationStatus verificationStatus;

  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? verificationNotes;

  final DateTime createdAt;
  final DateTime updatedAt;

  const ServiceLocationBoundary({
    required this.id,
    required this.locationId,
    required this.locationType,
    required this.points,
    required this.sourceType,
    required this.sourceName,
    required this.sourceReference,
    required this.verificationStatus,
    required this.verifiedBy,
    required this.verifiedAt,
    required this.verificationNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Whether this boundary has been verified.
  bool get isVerified =>
      verificationStatus == BoundaryVerificationStatus.verified;

  /// Converts Firestore timestamps and DateTime values safely.
  static DateTime _readDate(
    Object? value, {
    required DateTime fallback,
  }) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return fallback;
  }

  static DateTime? _readNullableDate(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  static String? _readNullableString(Object? value) {
    if (value == null) {
      return null;
    }

    final result = value.toString().trim();
    return result.isEmpty ? null : result;
  }

  static BoundarySourceType _readSourceType(Object? value) {
    final name = value?.toString().trim();

    for (final type in BoundarySourceType.values) {
      if (type.name == name) {
        return type;
      }
    }

    return BoundarySourceType.manuallyDrawn;
  }

  static BoundaryVerificationStatus _readVerificationStatus(
    Object? value,
  ) {
    final name = value?.toString().trim().toLowerCase();

    for (final status in BoundaryVerificationStatus.values) {
      if (status.name.toLowerCase() == name) {
        return status;
      }
    }

    return BoundaryVerificationStatus.notAvailable;
  }

  /// Creates a model from a Firestore document.
  factory ServiceLocationBoundary.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    final now = DateTime.now();

    final rawPoints = map['points'];
    final parsedPoints = <GeoPoint>[];

    if (rawPoints is Iterable) {
      for (final point in rawPoints) {
        if (point is GeoPoint) {
          parsedPoints.add(point);
        } else if (point is Map) {
          final latitude = point['latitude'];
          final longitude = point['longitude'];

          if (latitude is num && longitude is num) {
            parsedPoints.add(
              GeoPoint(
                latitude.toDouble(),
                longitude.toDouble(),
              ),
            );
          }
        }
      }
    }

    return ServiceLocationBoundary(
      id: id,
      locationId: map['locationId']?.toString() ?? '',
      locationType: map['locationType']?.toString() ?? '',
      points: List<GeoPoint>.unmodifiable(parsedPoints),
      sourceType: _readSourceType(map['sourceType']),
      sourceName: map['sourceName']?.toString() ?? '',
      sourceReference: map['sourceReference']?.toString() ?? '',
      verificationStatus: _readVerificationStatus(
        map['verificationStatus'],
      ),
      verifiedBy: _readNullableString(map['verifiedBy']),
      verifiedAt: _readNullableDate(map['verifiedAt']),
      verificationNotes: _readNullableString(
        map['verificationNotes'],
      ),
      createdAt: _readDate(
        map['createdAt'],
        fallback: now,
      ),
      updatedAt: _readDate(
        map['updatedAt'],
        fallback: now,
      ),
    );
  }

  /// Validates the polygon and its required metadata.
  ///
  /// Returns a list of validation errors.
  List<String> validate() {
    final errors = <String>[];

    if (locationId.trim().isEmpty) {
      errors.add('Location ID is required.');
    }

    final normalizedType = locationType.trim().toLowerCase();

    if (!const {'city', 'area'}.contains(
      normalizedType,
    )) {
      errors.add(
        'Location type must be city or area.',
      );
    }

    if (sourceName.trim().isEmpty) {
      errors.add('Boundary source name is required.');
    }

    if (sourceReference.trim().isEmpty) {
      errors.add('Boundary source reference is required.');
    }

    if (points.length < 3) {
      errors.add(
        'A polygon must contain at least three points.',
      );
    }

    final distinctPoints = <String>{};

    for (var i = 0; i < points.length; i++) {
      final point = points[i];

      if (!point.latitude.isFinite ||
          !point.longitude.isFinite ||
          point.latitude < -90 ||
          point.latitude > 90 ||
          point.longitude < -180 ||
          point.longitude > 180) {
        errors.add('Boundary point ${i + 1} is invalid.');
        continue;
      }

      distinctPoints.add(
        '${point.latitude.toStringAsFixed(7)},'
        '${point.longitude.toStringAsFixed(7)}',
      );
    }

    if (distinctPoints.length < 3) {
      errors.add(
        'A polygon must contain at least three distinct points.',
      );
    }

    return errors.toSet().toList(growable: false);
  }
}

/// Selects the boundary record that should open first in the Admin manager.
///
/// Pending replacements must be reachable for review even when an older
/// verified boundary remains attached to the same location.
ServiceLocationBoundary? selectBoundaryForManagement(
  Iterable<ServiceLocationBoundary> boundaries,
) {
  final items = boundaries.toList(growable: false);
  for (final status in const [
    BoundaryVerificationStatus.pending,
    BoundaryVerificationStatus.rejected,
    BoundaryVerificationStatus.verified,
  ]) {
    for (final boundary in items) {
      if (boundary.verificationStatus == status) return boundary;
    }
  }
  return items.isEmpty ? null : items.first;
}

/// Orders boundary records for the explicit Admin chooser.
///
/// Pending and rejected replacements appear before verified records, and
/// newer records appear first within each status. The input is not mutated.
List<ServiceLocationBoundary> sortBoundariesForChooser(
  Iterable<ServiceLocationBoundary> boundaries,
) {
  final items = boundaries.toList();
  int priority(BoundaryVerificationStatus status) {
    switch (status) {
      case BoundaryVerificationStatus.pending:
        return 0;
      case BoundaryVerificationStatus.rejected:
        return 1;
      case BoundaryVerificationStatus.verified:
        return 2;
      case BoundaryVerificationStatus.notAvailable:
        return 3;
    }
  }

  items.sort((a, b) {
    final statusOrder = priority(a.verificationStatus)
        .compareTo(priority(b.verificationStatus));
    if (statusOrder != 0) return statusOrder;
    return b.updatedAt.compareTo(a.updatedAt);
  });
  return List<ServiceLocationBoundary>.unmodifiable(items);
}

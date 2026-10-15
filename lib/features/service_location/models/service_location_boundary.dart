/// DOJO WALK Admin
///
/// Geographic boundary model for service locations.
///
/// Important:
/// - Coordinates use latitude and longitude.
/// - A polygon must have at least three distinct vertices.
/// - Boundary verification must be performed before activation.
/// - This model does not create boundaries automatically.

import 'package:cloud_firestore/cloud_firestore.dart';

enum BoundaryVerificationStatus {
  notAvailable,
  pending,
  verified,
  rejected,
}

enum BoundarySourceType {
  governmentGis,
  governmentCadastralMap,
  importedGeoJson,
  manuallyDrawn,
}

class ServiceLocationBoundary {
  final String id;

  /// Parent administrative or service-area record ID.
  final String locationId;

  /// For example: village, locality, city or service_area.
  final String locationType;

  /// Polygon vertices in order around the boundary.
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
    required this.createdAt,
    required this.updatedAt,
    this.verifiedBy,
    this.verifiedAt,
    this.verificationNotes,
  });

  bool get isVerified =>
      verificationStatus == BoundaryVerificationStatus.verified;

  /// Basic checks only. These do not prove that the polygon
  /// matches the real-world administrative boundary.
  List<String> validate() {
    final errors = <String>[];

    if (locationId.trim().isEmpty) {
      errors.add('Location ID is required.');
    }

    if (locationType.trim().isEmpty) {
      errors.add('Location type is required.');
    }

    if (sourceName.trim().isEmpty) {
      errors.add('Boundary source name is required.');
    }

    if (sourceReference.trim().isEmpty) {
      errors.add('Boundary source reference is required.');
    }

    if (points.length < 3) {
      errors.add('A polygon needs at least three vertices.');
    }

    for (var i = 0; i < points.length; i++) {
      final point = points[i];

      if (!point.latitude.isFinite ||
          !point.longitude.isFinite) {
        errors.add('Vertex $i contains a non-finite coordinate.');
        continue;
      }

      if (point.latitude < -90 || point.latitude > 90) {
        errors.add('Vertex $i has invalid latitude.');
      }

      if (point.longitude < -180 || point.longitude > 180) {
        errors.add('Vertex $i has invalid longitude.');
      }
    }

    final uniqueCoordinates = points
        .map(
          (point) =>
              '${point.latitude.toStringAsFixed(7)},'
              '${point.longitude.toStringAsFixed(7)}',
        )
        .toSet();

    if (uniqueCoordinates.length < 3) {
      errors.add('Polygon needs three distinct coordinates.');
    }

    if (isVerified) {
      if (verifiedBy == null || verifiedBy!.trim().isEmpty) {
        errors.add('Verified boundary requires a verifier ID.');
      }

      if (verifiedAt == null) {
        errors.add('Verified boundary requires a verification date.');
      }
    }

    return errors;
  }

  /// Activation must require both a verified status and
  /// successful basic validation.
  bool get canActivate =>
      isVerified && validate().isEmpty;

  Map<String, dynamic> toMap() {
    return {
      'locationId': locationId,
      'locationType': locationType,
      'points': points
          .map(
            (point) => {
              'latitude': point.latitude,
              'longitude': point.longitude,
            },
          )
          .toList(),
      'sourceType': sourceType.name,
      'sourceName': sourceName,
      'sourceReference': sourceReference,
      'verificationStatus': verificationStatus.name,
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt == null
          ? null
          : Timestamp.fromDate(verifiedAt!),
      'verificationNotes': verificationNotes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ServiceLocationBoundary.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    final rawPoints = map['points'];

    final points = <GeoPoint>[];

    if (rawPoints is List) {
      for (final rawPoint in rawPoints) {
        if (rawPoint is GeoPoint) {
          points.add(rawPoint);
        } else if (rawPoint is Map) {
          final latitude = rawPoint['latitude'];
          final longitude = rawPoint['longitude'];

          if (latitude is num && longitude is num) {
            points.add(
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
      locationId: map['locationId'] as String? ?? '',
      locationType: map['locationType'] as String? ?? '',
      points: List.unmodifiable(points),
      sourceType: _parseEnum(
        BoundarySourceType.values,
        map['sourceType'],
        BoundarySourceType.importedGeoJson,
      ),
      sourceName: map['sourceName'] as String? ?? '',
      sourceReference: map['sourceReference'] as String? ?? '',
      verificationStatus: _parseEnum(
        BoundaryVerificationStatus.values,
        map['verificationStatus'],
        BoundaryVerificationStatus.pending,
      ),
      verifiedBy: map['verifiedBy'] as String?,
      verifiedAt: _parseDate(map['verifiedAt']),
      verificationNotes: map['verificationNotes'] as String?,
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updatedAt']) ?? DateTime.now(),
    );
  }

  static T _parseEnum<T extends Enum>(
    List<T> values,
    Object? rawValue,
    T fallback,
  ) {
    for (final value in values) {
      if (value.name == rawValue) {
        return value;
      }
    }

    return fallback;
  }

  static DateTime? _parseDate(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }
}

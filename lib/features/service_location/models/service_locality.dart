import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceLocality {
  final String id;
  final String cityId;
  final String areaId;
  final String name;

  /// Automatically retrieved geographic boundary.
  final List<GeoPoint> boundary;

  /// Admin has checked and verified the boundary.
  final bool boundaryVerified;

  /// Whether DOJO WALK provides service in this locality.
  final bool isServiceActive;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ServiceLocality({
    this.id = '',
    required this.cityId,
    required this.areaId,
    required this.name,
    this.boundary = const [],
    this.boundaryVerified = false,
    this.isServiceActive = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Convert locality data into Firestore-compatible fields.
  Map<String, dynamic> toMap({
    bool includeCreatedAt = false,
  }) {
    return {
      'cityId': cityId.trim(),
      'areaId': areaId.trim(),
      'name': name.trim(),
      'boundary': boundary,
      'boundaryVerified': boundaryVerified,
      'isServiceActive': isServiceActive,
      'updatedAt': FieldValue.serverTimestamp(),
      if (includeCreatedAt)
        'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Read locality data from Firestore.
  factory ServiceLocality.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    final boundaryPoints = <GeoPoint>[];
    final rawBoundary = data['boundary'];

    if (rawBoundary is List) {
      for (final point in rawBoundary) {
        if (point is GeoPoint) {
          boundaryPoints.add(point);
        } else if (point is Map) {
          final latitude = point['latitude'];
          final longitude = point['longitude'];

          if (latitude is num && longitude is num) {
            boundaryPoints.add(
              GeoPoint(
                latitude.toDouble(),
                longitude.toDouble(),
              ),
            );
          }
        }
      }
    }

    return ServiceLocality(
      id: id,
      cityId: data['cityId']?.toString() ?? '',
      areaId: data['areaId']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      boundary: boundaryPoints,
      boundaryVerified: data['boundaryVerified'] == true,
      isServiceActive: data['isServiceActive'] == true,
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  ServiceLocality copyWith({
    String? id,
    String? cityId,
    String? areaId,
    String? name,
    List<GeoPoint>? boundary,
    bool? boundaryVerified,
    bool? isServiceActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceLocality(
      id: id ?? this.id,
      cityId: cityId ?? this.cityId,
      areaId: areaId ?? this.areaId,
      name: name ?? this.name,
      boundary: boundary ?? this.boundary,
      boundaryVerified:
          boundaryVerified ?? this.boundaryVerified,
      isServiceActive:
          isServiceActive ?? this.isServiceActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

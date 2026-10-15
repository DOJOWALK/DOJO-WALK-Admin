import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceArea {
  final String id;
  final String cityId;
  final String name;

  /// Geographic boundary points.
  final List<GeoPoint> boundary;

  /// True only after the boundary is verified.
  final bool boundaryVerified;

  /// Controls DOJO WALK service availability in this area.
  final bool isServiceActive;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ServiceArea({
    this.id = '',
    required this.cityId,
    required this.name,
    this.boundary = const [],
    this.boundaryVerified = false,
    this.isServiceActive = false,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap({
    bool includeCreatedAt = false,
  }) {
    return {
      'cityId': cityId.trim(),
      'name': name.trim(),
      'boundary': boundary,
      'boundaryVerified': boundaryVerified,
      'isServiceActive': isServiceActive,
      'updatedAt': FieldValue.serverTimestamp(),
      if (includeCreatedAt)
        'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory ServiceArea.fromMap(
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

    return ServiceArea(
      id: id,
      cityId: data['cityId']?.toString() ?? '',
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

  ServiceArea copyWith({
    String? id,
    String? cityId,
    String? name,
    List<GeoPoint>? boundary,
    bool? boundaryVerified,
    bool? isServiceActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceArea(
      id: id ?? this.id,
      cityId: cityId ?? this.cityId,
      name: name ?? this.name,
      boundary: boundary ?? this.boundary,
      boundaryVerified: boundaryVerified ?? this.boundaryVerified,
      isServiceActive: isServiceActive ?? this.isServiceActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

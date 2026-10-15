import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceCity {
  final String id;
  final String name;
  final String state;
  final String country;

  /// Geographic boundary points.
  final List<GeoPoint> boundary;

  /// True only after an administrator verifies the boundary.
  final bool boundaryVerified;

  /// Controls whether DOJO WALK services are available in this city.
  final bool isServiceActive;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ServiceCity({
    this.id = '',
    required this.name,
    required this.state,
    this.country = 'India',
    this.boundary = const [],
    this.boundaryVerified = false,
    this.isServiceActive = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Convert the city model to Firestore data.
  Map<String, dynamic> toMap({
    bool includeCreatedAt = false,
  }) {
    return {
      'name': name.trim(),
      'state': state.trim(),
      'country': country.trim(),
      'boundary': boundary,
      'boundaryVerified': boundaryVerified,
      'isServiceActive': isServiceActive,
      'updatedAt': FieldValue.serverTimestamp(),
      if (includeCreatedAt)
        'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Create a city model from Firestore data.
  factory ServiceCity.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    final rawBoundary = data['boundary'];

    final boundaryPoints = <GeoPoint>[];

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

    return ServiceCity(
      id: id,
      name: data['name']?.toString() ?? '',
      state: data['state']?.toString() ?? '',
      country: data['country']?.toString() ?? 'India',
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

  ServiceCity copyWith({
    String? id,
    String? name,
    String? state,
    String? country,
    List<GeoPoint>? boundary,
    bool? boundaryVerified,
    bool? isServiceActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceCity(
      id: id ?? this.id,
      name: name ?? this.name,
      state: state ?? this.state,
      country: country ?? this.country,
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

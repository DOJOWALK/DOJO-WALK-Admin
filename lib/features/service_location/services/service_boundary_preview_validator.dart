import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'service_location_geometry.dart';

/// Client-side feedback for a boundary drawing preview.
///
/// This is intentionally limited to basic polygon geometry. It does not
/// establish geographic accuracy, serviceability, GIS verification or approval.
class ServiceBoundaryPreviewValidator {
  ServiceBoundaryPreviewValidator._();

  static const validFeedback =
      'Basic polygon geometry looks valid locally. Not GIS-verified.';

  static String feedback(List<LatLng> points) {
    if (points.length < 3) {
      return 'Add at least 3 points (${points.length}/3).';
    }

    final distinctPoints = points
        .map((point) => '${point.latitude.toStringAsFixed(7)},'
            '${point.longitude.toStringAsFixed(7)}')
        .toSet();
    if (distinctPoints.length < 3) {
      return 'Invalid preview: at least 3 distinct points are required.';
    }

    if (!points.every((point) =>
        point.latitude.isFinite &&
        point.longitude.isFinite &&
        point.latitude >= -90 &&
        point.latitude <= 90 &&
        point.longitude >= -180 &&
        point.longitude <= 180)) {
      return 'Invalid preview: one or more coordinates are out of range.';
    }

    final geoPoints = points
        .map((point) => GeoPoint(point.latitude, point.longitude))
        .toList(growable: false);
    if (!ServiceLocationGeometry.isValidPolygon(geoPoints)) {
      return 'Invalid preview: polygon crosses itself or encloses no area.';
    }

    return validFeedback;
  }

  static bool isValid(List<LatLng> points) =>
      feedback(points) == validFeedback;
}

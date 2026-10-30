import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dojo_admin/features/service_location/services/service_boundary_preview_validator.dart';

void main() {
  group('ServiceBoundaryPreviewValidator.feedback', () {
    test('asks for three points when preview is empty', () {
      expect(
        ServiceBoundaryPreviewValidator.feedback(const []),
        'Add at least 3 points (0/3).',
      );
    });

    test('rejects fewer than three points', () {
      expect(
        ServiceBoundaryPreviewValidator.feedback(const [
          LatLng(0, 0),
          LatLng(0, 2),
        ]),
        'Add at least 3 points (2/3).',
      );
    });

    test('rejects repeated vertices', () {
      expect(
        ServiceBoundaryPreviewValidator.feedback(const [
          LatLng(0, 0),
          LatLng(0, 0),
          LatLng(2, 2),
        ]),
        'Invalid preview: at least 3 distinct points are required.',
      );
    });

    test('rejects out-of-range coordinates before creating GeoPoints', () {
      expect(
        ServiceBoundaryPreviewValidator.feedback(const [
          LatLng(0, 0),
          LatLng(0, 2),
          LatLng(91, 1),
        ]),
        'Invalid preview: one or more coordinates are out of range.',
      );
    });

    test('rejects a self-intersecting polygon', () {
      expect(
        ServiceBoundaryPreviewValidator.feedback(const [
          LatLng(0, 0),
          LatLng(2, 2),
          LatLng(0, 2),
          LatLng(2, 0),
        ]),
        'Invalid preview: polygon crosses itself or encloses no area.',
      );
    });

    test('rejects a collinear polygon with no enclosed area', () {
      expect(
        ServiceBoundaryPreviewValidator.feedback(const [
          LatLng(0, 0),
          LatLng(0, 1),
          LatLng(0, 2),
        ]),
        'Invalid preview: polygon crosses itself or encloses no area.',
      );
    });

    test('accepts basic geometry but explicitly denies GIS verification', () {
      const polygon = [
        LatLng(0, 0),
        LatLng(0, 2),
        LatLng(2, 2),
        LatLng(2, 0),
      ];
      expect(
        ServiceBoundaryPreviewValidator.feedback(polygon),
        ServiceBoundaryPreviewValidator.validFeedback,
      );
      expect(ServiceBoundaryPreviewValidator.isValid(polygon), isTrue);
    });
  });
}

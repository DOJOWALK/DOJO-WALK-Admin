import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dojo_admin/features/service_location/models/service_location_boundary.dart';
import 'package:flutter_test/flutter_test.dart';

ServiceLocationBoundary makeBoundary(List<GeoPoint> points) {
  return ServiceLocationBoundary(
    id: 'boundary-1',
    locationId: 'area-1',
    locationType: 'area',
    points: points,
    sourceType: BoundarySourceType.importedGeoJson,
    sourceName: 'Test fixture',
    sourceReference: 'test://polygon',
    verificationStatus: BoundaryVerificationStatus.pending,
    verifiedBy: null,
    verifiedAt: null,
    verificationNotes: null,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
}

void main() {
  group('Service location polygon geometry validation', () {
    test('accepts a simple triangle', () {
      final boundary = makeBoundary(const [
        GeoPoint(28.0, 77.0),
        GeoPoint(28.0, 77.1),
        GeoPoint(28.1, 77.0),
      ]);

      expect(boundary.validate(), isEmpty);
    });

    test('accepts a ring with repeated closing vertex', () {
      final boundary = makeBoundary(const [
        GeoPoint(28.0, 77.0),
        GeoPoint(28.0, 77.1),
        GeoPoint(28.1, 77.0),
        GeoPoint(28.0, 77.0),
      ]);

      expect(boundary.validate(), isEmpty);
    });

    test('rejects a zero-area collinear polygon', () {
      final boundary = makeBoundary(const [
        GeoPoint(28.0, 77.0),
        GeoPoint(28.1, 77.1),
        GeoPoint(28.2, 77.2),
      ]);

      expect(
        boundary.validate(),
        contains('A polygon must enclose a non-zero area.'),
      );
    });

    test('rejects a self-intersecting bow-tie polygon', () {
      final boundary = makeBoundary(const [
        GeoPoint(28.0, 77.0),
        GeoPoint(28.1, 77.1),
        GeoPoint(28.0, 77.1),
        GeoPoint(28.1, 77.0),
      ]);

      expect(
        boundary.validate(),
        contains('A polygon must not self-intersect.'),
      );
    });

    test('rejects duplicate adjacent vertices', () {
      final boundary = makeBoundary(const [
        GeoPoint(28.0, 77.0),
        GeoPoint(28.0, 77.1),
        GeoPoint(28.0, 77.1),
        GeoPoint(28.1, 77.0),
      ]);

      expect(
        boundary.validate(),
        contains('A polygon must not contain duplicate adjacent points.'),
      );
    });
  });

    test('rejects latitude outside the valid geographic range', () {
      final boundary = makeBoundary(const [
        GeoPoint(91.0, 77.0),
        GeoPoint(28.0, 77.1),
        GeoPoint(28.1, 77.0),
      ]);

      expect(
        boundary.validate(),
        contains('Boundary point 1 is invalid.'),
      );
    });

    test('rejects longitude outside the valid geographic range', () {
      final boundary = makeBoundary(const [
        GeoPoint(28.0, 181.0),
        GeoPoint(28.0, 77.1),
        GeoPoint(28.1, 77.0),
      ]);

      expect(
        boundary.validate(),
        contains('Boundary point 1 is invalid.'),
      );
    });

    test('rejects non-finite polygon coordinates', () {
      final boundary = makeBoundary([
        GeoPoint(double.nan, 77.0),
        const GeoPoint(28.0, 77.1),
        const GeoPoint(28.1, 77.0),
      ]);

      expect(
        boundary.validate(),
        contains('Boundary point 1 is invalid.'),
      );
    });

}
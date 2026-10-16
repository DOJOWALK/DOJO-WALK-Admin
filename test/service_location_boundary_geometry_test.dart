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

  group('Imported boundary coordinate validation', () {
    ServiceLocationBoundary fromImportedPoints(List<Map<String, double>> points) {
      return ServiceLocationBoundary.fromMap('boundary-1', {
        'locationId': 'area-1',
        'locationType': 'area',
        'points': points,
        'sourceType': 'importedGeoJson',
        'sourceName': 'Test fixture',
        'sourceReference': 'test://polygon',
        'verificationStatus': 'pending',
      });
    }

    test('safely rejects imported latitude outside valid range', () {
      final boundary = fromImportedPoints([
        {'latitude': 91, 'longitude': 77},
        {'latitude': 28, 'longitude': 77.1},
        {'latitude': 28.1, 'longitude': 77},
      ]);

      expect(boundary.points, hasLength(2));
      expect(boundary.validate(), contains('A polygon must contain at least three points.'));
    });

    test('safely rejects imported longitude outside valid range', () {
      final boundary = fromImportedPoints([
        {'latitude': 28, 'longitude': 181},
        {'latitude': 28, 'longitude': 77.1},
        {'latitude': 28.1, 'longitude': 77},
      ]);

      expect(boundary.points, hasLength(2));
      expect(boundary.validate(), contains('A polygon must contain at least three points.'));
    });

    test('safely rejects non-finite imported coordinates', () {
      final boundary = fromImportedPoints([
        {'latitude': double.nan, 'longitude': 77},
        {'latitude': 28, 'longitude': 77.1},
        {'latitude': 28.1, 'longitude': 77},
      ]);

      expect(boundary.points, hasLength(2));
      expect(boundary.validate(), contains('A polygon must contain at least three points.'));
    });
  });
}

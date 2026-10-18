import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/models/service_location_boundary.dart';

ServiceLocationBoundary boundary(
  String id,
  BoundaryVerificationStatus status,
) {
  final now = DateTime.utc(2026, 1, 1);
  return ServiceLocationBoundary(
    id: id,
    locationId: 'location-1',
    locationType: 'city',
    points: const [
      GeoPoint(28.0, 77.0),
      GeoPoint(28.1, 77.0),
      GeoPoint(28.1, 77.1),
    ],
    sourceType: BoundarySourceType.manuallyDrawn,
    sourceName: 'Test source',
    sourceReference: 'test-reference',
    verificationStatus: status,
    verifiedBy: null,
    verifiedAt: null,
    verificationNotes: null,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('ServiceLocationBoundary.validate', () {
    test('rejects fewer than three distinct polygon vertices', () {
      final valid = boundary(
        'duplicate-points',
        BoundaryVerificationStatus.pending,
      );
      final invalid = ServiceLocationBoundary(
        id: valid.id,
        locationId: valid.locationId,
        locationType: valid.locationType,
        points: const [
          GeoPoint(28.0, 77.0),
          GeoPoint(28.1, 77.0),
          GeoPoint(28.0, 77.0),
        ],
        sourceType: valid.sourceType,
        sourceName: valid.sourceName,
        sourceReference: valid.sourceReference,
        verificationStatus: valid.verificationStatus,
        verifiedBy: valid.verifiedBy,
        verifiedAt: valid.verifiedAt,
        verificationNotes: valid.verificationNotes,
        createdAt: valid.createdAt,
        updatedAt: valid.updatedAt,
      );

      expect(
        invalid.validate(),
        contains('A polygon must contain at least three distinct points.'),
      );
    });

    test('rejects coordinates outside latitude and longitude ranges', () {
      final valid = boundary(
        'out-of-range-point',
        BoundaryVerificationStatus.pending,
      );
      final invalid = ServiceLocationBoundary(
        id: valid.id,
        locationId: valid.locationId,
        locationType: valid.locationType,
        points: const [
          GeoPoint(91, 77),
          GeoPoint(28, 181),
          GeoPoint(28.1, 77.1),
        ],
        sourceType: valid.sourceType,
        sourceName: valid.sourceName,
        sourceReference: valid.sourceReference,
        verificationStatus: valid.verificationStatus,
        verifiedBy: null,
        verifiedAt: null,
        verificationNotes: null,
        createdAt: valid.createdAt,
        updatedAt: valid.updatedAt,
      );

      expect(invalid.validate(), contains('Boundary point 1 is invalid.'));
      expect(invalid.validate(), contains('Boundary point 2 is invalid.'));
    });

    test('rejects unsupported location type and missing location ID', () {
      final valid = boundary(
        'bad-location-owner',
        BoundaryVerificationStatus.pending,
      );
      final invalid = ServiceLocationBoundary(
        id: valid.id,
        locationId: ' ',
        locationType: 'district',
        points: valid.points,
        sourceType: valid.sourceType,
        sourceName: valid.sourceName,
        sourceReference: valid.sourceReference,
        verificationStatus: valid.verificationStatus,
        verifiedBy: null,
        verifiedAt: null,
        verificationNotes: null,
        createdAt: valid.createdAt,
        updatedAt: valid.updatedAt,
      );

      expect(invalid.validate(), contains('Location ID is required.'));
      expect(
        invalid.validate(),
        contains('Location type must be city, area, or locality.'),
      );
    });

    test('requires a source name and source reference', () {
      final valid = boundary(
        'missing-source-metadata',
        BoundaryVerificationStatus.pending,
      );
      final invalid = ServiceLocationBoundary(
        id: valid.id,
        locationId: valid.locationId,
        locationType: valid.locationType,
        points: valid.points,
        sourceType: valid.sourceType,
        sourceName: ' ',
        sourceReference: '',
        verificationStatus: valid.verificationStatus,
        verifiedBy: valid.verifiedBy,
        verifiedAt: valid.verifiedAt,
        verificationNotes: valid.verificationNotes,
        createdAt: valid.createdAt,
        updatedAt: valid.updatedAt,
      );

      expect(invalid.validate(), contains('Boundary source name is required.'));
      expect(invalid.validate(), contains('Boundary source reference is required.'));
    });
  });

  group('selectBoundaryForManagement', () {
    test('prefers pending replacement over existing verified boundary', () {
      final selected = selectBoundaryForManagement([
        boundary('verified-old', BoundaryVerificationStatus.verified),
        boundary('pending-replacement', BoundaryVerificationStatus.pending),
      ]);

      expect(selected?.id, 'pending-replacement');
    });

    test('prefers rejected boundary over verified boundary', () {
      final selected = selectBoundaryForManagement([
        boundary('verified-old', BoundaryVerificationStatus.verified),
        boundary('rejected-replacement', BoundaryVerificationStatus.rejected),
      ]);

      expect(selected?.id, 'rejected-replacement');
    });

    test('opens verified boundary when no pending or rejected exists', () {
      final selected = selectBoundaryForManagement([
        boundary('verified-old', BoundaryVerificationStatus.verified),
      ]);

      expect(selected?.id, 'verified-old');
    });

    test('returns null when no boundaries exist', () {
      expect(selectBoundaryForManagement(const []), isNull);
    });

    test('sorts pending then rejected before verified boundaries', () {
      final ordered = sortBoundariesForChooser([
        boundary('verified', BoundaryVerificationStatus.verified),
        boundary('rejected', BoundaryVerificationStatus.rejected),
        boundary('pending', BoundaryVerificationStatus.pending),
        boundary('unknown', BoundaryVerificationStatus.notAvailable),
      ]);

      expect(
        ordered.map((item) => item.id).toList(),
        ['pending', 'rejected', 'verified', 'unknown'],
      );
    });

    test('sorts newest first within the same status without mutating input', () {
      final older = boundary('older', BoundaryVerificationStatus.pending);
      final newer = ServiceLocationBoundary(
        id: 'newer',
        locationId: older.locationId,
        locationType: older.locationType,
        points: older.points,
        sourceType: older.sourceType,
        sourceName: older.sourceName,
        sourceReference: older.sourceReference,
        verificationStatus: older.verificationStatus,
        verifiedBy: older.verifiedBy,
        verifiedAt: older.verifiedAt,
        verificationNotes: older.verificationNotes,
        createdAt: older.createdAt,
        updatedAt: DateTime.utc(2026, 2, 1),
      );
      final input = [newer, older];

      final ordered = sortBoundariesForChooser(input);

      expect(ordered.map((item) => item.id).toList(), ['newer', 'older']);
      expect(input.map((item) => item.id).toList(), ['newer', 'older']);
    });
  });
}
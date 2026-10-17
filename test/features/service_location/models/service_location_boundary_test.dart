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
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/services/service_zone_workflow_service.dart';

void main() {
  group('Zone boundary draft contract', () {
    test('builds the pending Firestore Rules payload without verification fields', () {
      final points = [
        const GeoPoint(28.60, 77.35),
        const GeoPoint(28.61, 77.36),
        const GeoPoint(28.62, 77.35),
        const GeoPoint(28.60, 77.35),
      ];

      final payload = ServiceZoneWorkflowService.boundaryDraftPayload(
        zoneId: 'zone-123',
        points: points,
        sourceType: 'manuallyDrawn',
        sourceName: 'Government GIS reference',
        sourceReference: 'https://example.gov.in/gis/zone-123',
      );

      expect(payload['locationId'], 'zone-123');
      expect(payload['locationType'], 'zone');
      expect(payload['points'], points);
      expect(payload['sourceType'], 'manuallyDrawn');
      expect(payload['sourceName'], 'Government GIS reference');
      expect(payload['sourceReference'], 'https://example.gov.in/gis/zone-123');
      expect(payload['verificationStatus'], 'pending');
      expect(payload.keys, containsAll(['createdAt', 'updatedAt']));
      expect(payload, isNot(contains('verifiedBy')));
      expect(payload, isNot(contains('verifiedAt')));
      expect(payload, isNot(contains('verificationNotes')));
    });

    test('rejects fewer than four polygon points', () {
      expect(
        () => ServiceZoneWorkflowService.boundaryDraftPayload(
          zoneId: 'zone-123',
          points: const [
            GeoPoint(28.60, 77.35),
            GeoPoint(28.61, 77.36),
            GeoPoint(28.62, 77.35),
          ],
          sourceType: 'manuallyDrawn',
          sourceName: 'Source',
          sourceReference: 'source-ref',
        ),
        throwsArgumentError,
      );
    });

    test('rejects missing provenance and unsupported source types', () {
      final points = const [
        GeoPoint(28.60, 77.35),
        GeoPoint(28.61, 77.36),
        GeoPoint(28.62, 77.35),
        GeoPoint(28.60, 77.35),
      ];

      expect(
        () => ServiceZoneWorkflowService.boundaryDraftPayload(
          zoneId: 'zone-123',
          points: points,
          sourceType: 'unknown',
          sourceName: 'Source',
          sourceReference: 'source-ref',
        ),
        throwsArgumentError,
      );
      expect(
        () => ServiceZoneWorkflowService.boundaryDraftPayload(
          zoneId: 'zone-123',
          points: points,
          sourceType: 'manuallyDrawn',
          sourceName: ' ',
          sourceReference: 'source-ref',
        ),
        throwsArgumentError,
      );
    });
  });

  group('ServiceZoneRecord', () {
    test('parses the canonical Zone fields from Firebase', () {
      final zone = ServiceZoneRecord.fromMap('zone-123', {
        'name': 'Crossings Republik North',
        'stateId': 'up',
        'districtId': 'gbn',
        'cityId': 'ghaziabad',
        'isServiceActive': true,
        'workflowStatus': 'active',
        'revision': 4,
        'verifiedBoundaryId': 'boundary-123',
        'approvedRevision': 4,
        'approvedBoundaryHash': 'approved-hash',
        'submittedBoundaryHash': 'approved-hash',
      });

      expect(zone.id, 'zone-123');
      expect(zone.name, 'Crossings Republik North');
      expect(zone.stateId, 'up');
      expect(zone.districtId, 'gbn');
      expect(zone.cityId, 'ghaziabad');
      expect(zone.isServiceActive, isTrue);
      expect(zone.workflowStatus, 'active');
      expect(zone.revision, 4);
      expect(zone.verifiedBoundaryId, 'boundary-123');
      expect(zone.approvedRevision, 4);
      expect(zone.approvedBoundaryHash, 'approved-hash');
      expect(zone.submittedBoundaryHash, 'approved-hash');
    });

    test('uses safe defaults for incomplete legacy documents', () {
      final zone = ServiceZoneRecord.fromMap('draft-zone', const {});

      expect(zone.id, 'draft-zone');
      expect(zone.name, isEmpty);
      expect(zone.isServiceActive, isFalse);
      expect(zone.workflowStatus, 'draft');
      expect(zone.revision, 1);
      expect(zone.verifiedBoundaryId, isNull);
      expect(zone.approvedRevision, isNull);
      expect(zone.approvedBoundaryHash, isNull);
      expect(zone.submittedBoundaryHash, isNull);
    });
  });
}

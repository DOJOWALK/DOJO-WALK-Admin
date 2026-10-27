import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/models/service_location_zone.dart';

void main() {
  group('ServiceLocationZone', () {
    Map<String, dynamic> zoneData({
      String workflowStatus = 'approved',
      String founderDecision = 'approve',
      String? approvalUid = 'founder-uid',
      int revision = 3,
      int approvedRevision = 3,
      String? verifiedBoundaryId = 'boundary-1',
      String? approvedBoundaryHash = 'canonical-hash',
    }) => {
      'name': 'Gaur City Zone 1',
      'stateId': 'UP',
      'districtId': 'GBN',
      'cityId': 'GREATER_NOIDA',
      'workflowStatus': workflowStatus,
      'revision': revision,
      'isServiceActive': false,
      'verifiedBoundaryId': verifiedBoundaryId,
      'founderDecision': founderDecision,
      'approvalUid': approvalUid,
      'approvedRevision': approvedRevision,
      'approvedBoundaryHash': approvedBoundaryHash,
    };

    test('recognizes recorded Founder approval for the current revision', () {
      final zone = ServiceLocationZone.fromMap('zone-1', zoneData());

      expect(zone.hasRecordedFounderApprovalForCurrentRevision, isTrue);
      expect(zone.mayRequestActivation, isTrue);
    });

    test('blocks activation when approved revision is stale', () {
      final zone = ServiceLocationZone.fromMap(
        'zone-1',
        zoneData(revision: 4, approvedRevision: 3),
      );

      expect(zone.hasRecordedFounderApprovalForCurrentRevision, isFalse);
      expect(zone.mayRequestActivation, isFalse);
    });

    test('blocks activation when there is no verified boundary reference', () {
      final zone = ServiceLocationZone.fromMap(
        'zone-1',
        zoneData(verifiedBoundaryId: null),
      );

      expect(zone.mayRequestActivation, isFalse);
    });

    test('blocks activation when Founder approval metadata is missing', () {
      final zone = ServiceLocationZone.fromMap(
        'zone-1',
        zoneData(approvalUid: null, approvedBoundaryHash: null),
      );

      expect(zone.hasRecordedFounderApprovalForCurrentRevision, isFalse);
      expect(zone.mayRequestActivation, isFalse);
    });

    test('blocks activation when workflow status is not approved', () {
      final zone = ServiceLocationZone.fromMap(
        'zone-1',
        zoneData(workflowStatus: 'submitted'),
      );

      expect(zone.mayRequestActivation, isFalse);
    });

    test('rejects unknown workflow status rather than guessing', () {
      expect(
        () => ServiceLocationZone.fromMap(
          'zone-1',
          zoneData(workflowStatus: 'unknown_status'),
        ),
        throwsFormatException,
      );
    });

    test('rejects missing canonical ancestry fields', () {
      final data = zoneData()..remove('cityId');

      expect(
        () => ServiceLocationZone.fromMap('zone-1', data),
        throwsFormatException,
      );
    });
  });
}

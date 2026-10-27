import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/models/service_location_zone.dart';

Map<String, dynamic> zoneData({
  String status = 'approved',
  int revision = 4,
  int? approvedRevision = 4,
  String? founderDecision = 'approve',
  String? approvalUid = 'founder-1',
  String? approvedBoundaryHash = 'sha256:boundary-v4',
  String? verifiedBoundaryId = 'boundary-1',
  bool active = false,
}) => {
      'name': 'Gaur City Zone 1',
      'stateId': 'up',
      'districtId': 'gautam-buddha-nagar',
      'cityId': 'greater-noida-west',
      'workflowStatus': status,
      'revision': revision,
      'isServiceActive': active,
      'verifiedBoundaryId': verifiedBoundaryId,
      'founderDecision': founderDecision,
      'approvalUid': approvalUid,
      'approvedRevision': approvedRevision,
      'approvedBoundaryHash': approvedBoundaryHash,
    };

void main() {
  group('Zone UI activation eligibility projection', () {
    test('current Founder approval and verified boundary allow activation request', () {
      final zone = ServiceLocationZone.fromMap('zone-1', zoneData());

      expect(zone.hasRecordedFounderApprovalForCurrentRevision, isTrue);
      expect(zone.mayRequestActivation, isTrue);
    });

    test('stale approved revision fails closed', () {
      final zone = ServiceLocationZone.fromMap(
        'zone-1',
        zoneData(revision: 5, approvedRevision: 4),
      );

      expect(zone.hasRecordedFounderApprovalForCurrentRevision, isFalse);
      expect(zone.mayRequestActivation, isFalse);
    });

    test('missing verified boundary fails closed', () {
      final zone = ServiceLocationZone.fromMap(
        'zone-1',
        zoneData(verifiedBoundaryId: null),
      );

      expect(zone.hasRecordedFounderApprovalForCurrentRevision, isTrue);
      expect(zone.mayRequestActivation, isFalse);
    });

    test('missing boundary hash fails closed', () {
      final zone = ServiceLocationZone.fromMap(
        'zone-1',
        zoneData(approvedBoundaryHash: null),
      );

      expect(zone.hasRecordedFounderApprovalForCurrentRevision, isFalse);
      expect(zone.mayRequestActivation, isFalse);
    });

    test('approval by an empty or missing Founder identity fails closed', () {
      for (final uid in <String?>[null, '  ']) {
        final zone = ServiceLocationZone.fromMap(
          'zone-1',
          zoneData(approvalUid: uid),
        );
        expect(zone.mayRequestActivation, isFalse);
      }
    });

    test('non-approval Founder decisions fail closed', () {
      for (final decision in ['reject', 'changes_required', null]) {
        final zone = ServiceLocationZone.fromMap(
          'zone-1',
          zoneData(founderDecision: decision),
        );
        expect(zone.mayRequestActivation, isFalse);
      }
    });

    test('non-approved workflow status fails closed', () {
      for (final status in ['draft', 'submitted', 'suspended', 'deactivated']) {
        final zone = ServiceLocationZone.fromMap(
          'zone-1',
          zoneData(status: status),
        );
        expect(zone.mayRequestActivation, isFalse);
      }
    });

    test('already-active Zone cannot show an activation request', () {
      final zone = ServiceLocationZone.fromMap(
        'zone-1',
        zoneData(active: true),
      );

      expect(zone.hasRecordedFounderApprovalForCurrentRevision, isTrue);
      expect(zone.mayRequestActivation, isFalse);
    });
  });
}

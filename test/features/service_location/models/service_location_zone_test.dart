import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/models/service_location_zone.dart';

void main() {
  group('ServiceLocationZone', () {
    Map<String, dynamic> zoneData({
      String workflowStatus = 'approved',
      String approvalStatus = 'approved',
      int revision = 3,
      int approvedRevision = 3,
      String boundaryHash = 'hash-current',
      String approvedBoundaryHash = 'hash-current',
    }) => {
      'name': 'Gaur City Zone 1',
      'stateId': 'UP',
      'districtId': 'GBN',
      'cityId': 'GREATER_NOIDA',
      'workflowStatus': workflowStatus,
      'revision': revision,
      'isServiceActive': false,
      'boundaryHash': boundaryHash,
      'approvalStatus': approvalStatus,
      'approvedRevision': approvedRevision,
      'approvedBoundaryHash': approvedBoundaryHash,
    };

    test('accepts activation readiness only for current Founder approval', () {
      final zone = ServiceLocationZone.fromMap('zone-1', zoneData());

      expect(zone.hasCurrentFounderApproval, isTrue);
      expect(zone.mayRequestActivation, isTrue);
    });

    test('blocks activation when approved revision is stale', () {
      final zone = ServiceLocationZone.fromMap(
        'zone-1',
        zoneData(revision: 4, approvedRevision: 3),
      );

      expect(zone.hasCurrentFounderApproval, isFalse);
      expect(zone.mayRequestActivation, isFalse);
    });

    test('blocks activation when boundary hash changed after approval', () {
      final zone = ServiceLocationZone.fromMap(
        'zone-1',
        zoneData(boundaryHash: 'hash-new', approvedBoundaryHash: 'hash-old'),
      );

      expect(zone.hasCurrentFounderApproval, isFalse);
      expect(zone.mayRequestActivation, isFalse);
    });

    test('blocks activation when status is not approved', () {
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

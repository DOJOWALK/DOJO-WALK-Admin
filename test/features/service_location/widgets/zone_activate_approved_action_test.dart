import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/models/service_location_zone.dart';
import 'package:dojo_admin/features/service_location/models/zone_role_permissions.dart';
import 'package:dojo_admin/features/service_location/widgets/zone_activate_approved_action.dart';

void main() {
  ServiceLocationZone zone({
    bool active = false,
    ZoneWorkflowStatus status = ZoneWorkflowStatus.approved,
    String? decision = 'approve',
    String? approvalUid = 'founder-uid',
    int? approvedRevision = 2,
    String? approvedHash = 'canonical-hash',
    String? boundaryId = 'verified-boundary',
  }) => ServiceLocationZone(
        id: 'zone-1',
        name: 'Gaur City Zone 1',
        stateId: 'UP',
        districtId: 'GBN',
        cityId: 'GREATER_NOIDA',
        workflowStatus: status,
        revision: 2,
        isServiceActive: active,
        verifiedBoundaryId: boundaryId,
        founderDecision: decision,
        approvalUid: approvalUid,
        approvedRevision: approvedRevision,
        approvedBoundaryHash: approvedHash,
      );

  Future<void> pumpAction(
    WidgetTester tester, {
    required String? role,
    bool isActive = true,
    bool busy = false,
    bool zoneActive = false,
    ZoneWorkflowStatus status = ZoneWorkflowStatus.approved,
    String? decision = 'approve',
    String? approvalUid = 'founder-uid',
    int? approvedRevision = 2,
    String? approvedHash = 'canonical-hash',
    String? boundaryId = 'verified-boundary',
  }) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ZoneActivateApprovedAction(
          permissions: ZoneRolePermissions.fromFirestore(role: role, isActive: isActive),
          zone: zone(
            active: zoneActive,
            status: status,
            decision: decision,
            approvalUid: approvalUid,
            approvedRevision: approvedRevision,
            approvedHash: approvedHash,
            boundaryId: boundaryId,
          ),
          busy: busy,
          onPressed: () {},
        ),
      ),
    ));
  }

  group('ZoneActivateApprovedAction role and approval gate', () {
    testWidgets('active Central Admin sees action for current approved revision', (tester) async {
      await pumpAction(tester, role: 'central_admin');
      expect(find.text('Activate Approved Zone'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNotNull);
    });

    testWidgets('Founder cannot activate Zone', (tester) async {
      await pumpAction(tester, role: 'founder');
      expect(find.text('Activate Approved Zone'), findsNothing);
    });

    testWidgets('technical Super Admin cannot activate Zone', (tester) async {
      await pumpAction(tester, role: 'super_admin');
      expect(find.text('Activate Approved Zone'), findsNothing);
    });

    testWidgets('inactive Central Admin cannot activate Zone', (tester) async {
      await pumpAction(tester, role: 'central_admin', isActive: false);
      expect(find.text('Activate Approved Zone'), findsNothing);
    });

    testWidgets('already active Zone cannot be activated again', (tester) async {
      await pumpAction(tester, role: 'central_admin', zoneActive: true, status: ZoneWorkflowStatus.active);
      expect(find.text('Activate Approved Zone'), findsNothing);
    });

    testWidgets('stale approval revision prevents activation', (tester) async {
      await pumpAction(tester, role: 'central_admin', approvedRevision: 1);
      expect(find.text('Activate Approved Zone'), findsNothing);
    });

    testWidgets('missing Founder approval prevents activation', (tester) async {
      await pumpAction(tester, role: 'central_admin', approvalUid: null);
      expect(find.text('Activate Approved Zone'), findsNothing);
    });

    testWidgets('missing approved boundary hash prevents activation', (tester) async {
      await pumpAction(tester, role: 'central_admin', approvedHash: null);
      expect(find.text('Activate Approved Zone'), findsNothing);
    });

    testWidgets('missing verified boundary prevents activation', (tester) async {
      await pumpAction(tester, role: 'central_admin', boundaryId: null);
      expect(find.text('Activate Approved Zone'), findsNothing);
    });

    testWidgets('busy state disables activation', (tester) async {
      await pumpAction(tester, role: 'central_admin', busy: true);
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    });
  });
}
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/models/service_location_zone.dart';
import 'package:dojo_admin/features/service_location/models/zone_role_permissions.dart';
import 'package:dojo_admin/features/service_location/widgets/zone_submit_for_founder_review_action.dart';

void main() {
  ServiceLocationZone zone({
    ZoneWorkflowStatus status = ZoneWorkflowStatus.draft,
    String? boundaryId = 'boundary-1',
    bool active = false,
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
      );

  Future<void> pumpAction(
    WidgetTester tester, {
    required String? role,
    bool isActive = true,
    bool busy = false,
    ZoneWorkflowStatus status = ZoneWorkflowStatus.draft,
    String? boundaryId = 'boundary-1',
    bool zoneActive = false,
  }) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ZoneSubmitForFounderReviewAction(
          permissions: ZoneRolePermissions.fromFirestore(role: role, isActive: isActive),
          zone: zone(status: status, boundaryId: boundaryId, active: zoneActive),
          busy: busy,
          onPressed: () {},
        ),
      ),
    ));
  }

  group('ZoneSubmitForFounderReviewAction gate', () {
    testWidgets('active Central Admin sees action for draft with verified boundary', (tester) async {
      await pumpAction(tester, role: 'central_admin');
      expect(find.text('Submit for Founder Review'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNotNull);
    });

    testWidgets('changes-required Zone can be resubmitted', (tester) async {
      await pumpAction(tester, role: 'central_admin', status: ZoneWorkflowStatus.changesRequired);
      expect(find.text('Submit for Founder Review'), findsOneWidget);
    });

    testWidgets('Founder cannot submit Zone for own review', (tester) async {
      await pumpAction(tester, role: 'founder');
      expect(find.text('Submit for Founder Review'), findsNothing);
    });

    testWidgets('technical Super Admin cannot submit Zone for review', (tester) async {
      await pumpAction(tester, role: 'super_admin');
      expect(find.text('Submit for Founder Review'), findsNothing);
    });

    testWidgets('inactive Central Admin cannot submit Zone', (tester) async {
      await pumpAction(tester, role: 'central_admin', isActive: false);
      expect(find.text('Submit for Founder Review'), findsNothing);
    });

    testWidgets('missing verified boundary hides submission action', (tester) async {
      await pumpAction(tester, role: 'central_admin', boundaryId: null);
      expect(find.text('Submit for Founder Review'), findsNothing);
    });

    testWidgets('active Zone cannot be submitted again', (tester) async {
      await pumpAction(tester, role: 'central_admin', zoneActive: true);
      expect(find.text('Submit for Founder Review'), findsNothing);
    });

    testWidgets('unsupported workflow status hides submission action', (tester) async {
      await pumpAction(tester, role: 'central_admin', status: ZoneWorkflowStatus.submitted);
      expect(find.text('Submit for Founder Review'), findsNothing);
    });

    testWidgets('busy state disables submission action', (tester) async {
      await pumpAction(tester, role: 'central_admin', busy: true);
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    });
  });
}
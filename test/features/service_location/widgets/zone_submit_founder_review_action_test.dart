import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/models/service_location_zone.dart';
import 'package:dojo_admin/features/service_location/models/zone_role_permissions.dart';
import 'package:dojo_admin/features/service_location/widgets/zone_submit_founder_review_action.dart';

void main() {
  ServiceLocationZone zone({
    bool active = false,
    ZoneWorkflowStatus status = ZoneWorkflowStatus.draft,
    String? boundaryId = 'verified-boundary-1',
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
    bool zoneActive = false,
    ZoneWorkflowStatus status = ZoneWorkflowStatus.draft,
    String? boundaryId = 'verified-boundary-1',
  }) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ZoneSubmitFounderReviewAction(
          permissions: ZoneRolePermissions.fromFirestore(role: role, isActive: isActive),
          zone: zone(active: zoneActive, status: status, boundaryId: boundaryId),
          busy: busy,
          onPressed: () {},
        ),
      ),
    ));
  }

  group('ZoneSubmitFounderReviewAction role and workflow gate', () {
    testWidgets('active Central Admin sees action for verified draft', (tester) async {
      await pumpAction(tester, role: 'central_admin');
      expect(find.text('Submit for Founder Review'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNotNull);
    });

    testWidgets('Founder cannot submit own Zone for review', (tester) async {
      await pumpAction(tester, role: 'founder');
      expect(find.text('Submit for Founder Review'), findsNothing);
    });

    testWidgets('technical Super Admin cannot submit Zone', (tester) async {
      await pumpAction(tester, role: 'super_admin');
      expect(find.text('Submit for Founder Review'), findsNothing);
    });

    testWidgets('inactive Central Admin cannot submit Zone', (tester) async {
      await pumpAction(tester, role: 'central_admin', isActive: false);
      expect(find.text('Submit for Founder Review'), findsNothing);
    });

    testWidgets('unverified boundary prevents submission', (tester) async {
      await pumpAction(tester, role: 'central_admin', boundaryId: null);
      expect(find.text('Submit for Founder Review'), findsNothing);
    });

    testWidgets('active Zone cannot be resubmitted', (tester) async {
      await pumpAction(tester, role: 'central_admin', zoneActive: true, status: ZoneWorkflowStatus.active);
      expect(find.text('Submit for Founder Review'), findsNothing);
    });

    testWidgets('submitted Zone cannot be submitted twice', (tester) async {
      await pumpAction(tester, role: 'central_admin', status: ZoneWorkflowStatus.submitted);
      expect(find.text('Submit for Founder Review'), findsNothing);
    });

    testWidgets('busy state disables submission', (tester) async {
      await pumpAction(tester, role: 'central_admin', busy: true);
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    });
  });
}
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/models/service_location_zone.dart';
import 'package:dojo_admin/features/service_location/models/zone_role_permissions.dart';
import 'package:dojo_admin/features/service_location/widgets/zone_founder_review_action.dart';

void main() {
  ServiceLocationZone zone(ZoneWorkflowStatus status) => ServiceLocationZone(
        id: 'zone-1',
        name: 'Gaur City Zone 1',
        stateId: 'UP',
        districtId: 'GBN',
        cityId: 'GREATER_NOIDA',
        workflowStatus: status,
        revision: 2,
        isServiceActive: false,
      );

  Future<void> pumpAction(
    WidgetTester tester, {
    required String? role,
    bool isActive = true,
    bool busy = false,
    ZoneWorkflowStatus status = ZoneWorkflowStatus.submitted,
  }) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ZoneFounderReviewAction(
          permissions: ZoneRolePermissions.fromFirestore(
            role: role,
            isActive: isActive,
          ),
          zone: zone(status),
          busy: busy,
          onPressed: () {},
        ),
      ),
    ));
  }

  group('ZoneFounderReviewAction role and state gate', () {
    testWidgets('active Founder sees enabled review action for submitted Zone', (tester) async {
      await pumpAction(tester, role: 'founder');
      expect(find.text('Founder Review'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNotNull);
    });

    testWidgets('Central Admin cannot see Founder review action', (tester) async {
      await pumpAction(tester, role: 'central_admin');
      expect(find.text('Founder Review'), findsNothing);
    });

    testWidgets('technical Super Admin cannot see Founder review action', (tester) async {
      await pumpAction(tester, role: 'super_admin');
      expect(find.text('Founder Review'), findsNothing);
    });

    testWidgets('inactive Founder cannot see Founder review action', (tester) async {
      await pumpAction(tester, role: 'founder', isActive: false);
      expect(find.text('Founder Review'), findsNothing);
    });

    testWidgets('Founder review is hidden when no decision is pending', (tester) async {
      await pumpAction(tester, role: 'founder', status: ZoneWorkflowStatus.draft);
      expect(find.text('Founder Review'), findsNothing);
    });

    testWidgets('busy state disables review action', (tester) async {
      await pumpAction(tester, role: 'founder', busy: true);
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    });
  });
}
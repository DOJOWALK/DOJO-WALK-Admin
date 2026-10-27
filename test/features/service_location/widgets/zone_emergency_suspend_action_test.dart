import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/models/service_location_zone.dart';
import 'package:dojo_admin/features/service_location/models/zone_role_permissions.dart';
import 'package:dojo_admin/features/service_location/widgets/zone_emergency_suspend_action.dart';

void main() {
  ServiceLocationZone zone({bool active = true}) => ServiceLocationZone(
        id: 'zone-1',
        name: 'Gaur City Zone 1',
        stateId: 'UP',
        districtId: 'GBN',
        cityId: 'GREATER_NOIDA',
        workflowStatus: active ? ZoneWorkflowStatus.active : ZoneWorkflowStatus.approved,
        revision: 2,
        isServiceActive: active,
      );

  Future<void> pumpAction(
    WidgetTester tester, {
    required String? role,
    bool isActive = true,
    bool busy = false,
    bool zoneActive = true,
  }) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ZoneEmergencySuspendAction(
          permissions: ZoneRolePermissions.fromFirestore(
            role: role,
            isActive: isActive,
          ),
          zone: zone(active: zoneActive),
          busy: busy,
          onPressed: () {},
        ),
      ),
    ));
  }

  group('ZoneEmergencySuspendAction role and state gate', () {
    testWidgets('active Central Admin sees enabled emergency action', (tester) async {
      await pumpAction(tester, role: 'central_admin');
      expect(find.text('Emergency Suspend'), findsOneWidget);
      expect(tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed, isNotNull);
    });

    testWidgets('Founder cannot see emergency suspension action', (tester) async {
      await pumpAction(tester, role: 'founder');
      expect(find.text('Emergency Suspend'), findsNothing);
    });

    testWidgets('technical Super Admin cannot see emergency suspension action', (tester) async {
      await pumpAction(tester, role: 'super_admin');
      expect(find.text('Emergency Suspend'), findsNothing);
    });

    testWidgets('inactive Central Admin cannot see emergency suspension action', (tester) async {
      await pumpAction(tester, role: 'central_admin', isActive: false);
      expect(find.text('Emergency Suspend'), findsNothing);
    });

    testWidgets('already inactive Zone has no emergency suspension action', (tester) async {
      await pumpAction(tester, role: 'central_admin', zoneActive: false);
      expect(find.text('Emergency Suspend'), findsNothing);
    });

    testWidgets('busy state disables emergency suspension action', (tester) async {
      await pumpAction(tester, role: 'central_admin', busy: true);
      expect(tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed, isNull);
    });
  });
}
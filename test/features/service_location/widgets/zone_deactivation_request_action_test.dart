import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/models/service_location_zone.dart';
import 'package:dojo_admin/features/service_location/models/zone_role_permissions.dart';
import 'package:dojo_admin/features/service_location/widgets/zone_deactivation_request_action.dart';

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
        body: ZoneDeactivationRequestAction(
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

  group('ZoneDeactivationRequestAction role and state gate', () {
    testWidgets('active Central Admin sees enabled action for active Zone', (tester) async {
      await pumpAction(tester, role: 'central_admin');
      expect(find.text('Request Deactivation'), findsOneWidget);
      expect(tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed, isNotNull);
    });

    testWidgets('Founder cannot see deactivation request action', (tester) async {
      await pumpAction(tester, role: 'founder');
      expect(find.text('Request Deactivation'), findsNothing);
    });

    testWidgets('technical Super Admin cannot see deactivation request action', (tester) async {
      await pumpAction(tester, role: 'super_admin');
      expect(find.text('Request Deactivation'), findsNothing);
    });

    testWidgets('inactive Central Admin cannot see deactivation request action', (tester) async {
      await pumpAction(tester, role: 'central_admin', isActive: false);
      expect(find.text('Request Deactivation'), findsNothing);
    });

    testWidgets('inactive Zone has no deactivation request action', (tester) async {
      await pumpAction(tester, role: 'central_admin', zoneActive: false);
      expect(find.text('Request Deactivation'), findsNothing);
    });

    testWidgets('busy state disables deactivation request action', (tester) async {
      await pumpAction(tester, role: 'central_admin', busy: true);
      expect(tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed, isNull);
    });
  });
}
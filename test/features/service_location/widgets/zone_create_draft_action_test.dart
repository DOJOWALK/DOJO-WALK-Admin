import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/models/zone_role_permissions.dart';
import 'package:dojo_admin/features/service_location/widgets/zone_create_draft_action.dart';

void main() {
  Future<void> pumpAction(
    WidgetTester tester, {
    required String? role,
    bool isActive = true,
    bool busy = false,
  }) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ZoneCreateDraftAction(
          permissions: ZoneRolePermissions.fromFirestore(
            role: role,
            isActive: isActive,
          ),
          busy: busy,
          onPressed: () {},
        ),
      ),
    ));
  }

  group('ZoneCreateDraftAction widget authorization visibility', () {
    testWidgets('active Central Admin can press Create Zone Draft', (tester) async {
      await pumpAction(tester, role: 'central_admin');

      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Create Zone Draft'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('Founder cannot create a Zone draft', (tester) async {
      await pumpAction(tester, role: 'founder');

      expect(find.text('Create Zone Draft'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Create Zone Draft'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('technical Super Admin cannot create a Zone draft', (tester) async {
      await pumpAction(tester, role: 'super_admin');

      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Create Zone Draft'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('inactive Central Admin cannot create a Zone draft', (tester) async {
      await pumpAction(tester, role: 'central_admin', isActive: false);

      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Create Zone Draft'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('busy state disables create action', (tester) async {
      await pumpAction(tester, role: 'central_admin', busy: true);

      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Create Zone Draft'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNull);
    });
  });
}

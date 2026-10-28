import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/screens/suspended_zones_screen.dart';

void main() {
  group('SuspendedZonesScreen UI prototype', () {
    testWidgets('shows prototype warning and operational safeguards',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SuspendedZonesScreen()),
      );

      expect(find.text('Suspended / Deactivated Zones'), findsOneWidget);
      expect(find.textContaining('PROTOTYPE ONLY'), findsOneWidget);
      expect(find.text('Required safeguards'), findsOneWidget);
      expect(find.text('Existing bookings'), findsOneWidget);
      expect(find.text('Walk already in progress'), findsOneWidget);
      expect(find.text('Reactivation is a new approval gate'), findsOneWidget);
      expect(find.text('Append-only audit trail'), findsOneWidget);
    });

    testWidgets('filters example zones by status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SuspendedZonesScreen()),
      );

      expect(find.text('Example Zone North'), findsOneWidget);
      expect(find.text('Example Zone South'), findsOneWidget);
      expect(find.text('Example Zone Central'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Deactivated'));
      await tester.pumpAndSettle();

      expect(find.text('Example Zone South'), findsOneWidget);
      expect(find.text('Example Zone North'), findsNothing);
      expect(find.text('Example Zone Central'), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Suspended'));
      await tester.pumpAndSettle();

      expect(find.text('Example Zone North'), findsOneWidget);
      expect(find.text('Example Zone Central'), findsOneWidget);
      expect(find.text('Example Zone South'), findsNothing);
    });

    testWidgets('keeps case and reactivation actions disabled in prototype',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SuspendedZonesScreen()),
      );

      final viewCase = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'View case').first,
      );
      final requestReactivation = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Request reactivation').first,
      );

      expect(viewCase.onPressed, isNull);
      expect(requestReactivation.onPressed, isNull);
    });

    testWidgets('shows audit history as example data', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SuspendedZonesScreen()),
      );

      expect(find.textContaining('not live audit data'), findsNWidgets(3));
      await tester.tap(find.text('Audit history').first);
      await tester.pumpAndSettle();

      expect(find.text('Suspension requested'), findsOneWidget);
      expect(find.text('Zone suspended'), findsOneWidget);
    });
  });
}

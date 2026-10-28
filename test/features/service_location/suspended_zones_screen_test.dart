import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/screens/suspended_zones_screen.dart';

void main() {
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  group('SuspendedZonesScreen UI prototype', () {
    testWidgets('shows prototype warning and operational safeguards',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SuspendedZonesScreen()),
      );

      expect(find.text('Suspended / Deactivated Zones'), findsOneWidget);
      expect(find.textContaining('PROTOTYPE ONLY'), findsOneWidget);

      await scrollTo(tester, find.text('Required safeguards'));
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

      for (final zone in [
        'Example Zone North',
        'Example Zone South',
        'Example Zone Central',
      ]) {
        await scrollTo(tester, find.text(zone));
        expect(find.text(zone), findsOneWidget);
      }

      await scrollTo(tester, find.widgetWithText(ChoiceChip, 'Deactivated'));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Deactivated'));
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('Example Zone South'));
      expect(find.text('Example Zone South'), findsOneWidget);

      await scrollTo(tester, find.widgetWithText(ChoiceChip, 'Suspended'));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Suspended'));
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('Example Zone North'));
      expect(find.text('Example Zone North'), findsOneWidget);
      await scrollTo(tester, find.text('Example Zone Central'));
      expect(find.text('Example Zone Central'), findsOneWidget);
    });

    testWidgets('keeps case and reactivation actions disabled in prototype',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SuspendedZonesScreen()),
      );

      await scrollTo(tester, find.text('Example Zone North'));
      await scrollTo(tester, find.widgetWithText(OutlinedButton, 'View case'));
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

      await scrollTo(tester, find.text('Example Zone North'));
      await scrollTo(tester, find.text('Audit history').first);
      expect(find.textContaining('not live audit data'), findsWidgets);
      await tester.tap(find.text('Audit history').first);
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('Suspension requested'));
      expect(find.text('Suspension requested'), findsOneWidget);
      expect(find.text('Zone suspended'), findsOneWidget);
    });
  });
}

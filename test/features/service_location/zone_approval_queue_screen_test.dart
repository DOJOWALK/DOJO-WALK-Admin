import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/screens/zone_approval_queue_screen.dart';

void main() {
  group('ZoneApprovalQueueScreen UI prototype', () {
    testWidgets('explains Founder authority and keeps server decisions disabled',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ZoneApprovalQueueScreen()),
      );

      expect(find.text('Founder Approval Queue'), findsOneWidget);
      expect(find.text('Business approval gate'), findsOneWidget);
      expect(find.textContaining('Founder/CEO makes the final business decision'),
          findsOneWidget);
      expect(find.textContaining('Super Admin does not inherit Founder approval authority'),
          findsOneWidget);
      expect(find.textContaining('No server actions enabled'), findsOneWidget);
      expect(find.text('Decision disabled — not connected'), findsWidgets);

      final decisionButtons = tester.widgetList<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Decision disabled — not connected'),
      );
      expect(decisionButtons, isNotEmpty);
      expect(decisionButtons.every((button) => button.onPressed == null), isTrue);
    });

    testWidgets('filters blocked revisions and restores all examples',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ZoneApprovalQueueScreen()),
      );

      expect(find.text('Example Zone A'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Blocked — re-review'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Example Zone B'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Example Zone B'), findsOneWidget);
      expect(find.text('Example Zone A'), findsNothing);

      await tester.drag(find.byType(ListView).first, const Offset(0, 1600));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Example Zone A'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Example Zone A'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Example Zone B'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Example Zone B'), findsOneWidget);
    });
  });

  testWidgets('approval details remain readable on a narrow mobile viewport',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: ZoneApprovalQueueScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Founder Approval Queue'), findsOneWidget);
    expect(find.text('Example Zone A'), findsOneWidget);
    expect(find.text('Boundary integrity'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

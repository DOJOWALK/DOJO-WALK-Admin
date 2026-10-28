import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/support/screens/support_center_screen.dart';

void main() {
  testWidgets('shows example queue and prioritizes safety cases',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SupportCenterScreen()),
    );

    expect(find.text('Support & Complaints'), findsOneWidget);
    expect(find.textContaining('not connected to live cases'), findsOneWidget);
    expect(find.text('CASE-EX-001'), findsOneWidget);
    expect(find.text('S0 — Critical safety/security'), findsOneWidget);
    expect(find.text('Transfer disabled'), findsWidgets);
    expect(find.text('Resolve disabled'), findsWidgets);
  });

  testWidgets('severity filter narrows the example support queue',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SupportCenterScreen()),
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'S1'));
    await tester.pumpAndSettle();

    expect(find.text('CASE-EX-002'), findsOneWidget);
    expect(find.text('CASE-EX-001'), findsNothing);
    expect(find.text('CASE-EX-003'), findsNothing);
  });

  testWidgets('case detail dialog states that the record is an example',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SupportCenterScreen()),
    );

    await tester.tap(find.text('View example case').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('No live support or incident data was accessed'),
        findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  });
}

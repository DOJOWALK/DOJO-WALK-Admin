import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/finance/screens/finance_operations_screen.dart';

void main() {
  testWidgets('shows cashless finance controls with no live transactions',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: FinanceOperationsScreen()),
    );

    expect(find.text('Finance Operations'), findsOneWidget);
    expect(find.textContaining('No payment gateway'), findsOneWidget);
    expect(find.textContaining('Cash is not accepted'), findsOneWidget);
    expect(find.text('PAY-EX-001'), findsOneWidget);
    expect(find.text('Verify disabled'), findsWidgets);
    expect(find.text('Approve disabled'), findsWidgets);
    expect(find.text('Reconcile disabled'), findsWidgets);
  });

  testWidgets('switches between payment, refund and payout examples',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: FinanceOperationsScreen()),
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Refunds'));
    await tester.pumpAndSettle();
    expect(find.text('REF-EX-001'), findsOneWidget);
    expect(find.text('PAY-EX-001'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Walker payouts'));
    await tester.pumpAndSettle();
    expect(find.text('PAYOUT-EX-001'), findsOneWidget);
    expect(find.text('REF-EX-001'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Reconciliation'));
    await tester.pumpAndSettle();
    expect(find.text('RECON-EX-001'), findsOneWidget);
    expect(find.text('PAYOUT-EX-001'), findsNothing);
  });
}

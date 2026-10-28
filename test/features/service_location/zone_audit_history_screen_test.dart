import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/screens/zone_audit_history_screen.dart';

void main() {
  Widget app() => const MaterialApp(home: ZoneAuditHistoryScreen());

  testWidgets('labels audit history as sample data, not live audit records',
      (tester) async {
    await tester.pumpWidget(app());

    expect(find.text('Zone Audit History'), findsOneWidget);
    expect(find.textContaining('not real audit records'), findsOneWidget);
    expect(find.textContaining('Live audit_logs connection'), findsOneWidget);
    expect(find.text('3 examples'), findsOneWidget);
    expect(find.text('Zone readiness submitted'), findsOneWidget);
  });

  testWidgets('search filters by event, zone, actor and status; clear restores',
      (tester) async {
    await tester.pumpWidget(app());

    await tester.enterText(find.byType(TextField).first, 'Founder / CEO');
    await tester.pumpAndSettle();

    expect(find.text('1 examples'), findsOneWidget);
    expect(find.text('Boundary revision requested'), findsOneWidget);
    expect(find.text('Zone readiness submitted'), findsNothing);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();

    expect(find.text('3 examples'), findsOneWidget);
    expect(find.text('Zone readiness submitted'), findsOneWidget);
    expect(find.text('Boundary revision requested'), findsOneWidget);
    expect(find.text('Zone suspended for safety review'), findsOneWidget);
  });

  testWidgets('no-match search shows recovery state and clear control',
      (tester) async {
    await tester.pumpWidget(app());

    await tester.enterText(find.byType(TextField).first, 'not-a-real-event');
    await tester.pumpAndSettle();

    expect(find.text('0 examples'), findsOneWidget);
    expect(find.text('No matching example events'), findsOneWidget);
    expect(find.byTooltip('Clear search'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();

    expect(find.text('3 examples'), findsOneWidget);
    expect(find.text('No matching example events'), findsNothing);
  });
}

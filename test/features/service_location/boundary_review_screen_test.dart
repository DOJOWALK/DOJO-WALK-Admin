import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/screens/boundary_review_screen.dart';

void main() {
  Widget app() => const MaterialApp(home: BoundaryReviewScreen());

  testWidgets('labels the screen as a UI preview with no live records', (tester) async {
    await tester.pumpWidget(app());

    expect(find.text('Boundary Review'), findsOneWidget);
    expect(find.textContaining('not connected to live records'), findsOneWidget);
    expect(find.textContaining('mock data'), findsOneWidget);
  });

  testWidgets('shows explicit statuses, Zone ID, revision, polygon and hash evidence', (tester) async {
    await tester.pumpWidget(app());

    expect(find.text('Pending review'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('Needs changes'), findsOneWidget);
    expect(find.text('EXAMPLE-ZONE-001'), findsOneWidget);
    expect(find.text('1'), findsNWidgets(2));
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Not verified'), findsOneWidget);
    expect(find.text('Hash changed'), findsOneWidget);
    expect(find.text('EXAMPLE-SHA256-ABC123'), findsOneWidget);
    expect(find.text('Polygon verification'), findsNWidgets(4));
  });

  testWidgets('review and decision actions are disabled in prototype', (tester) async {
    await tester.pumpWidget(app());

    expect(find.widgetWithText(OutlinedButton, 'Review evidence'), findsNWidgets(4));
    expect(find.widgetWithText(OutlinedButton, 'Request changes'), findsNWidgets(4));
    expect(find.widgetWithText(FilledButton, 'Founder decision'), findsNWidgets(4));
    expect(tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Review evidence').first).onPressed, isNull);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Founder decision').first).onPressed, isNull);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/screens/boundary_review_screen.dart';

void main() {
  Widget app() => const MaterialApp(home: BoundaryReviewScreen());

  testWidgets('labels the screen as a UI preview with no live records', (tester) async {
    await tester.pumpWidget(app());

    expect(find.text('Boundary Review'), findsOneWidget);
    expect(find.textContaining('not connected to live records'), findsOneWidget);
    expect(find.textContaining('example rows are mock data'), findsOneWidget);
  });

  testWidgets('shows readable review status and revision/boundary details', (tester) async {
    await tester.pumpWidget(app());

    expect(find.text('Pending review'), findsOneWidget);
    expect(find.text('Needs changes'), findsOneWidget);
    expect(find.text('Revision 1'), findsOneWidget);
    expect(find.text('Revision 2'), findsOneWidget);
    expect(find.text('Not verified'), findsOneWidget);
    expect(find.text('Hash changed'), findsOneWidget);
  });

  testWidgets('review and decision actions are disabled in prototype', (tester) async {
    await tester.pumpWidget(app());

    expect(find.widgetWithText(OutlinedButton, 'Review evidence'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Request changes'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Founder decision'), findsOneWidget);
    expect(tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Review evidence')).onPressed, isNull);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Founder decision')).onPressed, isNull);
  });
}

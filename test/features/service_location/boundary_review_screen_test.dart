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
    expect(find.text('Boundary map preview'), findsOneWidget);
    expect(find.text('Not connected'), findsOneWidget);
    expect(find.text('Zone polygon overlay will appear here'), findsOneWidget);
    expect(find.textContaining('not proof of boundary verification'), findsOneWidget);
  });

  testWidgets('shows status, Zone ID, revision, polygon and hash evidence', (tester) async {
    await tester.pumpWidget(app());

    expect(find.text('Pending review'), findsWidgets);
    expect(find.text('Verified'), findsWidgets);
    expect(find.text('Rejected'), findsWidgets);
    expect(find.text('Needs changes'), findsWidgets);
    expect(find.text('EXAMPLE-ZONE-001'), findsOneWidget);
    expect(find.text('Not verified'), findsWidgets);
    expect(find.text('Hash changed'), findsWidgets);
    expect(find.text('EXAMPLE-SHA256-ABC123'), findsOneWidget);
    expect(find.text('Polygon verification'), findsWidgets);
  });

  testWidgets('opens Founder Approval Queue preview from Boundary Review',
      (tester) async {
    await tester.pumpWidget(app());

    await tester.tap(find.text('Preview Founder Approval Queue'));
    await tester.pumpAndSettle();

    expect(find.text('Founder Approval Queue'), findsOneWidget);
    expect(find.textContaining('No server actions enabled'), findsOneWidget);
  });

  testWidgets('review and decision actions are disabled in prototype', (tester) async {
    await tester.pumpWidget(app());

    expect(find.widgetWithText(OutlinedButton, 'Review evidence'), findsNWidgets(4));
    expect(find.widgetWithText(OutlinedButton, 'Request changes'), findsNWidgets(4));
    expect(find.widgetWithText(FilledButton, 'Founder decision'), findsNWidgets(4));
    expect(tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Review evidence').first).onPressed, isNull);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Founder decision').first).onPressed, isNull);
  });

  testWidgets('boundary review remains readable on a narrow mobile viewport',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Boundary Review'), findsOneWidget);
    expect(find.text('Zone boundary review'), findsOneWidget);
    expect(find.text('Boundary map preview'), findsOneWidget);
    expect(find.text('Required before approval'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

}

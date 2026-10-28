import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/screens/zone_directory_screen.dart';

void main() {
  group('ZoneDirectoryScreen UI prototype', () {
    testWidgets('shows example records with readiness and audit metadata',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ZoneDirectoryScreen()),
      );

      expect(find.text('Zone Directory'), findsOneWidget);
      expect(find.textContaining('not connected to Firestore'), findsOneWidget);
      expect(find.text('ZONE-EX-001'), findsOneWidget);
      expect(find.text('Parent path'), findsWidgets);
      expect(find.text('Boundary status'), findsWidgets);
      expect(find.text('Readiness blockers'), findsWidgets);
      expect(find.text('Last updated'), findsWidgets);
      expect(find.text('Updated by'), findsWidgets);
      expect(find.text('Lifecycle actions disabled'), findsWidgets);
    });

    testWidgets('search and status filters narrow the example directory',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ZoneDirectoryScreen()),
      );

      await tester.enterText(find.byType(TextField).first, 'ZONE-EX-002');
      await tester.pumpAndSettle();

      expect(find.text('Example Zone B'), findsOneWidget);
      expect(find.text('Example Zone A'), findsNothing);
      expect(find.text('Example Zone C'), findsNothing);

      await tester.enterText(find.byType(TextField).first, '');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Needs changes'));
      await tester.pumpAndSettle();

      expect(find.text('Example Zone B'), findsOneWidget);
      expect(find.text('Example Zone A'), findsNothing);
      expect(find.text('Example Zone C'), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Suspended'));
      await tester.pumpAndSettle();
      expect(find.text('Example Zone F'), findsOneWidget);
      expect(find.text('Example Zone B'), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Deactivated'));
      await tester.pumpAndSettle();
      expect(find.text('Example Zone G'), findsOneWidget);
      expect(find.text('Example Zone F'), findsNothing);
    });

    testWidgets('clear search restores examples and lifecycle controls stay disabled',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ZoneDirectoryScreen()),
      );

      final search = find.byType(TextField).first;
      await tester.enterText(search, 'does-not-exist');
      await tester.pumpAndSettle();

      expect(find.textContaining('No example zones match'), findsOneWidget);
      expect(find.text('Example Zone A'), findsNothing);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();

      expect(find.text('Example Zone A'), findsOneWidget);
      expect(find.textContaining('No example zones match'), findsNothing);

      final lifecycleButtons = tester.widgetList<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Lifecycle actions disabled'),
      );
      expect(lifecycleButtons, isNotEmpty);
      expect(
        lifecycleButtons.every((button) => button.onPressed == null),
        isTrue,
      );
    });

    testWidgets('opens Zone Details with hierarchy and readiness metadata',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ZoneDirectoryScreen()),
      );

      final detailsButton = find.text('View details').first;
      await tester.scrollUntilVisible(
        detailsButton,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(detailsButton);
      await tester.pumpAndSettle();

      expect(find.text('Zone Details'), findsOneWidget);
      expect(find.text('ZONE-EX-001 · Revision 1'), findsOneWidget);
      expect(find.text('Parent path'), findsOneWidget);
      expect(find.text('Readiness blockers'), findsOneWidget);
      expect(find.textContaining('not connected to the Zone service'), findsOneWidget);
    });

    testWidgets('directory routes to boundary review preview',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ZoneDirectoryScreen()),
      );

      final previewButton = find.text('View boundary preview').first;
      await tester.scrollUntilVisible(
        previewButton,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(previewButton);
      await tester.pumpAndSettle();

      expect(find.text('Boundary Review'), findsOneWidget);
      expect(find.text('Boundary map preview'), findsOneWidget);
    });
  });
}

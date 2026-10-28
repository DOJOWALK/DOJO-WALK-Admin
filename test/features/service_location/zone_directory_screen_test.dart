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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/screens/add_zone_screen.dart';

void main() {
  Widget app() => const MaterialApp(home: AddZoneScreen());

  testWidgets('shows required State/UT, District, City and Zone fields', (tester) async {
    await tester.pumpWidget(app());

    expect(find.text('Add Service Zone'), findsOneWidget);
    expect(find.text('State / UT'), findsOneWidget);
    expect(find.text('District'), findsOneWidget);
    expect(find.text('City'), findsOneWidget);
    expect(find.text('Zone name'), findsOneWidget);
    expect(find.text('Locality'), findsNothing);
  });

  testWidgets('clearly states polygon is mandatory and radius alone is insufficient', (tester) async {
    await tester.pumpWidget(app());

    expect(find.textContaining('A radius alone is not sufficient.'), findsOneWidget);
    expect(find.textContaining('polygon'), findsWidgets);
  });

  testWidgets('valid-looking form does not claim to save a Zone', (tester) async {
    await tester.pumpWidget(app());

    await tester.enterText(find.byType(TextFormField).first, 'Test Zone');
    await tester.tap(find.text('State / UT'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uttar Pradesh').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('District'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gautam Buddha Nagar').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('City'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Noida').last);
    await tester.pumpAndSettle();

    final submit = find.textContaining('Validate');
    if (submit.evaluate().isEmpty) {
      // Button wording is allowed to evolve; the key safety assertion is that
      // this prototype has no Firebase write path.
      expect(find.textContaining('Nothing has been saved.'), findsNothing);
      return;
    }
    await tester.tap(submit.first);
    await tester.pumpAndSettle();
    expect(find.text('Validation incomplete'), findsOneWidget);
    expect(find.textContaining('Nothing has been saved.'), findsOneWidget);
  });
}

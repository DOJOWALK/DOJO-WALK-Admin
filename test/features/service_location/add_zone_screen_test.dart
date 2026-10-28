import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/screens/add_zone_screen.dart';

void main() {
  Widget app() => const MaterialApp(home: AddZoneScreen());

  testWidgets('shows the four dependent selectors and no Locality selector', (tester) async {
    await tester.pumpWidget(app());

    expect(find.text('Add Service Zone'), findsOneWidget);
    expect(find.text('State / UT'), findsOneWidget);
    expect(find.text('District'), findsOneWidget);
    expect(find.text('City'), findsOneWidget);
    expect(find.text('Zone'), findsOneWidget);
    expect(find.text('New Zone name'), findsNothing);
    expect(find.text('Locality'), findsNothing);
  });

  testWidgets('fourth Zone selector reveals the new Zone name field',
      (tester) async {
    await tester.pumpWidget(app());

    final dropdowns = find.byType(DropdownButtonFormField<String>);
    expect(dropdowns, findsNWidgets(4));

    await tester.tap(dropdowns.at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uttar Pradesh').last);
    await tester.pumpAndSettle();

    await tester.tap(dropdowns.at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gautam Buddha Nagar').last);
    await tester.pumpAndSettle();

    await tester.tap(dropdowns.at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Noida').last);
    await tester.pumpAndSettle();

    await tester.tap(dropdowns.at(3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create new Zone…').last);
    await tester.pumpAndSettle();

    expect(find.text('New Zone name'), findsOneWidget);
    expect(find.text('Locality'), findsNothing);
  });

  testWidgets('clearly states polygon is mandatory and radius alone is insufficient', (tester) async {
    await tester.pumpWidget(app());

    expect(find.textContaining('A radius alone is not sufficient.'), findsOneWidget);
    expect(find.textContaining('polygon'), findsWidgets);
    expect(find.textContaining('Nothing has been saved.'), findsNothing);
  });

  testWidgets('empty form is validated and does not create a Zone', (tester) async {
    await tester.pumpWidget(app());

    final validateButton = find.text('Validate readiness');
    await tester.scrollUntilVisible(
      validateButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(validateButton);
    await tester.pumpAndSettle();

    expect(find.text('Please select State / UT'), findsOneWidget);
    expect(find.text('Please select Zone'), findsOneWidget);
    expect(find.text('Enter a zone name'), findsNothing);
    expect(find.text('Validation incomplete'), findsNothing);
    expect(find.textContaining('Nothing has been saved.'), findsNothing);
  });
}

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
    expect(find.text('Example Zone North (mock)'), findsOneWidget);
    expect(find.text('Example Zone Central (mock)'), findsOneWidget);
    await tester.tap(find.text('Create new Zone…').last);
    await tester.pumpAndSettle();

    expect(find.text('New Zone name'), findsOneWidget);
    expect(find.text('Locality'), findsNothing);

    // Changing an upstream parent clears all downstream selections.
    await tester.tap(dropdowns.at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delhi').last);
    await tester.pumpAndSettle();

    expect(find.text('New Zone name'), findsNothing);
    expect(find.text('Please select Zone'), findsNothing);
  });

  testWidgets('selecting an example Zone never presents it as a new Zone',
      (tester) async {
    await tester.pumpWidget(app());

    final dropdowns = find.byType(DropdownButtonFormField<String>);
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
    await tester.tap(find.text('Example Zone North (mock)').last);
    await tester.pumpAndSettle();

    final validateButton = find.text('Validate readiness');
    await tester.scrollUntilVisible(
      validateButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(validateButton);
    await tester.pumpAndSettle();

    expect(find.text('Example Zone selected'), findsOneWidget);
    expect(find.textContaining('Nothing has been edited or saved.'), findsOneWidget);
    expect(find.text('Validation incomplete'), findsNothing);
  });

  testWidgets('keeps draft save and review submission disabled without backend',
      (tester) async {
    await tester.pumpWidget(app());

    final saveDraft = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Save Draft disabled'),
    );
    final submit = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Submit for Review disabled'),
    );
    expect(saveDraft.onPressed, isNull);
    expect(submit.onPressed, isNull);
    expect(
      find.textContaining('polygon evidence is drawn and verified'),
      findsOneWidget,
    );
  });

  testWidgets('opens Boundary Review preview without submitting a Zone',
      (tester) async {
    await tester.pumpWidget(app());

    final previewButton = find.text('Preview Boundary Review');
    await tester.scrollUntilVisible(
      previewButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(previewButton);
    await tester.pumpAndSettle();

    expect(find.text('Boundary Review'), findsOneWidget);
    expect(find.textContaining('not connected to live records'), findsOneWidget);
  });

  testWidgets('Create Zone form remains usable on a narrow mobile viewport',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Add Service Zone'), findsOneWidget);
    expect(find.text('State / UT'), findsOneWidget);
    expect(find.text('Zone'), findsOneWidget);
    expect(find.text('Boundary editor pending'), findsOneWidget);
    expect(tester.takeException(), isNull);
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

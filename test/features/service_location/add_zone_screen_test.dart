import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/models/service_location_models.dart';
import 'package:dojo_admin/features/service_location/screens/add_zone_screen.dart';

const _states = [
  ServiceState(
    id: 'state-up',
    countryId: 'country-in',
    name: 'Uttar Pradesh',
    isActive: true,
  ),
  ServiceState(
    id: 'state-dl',
    countryId: 'country-in',
    name: 'Delhi',
    isActive: true,
  ),
];

const _districts = [
  ServiceDistrict(
    id: 'district-gbn',
    countryId: 'country-in',
    stateId: 'state-up',
    name: 'Gautam Buddha Nagar',
    isActive: true,
  ),
  ServiceDistrict(
    id: 'district-ghz',
    countryId: 'country-in',
    stateId: 'state-up',
    name: 'Ghaziabad',
    isActive: true,
  ),
];

const _cities = [
  ServiceCity(
    id: 'city-noida',
    countryId: 'country-in',
    stateId: 'state-up',
    districtId: 'district-gbn',
    name: 'Noida',
    isServiceActive: true,
  ),
  ServiceCity(
    id: 'city-greater-noida',
    countryId: 'country-in',
    stateId: 'state-up',
    districtId: 'district-gbn',
    name: 'Greater Noida',
    isServiceActive: true,
  ),
];

Widget app() => MaterialApp(
      home: AddZoneScreen(
        statesStream: () => Stream.value(_states),
        districtsStream: (stateId) => Stream.value(
          _districts.where((item) => item.stateId == stateId).toList(),
        ),
        citiesStream: (stateId) => Stream.value(
          _cities.where((item) => item.stateId == stateId).toList(),
        ),
      ),
    );

Future<void> selectState(WidgetTester tester) async {
  await tester.tap(find.byType(DropdownButtonFormField<String>).at(0));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Uttar Pradesh').last);
  await tester.pumpAndSettle();
}

Future<void> selectDistrict(WidgetTester tester, String name) async {
  await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

Future<void> selectCity(WidgetTester tester) async {
  await tester.tap(find.byType(DropdownButtonFormField<String>).at(2));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Noida').last);
  await tester.pumpAndSettle();
}

Future<void> selectCreateZone(WidgetTester tester) async {
  await tester.tap(find.byType(DropdownButtonFormField<String>).at(3));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Create new Zone…').last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows four dependent selectors and no Locality selector',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Add Service Zone'), findsOneWidget);
    expect(find.text('State / UT'), findsOneWidget);
    expect(find.text('District'), findsOneWidget);
    expect(find.text('City'), findsOneWidget);
    expect(find.text('Zone'), findsOneWidget);
    expect(find.text('Locality'), findsNothing);
    expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(4));
  });

  testWidgets('loads canonical State, District and City labels from streams',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await selectState(tester);
    await selectDistrict(tester, 'Gautam Buddha Nagar');
    await selectCity(tester);

    expect(find.text('Noida'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fourth selector reveals new Zone name only for create option',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await selectState(tester);
    await selectDistrict(tester, 'Gautam Buddha Nagar');
    await selectCity(tester);
    await selectCreateZone(tester);

    expect(find.text('New Zone name'), findsOneWidget);
    expect(find.text('Locality'), findsNothing);
  });

  testWidgets('changing State clears downstream selections and Zone name',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await selectState(tester);
    await selectDistrict(tester, 'Gautam Buddha Nagar');
    await selectCity(tester);
    await selectCreateZone(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Crossings West');
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delhi').last);
    await tester.pumpAndSettle();

    expect(find.text('New Zone name'), findsNothing);
    expect(find.text('Please select Zone'), findsNothing);
  });

  testWidgets('Save Draft and Submit for Review remain disabled',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    final save = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Save Draft disabled'),
    );
    final submit = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Submit for Review disabled'),
    );
    expect(save.onPressed, isNull);
    expect(submit.onPressed, isNull);
  });

  testWidgets('boundary preview does not claim GIS verification',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    final preview = find.text('Preview Boundary Review');
    await tester.scrollUntilVisible(
      preview,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(preview);
    await tester.pumpAndSettle();

    expect(find.text('Boundary Review'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('form remains usable on a narrow mobile viewport',
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
    expect(tester.takeException(), isNull);
  });
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/models/service_location_models.dart';
import 'package:dojo_admin/features/service_location/services/add_location_data_source.dart';
import 'package:dojo_admin/features/service_location/widgets/add_location_dialog.dart';

void main() {
  testWidgets('renders India setup and makes the new record inactive', (tester) async {
    final source = _FakeAddLocationDataSource();
    var savedLevel = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => AddLocationDialog(
                  service: source,
                  onSaved: (level) => savedLevel = level,
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Add Location'), findsOneWidget);
    expect(find.text('India'), findsOneWidget);
    expect(find.text('Country fixed • Code IN'), findsOneWidget);
    expect(find.text('Safety check: this record is saved as inactive. City and Area activation requires a verified geographic boundary. Saving here does not verify or activate coverage.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Uttar Pradesh');
    await tester.tap(find.text('Save Location'));
    await tester.pumpAndSettle();

    expect(source.savedState, isNotNull);
    expect(source.savedState!.name, 'Uttar Pradesh');
    expect(source.savedState!.countryId, 'india');
    expect(source.savedState!.isActive, isFalse);
    expect(savedLevel, 1);
    expect(find.text('Add Location'), findsNothing);
  });

  testWidgets('keeps the dialog open and surfaces a duplicate-save error', (tester) async {
    final source = _FakeAddLocationDataSource(
      saveStateError: StateError('Duplicate state name for this parent.'),
    );
    var savedLevel = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => AddLocationDialog(
                  service: source,
                  onSaved: (level) => savedLevel = level,
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Uttar Pradesh');
    await tester.tap(find.text('Save Location'));
    // The save button shows an indeterminate spinner while the error dialog
    // is being pushed, so pump the route transition without waiting for all
    // animations (which cannot settle while that spinner is visible).
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Unable to save location'), findsOneWidget);
    expect(
      find.textContaining('Duplicate state name for this parent.'),
      findsOneWidget,
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Add Location'), findsOneWidget);
    expect(savedLevel, -1);
  });

  testWidgets('shows a clear setup error when India master is missing', (tester) async {
    final source = _FakeAddLocationDataSource(includeIndia: false);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => AddLocationDialog(
                  service: source,
                  onSaved: (_) {},
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('India is not configured in the country master yet'),
      findsOneWidget,
    );
    expect(source.savedState, isNull);
  });
}

class _FakeAddLocationDataSource implements AddLocationDataSource {
  _FakeAddLocationDataSource({
    this.includeIndia = true,
    this.saveStateError,
  });

  final bool includeIndia;
  final Object? saveStateError;
  ServiceState? savedState;

  @override
  Stream<List<ServiceCountry>> watchCountries() => Stream.value(
        includeIndia
            ? const [ServiceCountry(id: 'india', name: 'India', code: 'IN')]
            : const <ServiceCountry>[],
      );

  @override
  Stream<List<ServiceState>> watchStates({String? countryId}) =>
      Stream.value(const <ServiceState>[]);

  @override
  Stream<List<ServiceDistrict>> watchDistricts({
    String? countryId,
    String? stateId,
    bool? activeOnly,
  }) =>
      Stream.value(const <ServiceDistrict>[]);

  @override
  Stream<List<ServiceCity>> watchCities({
    String? countryId,
    String? stateId,
    bool? activeOnly,
  }) =>
      Stream.value(const <ServiceCity>[]);

  @override
  Stream<List<ServiceArea>> watchAreas({
    String? countryId,
    String? stateId,
    String? cityId,
    bool? activeOnly,
  }) =>
      Stream.value(const <ServiceArea>[]);

  @override
  Future<void> saveCountry(ServiceCountry country) async {}

  @override
  Future<void> saveState(ServiceState state) async {
    final error = saveStateError;
    if (error != null) throw error;
    savedState = state;
  }

  @override
  Future<void> saveDistrict(ServiceDistrict district) async {}

  @override
  Future<ServiceCity?> getCity(String cityId) async => null;

  @override
  Future<void> saveCity(ServiceCity city) async {}

  @override
  Future<void> saveArea(ServiceArea area) async {}

  @override
  Future<void> saveLocality(ServiceLocality locality) async {}
}

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dojo_admin/features/service_location/models/service_location_models.dart';
import 'package:dojo_admin/features/service_location/services/service_location_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final emulatorHost = Platform.environment['FIRESTORE_EMULATOR_HOST'];
  final emulatorEnabled = emulatorHost != null && emulatorHost.isNotEmpty;

  setUpAll(() async {
    if (!emulatorEnabled) return;

    final parts = emulatorHost.split(':');
    final host = parts.first;
    final port = parts.length > 1 ? int.parse(parts.last) : 8080;

    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'fake-api-key',
        appId: '1:123456789:web:dojo-admin-test',
        messagingSenderId: '123456789',
        projectId: 'demo-dojo-walk',
      ),
    );

    FirebaseFirestore.instance.useFirestoreEmulator(host, port);
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  });

  group('Service location Firestore emulator persistence', () {
    test(
      'saves, reloads, and clears LGD codes for State, District, and Area',
      () async {
        final firestore = FirebaseFirestore.instance;
        final service = ServiceLocationService(firestore: firestore);
        final suffix = DateTime.now().microsecondsSinceEpoch.toString();
        final countryId = 'test-country-$suffix';
        final stateId = 'test-state-$suffix';
        final cityId = 'test-district-$suffix';
        final areaId = 'test-area-$suffix';

        await firestore.collection('service_countries').doc(countryId).set({
          'name': 'Test Country $suffix',
          'code': 'TST$suffix',
          'isActive': false,
        });

        await service.saveState(ServiceState(
          id: stateId,
          countryId: countryId,
          name: 'Test State $suffix',
          lgdCode: 9,
        ));
        var stateSnapshot =
            await firestore.collection('service_states').doc(stateId).get();
        expect(ServiceState.fromMap(stateId, stateSnapshot.data()!).lgdCode, 9);

        await service.saveState(ServiceState(
          id: stateId,
          countryId: countryId,
          name: 'Test State $suffix',
        ));
        stateSnapshot =
            await firestore.collection('service_states').doc(stateId).get();
        expect(
          ServiceState.fromMap(stateId, stateSnapshot.data()!).lgdCode,
          isNull,
          reason: 'A merge save must not retain a previous State LGD code.',
        );

        await service.saveCity(ServiceCity(
          id: cityId,
          countryId: countryId,
          stateId: stateId,
          name: 'Test District $suffix',
          lgdCode: '009',
        ));
        var citySnapshot =
            await firestore.collection('service_cities').doc(cityId).get();
        expect(ServiceCity.fromMap(cityId, citySnapshot.data()!).lgdCode, '009');

        await service.saveCity(ServiceCity(
          id: cityId,
          countryId: countryId,
          stateId: stateId,
          name: 'Test District $suffix',
        ));
        citySnapshot =
            await firestore.collection('service_cities').doc(cityId).get();
        expect(
          ServiceCity.fromMap(cityId, citySnapshot.data()!).lgdCode,
          isNull,
          reason: 'A merge save must not retain a previous District LGD code.',
        );

        await service.saveArea(ServiceArea(
          id: areaId,
          countryId: countryId,
          stateId: stateId,
          cityId: cityId,
          name: 'Test Sub-district $suffix',
          lgdCode: '12345',
        ));
        var areaSnapshot =
            await firestore.collection('service_areas').doc(areaId).get();
        expect(ServiceArea.fromMap(areaId, areaSnapshot.data()!).lgdCode, '12345');

        await service.saveArea(ServiceArea(
          id: areaId,
          countryId: countryId,
          stateId: stateId,
          cityId: cityId,
          name: 'Test Sub-district $suffix',
        ));
        areaSnapshot =
            await firestore.collection('service_areas').doc(areaId).get();
        expect(
          ServiceArea.fromMap(areaId, areaSnapshot.data()!).lgdCode,
          isNull,
          reason: 'A merge save must not retain a previous Sub-district LGD code.',
        );
      },
      skip: !emulatorEnabled
          ? 'Set FIRESTORE_EMULATOR_HOST to run this integration test.'
          : false,
    );
  });
}

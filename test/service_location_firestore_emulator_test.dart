import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dojo_admin/features/service_location/models/service_location_models.dart';
import 'package:dojo_admin/features/service_location/services/service_location_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Service location activation guards', () {
    Future<void> seedParents(
      FirebaseFirestore firestore, {
      required String suffix,
      bool countryActive = true,
      bool stateActive = true,
      bool cityActive = false,
    }) async {
      await firestore.collection('service_countries').doc('c-$suffix').set({
        'name': 'Country $suffix',
        'code': 'TST-$suffix',
        'isActive': countryActive,
      });
      await firestore.collection('service_states').doc('s-$suffix').set({
        'name': 'State $suffix',
        'countryId': 'c-$suffix',
        'isActive': stateActive,
      });
      await firestore.collection('service_cities').doc('city-$suffix').set({
        'name': 'City $suffix',
        'countryId': 'c-$suffix',
        'stateId': 's-$suffix',
        'isServiceActive': cityActive,
      });
    }

    test(
      'City activation delegates to the trusted backend without client writes',
      () async {
        final firestore = FakeFirebaseFirestore();
        String? calledType;
        String? calledId;
        final service = ServiceLocationService(
          firestore: firestore,
          activateLocation: ({
            required String locationType,
            required String locationId,
          }) async {
            calledType = locationType;
            calledId = locationId;
          },
        );
        await firestore.collection('service_cities').doc('city-test').set({
          'name': 'Test City',
          'isServiceActive': false,
        });

        await service.setCityServiceStatus(
          cityId: 'city-test',
          isActive: true,
        );

        expect(calledType, 'city');
        expect(calledId, 'city-test');
        final snapshot = await firestore.collection('service_cities')
            .doc('city-test').get();
        expect(snapshot.data()?['isServiceActive'], isFalse,
            reason: 'Client code must not activate a City directly.');
      },
    );

    test(
      'Area activation delegates to the trusted backend without client writes',
      () async {
        final firestore = FakeFirebaseFirestore();
        String? calledType;
        String? calledId;
        final service = ServiceLocationService(
          firestore: firestore,
          activateLocation: ({
            required String locationType,
            required String locationId,
          }) async {
            calledType = locationType;
            calledId = locationId;
          },
        );
        await firestore.collection('service_areas').doc('area-test').set({
          'name': 'Test Area',
          'isServiceActive': false,
        });

        await service.setAreaServiceStatus(
          areaId: 'area-test',
          isActive: true,
        );

        expect(calledType, 'area');
        expect(calledId, 'area-test');
        final snapshot = await firestore.collection('service_areas')
            .doc('area-test').get();
        expect(snapshot.data()?['isServiceActive'], isFalse,
            reason: 'Client code must not activate an Area directly.');
      },
    );

    test(
      'City activation propagates trusted backend validation failures',
      () async {
        final service = ServiceLocationService(
          firestore: FakeFirebaseFirestore(),
          activateLocation: ({
            required String locationType,
            required String locationId,
          }) async {
            throw StateError('Backend rejected activation.');
          },
        );

        await expectLater(
          service.setCityServiceStatus(cityId: 'city-rejected', isActive: true),
          throwsA(isA<StateError>()),
        );
      },
    );

    test(
      'Area activation propagates trusted backend validation failures',
      () async {
        final service = ServiceLocationService(
          firestore: FakeFirebaseFirestore(),
          activateLocation: ({
            required String locationType,
            required String locationId,
          }) async {
            throw StateError('Backend rejected activation.');
          },
        );

        await expectLater(
          service.setAreaServiceStatus(areaId: 'area-rejected', isActive: true),
          throwsA(isA<StateError>()),
        );
      },
    );

    test(
      'City activation rejects an empty ID before calling the backend',
      () async {
        var called = false;
        final service = ServiceLocationService(
          firestore: FakeFirebaseFirestore(),
          activateLocation: ({
            required String locationType,
            required String locationId,
          }) async {
            called = true;
          },
        );

        await expectLater(
          service.setCityServiceStatus(cityId: '  ', isActive: true),
          throwsA(isA<ArgumentError>()),
        );
        expect(called, isFalse);
      },
    );

    test(
      'Locality can activate without its own polygon when its parent Area is active',
      () async {
        final firestore = FakeFirebaseFirestore();
        var delegated = false;
        final service = ServiceLocationService(
          firestore: firestore,
          changeLocationStatus: ({
            required String locationType,
            required String locationId,
            required bool isActive,
          }) async {
            delegated = true;
            expect(locationType, 'locality');
            expect(locationId, startsWith('locality-'));
            expect(isActive, isTrue);
            await firestore.collection('service_localities').doc(locationId).update({
              'isServiceActive': isActive,
            });
          },
        );
        final suffix = DateTime.now().microsecondsSinceEpoch.toString();
        await seedParents(firestore, suffix: suffix, cityActive: true);
        await firestore.collection('service_areas').doc('area-$suffix').set({
          'name': 'Area $suffix',
          'countryId': 'c-$suffix',
          'stateId': 's-$suffix',
          'cityId': 'city-$suffix',
          'isServiceActive': true,
        });
        await firestore.collection('service_localities').doc('locality-$suffix').set({
          'name': 'Locality $suffix',
          'countryId': 'c-$suffix',
          'stateId': 's-$suffix',
          'cityId': 'city-$suffix',
          'areaId': 'area-$suffix',
          'isServiceActive': false,
        });

        await service.setLocalityServiceStatus(
          localityId: 'locality-$suffix',
          isActive: true,
        );

        final snapshot = await firestore.collection('service_localities')
            .doc('locality-$suffix').get();
        expect(snapshot.data()?['isServiceActive'], isTrue);
        expect(delegated, isTrue, reason: 'Locality status must delegate to the trusted backend.');
      },
    );

    test(
      'Locality activation is rejected when parent Area is inactive',
      () async {
        final firestore = FakeFirebaseFirestore();
        final service = ServiceLocationService(
          firestore: firestore,
          changeLocationStatus: ({
            required String locationType,
            required String locationId,
            required bool isActive,
          }) async {
            throw StateError('Backend rejected Locality activation because parent Area is inactive.');
          },
        );
        final suffix = DateTime.now().microsecondsSinceEpoch.toString();
        await seedParents(firestore, suffix: suffix, cityActive: true);
        await firestore.collection('service_areas').doc('area-$suffix').set({
          'name': 'Area $suffix',
          'countryId': 'c-$suffix',
          'stateId': 's-$suffix',
          'cityId': 'city-$suffix',
          'isServiceActive': false,
        });
        await firestore.collection('service_localities').doc('locality-$suffix').set({
          'name': 'Locality $suffix',
          'countryId': 'c-$suffix',
          'stateId': 's-$suffix',
          'cityId': 'city-$suffix',
          'areaId': 'area-$suffix',
          'isServiceActive': false,
        });

        await expectLater(
          service.setLocalityServiceStatus(
            localityId: 'locality-$suffix',
            isActive: true,
          ),
          throwsA(isA<StateError>()),
        );
        final snapshot = await firestore.collection('service_localities')
            .doc('locality-$suffix').get();
        expect(snapshot.data()?['isServiceActive'], isFalse);
      },
    );


  });

  group('Service location Firestore service persistence', () {
    test(
      'saves, reloads, and clears LGD codes for State, District, and Area',
      () async {
        final firestore = FakeFirebaseFirestore();
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
    );
  });
}

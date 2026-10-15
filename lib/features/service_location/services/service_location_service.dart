import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/service_location_models.dart';

class ServiceLocationService {
  ServiceLocationService({
    FirebaseFirestore? firestore,
  }) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // =========================================================
  // COLLECTIONS
  // =========================================================

  CollectionReference<Map<String, dynamic>> get _countries =>
      _db.collection('service_countries');

  CollectionReference<Map<String, dynamic>> get _states =>
      _db.collection('service_states');

  CollectionReference<Map<String, dynamic>> get _cities =>
      _db.collection('service_cities');

  CollectionReference<Map<String, dynamic>> get _areas =>
      _db.collection('service_areas');

  CollectionReference<Map<String, dynamic>> get _localities =>
      _db.collection('service_localities');

  CollectionReference<Map<String, dynamic>> get _imports =>
      _db.collection('service_location_imports');

  // =========================================================
  // COMMON VALIDATION
  // =========================================================

  void _validateName(String name, String label) {
    if (name.trim().isEmpty) {
      throw ArgumentError('$label is required.');
    }
  }

  void _validateBoundary({
    required List<GeoPoint> boundary,
    required bool boundaryVerified,
    required String boundarySource,
    required bool isServiceActive,
  }) {
    if (!isServiceActive) return;

    if (!boundaryVerified) {
      throw StateError(
        'Verify the geographic boundary before activating service.',
      );
    }

    if (boundary.length < 3) {
      throw StateError(
        'A verified boundary with at least 3 points is required.',
      );
    }

    if (boundarySource.trim().isEmpty) {
      throw StateError(
        'Boundary source is required before activation.',
      );
    }

    for (final point in boundary) {
      if (point.latitude < -90 ||
          point.latitude > 90 ||
          point.longitude < -180 ||
          point.longitude > 180) {
        throw StateError('Boundary contains invalid coordinates.');
      }
    }
  }

  Future<Map<String, dynamic>> _requireDocument(
    CollectionReference<Map<String, dynamic>> collection,
    String id,
    String label,
  ) async {
    if (id.trim().isEmpty) {
      throw ArgumentError('$label must be selected.');
    }

    final doc = await collection.doc(id).get();

    if (!doc.exists || doc.data() == null) {
      throw StateError('Selected $label does not exist.');
    }

    return doc.data()!;
  }

  Future<void> _requireActiveParent(
    CollectionReference<Map<String, dynamic>> collection,
    String id,
    String label,
  ) async {
    final data = await _requireDocument(collection, id, label);

    if (data['isActive'] != true &&
        data['isServiceActive'] != true) {
      throw StateError('Activate the parent $label first.');
    }
  }

  // =========================================================
  // COUNTRIES
  // =========================================================

  Stream<List<ServiceCountry>> watchCountries() {
    return _countries.orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ServiceCountry.fromMap(
                  doc.id,
                  doc.data(),
                ),
              )
              .toList(),
        );
  }

  Future<String> saveCountry(ServiceCountry country) async {
    _validateName(country.name, 'Country name');
    _validateName(country.code, 'Country code');

    final isNew = country.id.trim().isEmpty;
    final doc = isNew ? _countries.doc() : _countries.doc(country.id);

    await doc.set(
      country.toMap(includeCreatedAt: isNew),
      SetOptions(merge: true),
    );

    return doc.id;
  }

  Future<void> setCountryStatus({
    required String countryId,
    required bool isActive,
  }) async {
    await _requireDocument(_countries, countryId, 'country');

    if (!isActive) {
      final states = await _states
          .where('countryId', isEqualTo: countryId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (states.docs.isNotEmpty) {
        throw StateError(
          'Deactivate active child states before deactivating this country.',
        );
      }
    }

    await _countries.doc(countryId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // =========================================================
  // STATES
  // =========================================================

  Stream<List<ServiceState>> watchStates(String countryId) {
    return _states
        .where('countryId', isEqualTo: countryId)
        .snapshots()
        .map((snapshot) {
          final result = snapshot.docs
              .map(
                (doc) => ServiceState.fromMap(
                  doc.id,
                  doc.data(),
                ),
              )
              .toList();

          result.sort(
            (a, b) => a.name.toLowerCase().compareTo(
                  b.name.toLowerCase(),
                ),
          );

          return result;
        });
  }

  Future<String> saveState(ServiceState state) async {
    _validateName(state.name, 'State name');

    await _requireDocument(
      _countries,
      state.countryId,
      'country',
    );

    final isNew = state.id.trim().isEmpty;
    final doc = isNew ? _states.doc() : _states.doc(state.id);

    await doc.set(
      state.toMap(includeCreatedAt: isNew),
      SetOptions(merge: true),
    );

    return doc.id;
  }

  Future<void> setStateStatus({
    required String stateId,
    required bool isActive,
  }) async {
    final data = await _requireDocument(
      _states,
      stateId,
      'state',
    );

    if (isActive) {
      final country = await _requireDocument(
        _countries,
        data['countryId']?.toString() ?? '',
        'country',
      );

      if (country['isActive'] != true) {
        throw StateError('Activate the parent country first.');
      }
    }

    await _states.doc(stateId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // =========================================================
  // CITIES / DISTRICTS
  // =========================================================

  Stream<List<ServiceCity>> watchCities({
    String? countryId,
    String? stateId,
  }) {
    Query<Map<String, dynamic>> query = _cities;

    if (countryId != null && countryId.trim().isNotEmpty) {
      query = query.where('countryId', isEqualTo: countryId);
    }

    if (stateId != null && stateId.trim().isNotEmpty) {
      query = query.where('stateId', isEqualTo: stateId);
    }

    return query.snapshots().map((snapshot) {
      final result = snapshot.docs
          .map(
            (doc) => ServiceCity.fromMap(
              doc.id,
              doc.data(),
            ),
          )
          .toList();

      result.sort(
        (a, b) => a.name.toLowerCase().compareTo(
              b.name.toLowerCase(),
            ),
      );

      return result;
    });
  }

  Future<ServiceCity?> getCity(String cityId) async {
    final doc = await _cities.doc(cityId).get();

    if (!doc.exists || doc.data() == null) return null;

    return ServiceCity.fromMap(doc.id, doc.data()!);
  }

  Future<String> saveCity(ServiceCity city) async {
    _validateName(city.name, 'City/District name');

    final country = await _requireDocument(
      _countries,
      city.countryId,
      'country',
    );

    final state = await _requireDocument(
      _states,
      city.stateId,
      'state',
    );

    if (state['countryId'] != city.countryId) {
      throw StateError('Selected state does not belong to this country.');
    }

    if (city.isServiceActive) {
      if (country['isActive'] != true || state['isActive'] != true) {
        throw StateError(
          'The country and state must be active before activating this city.',
        );
      }
    }

    _validateBoundary(
      boundary: city.boundary,
      boundaryVerified: city.boundaryVerified,
      boundarySource: city.boundarySource,
      isServiceActive: city.isServiceActive,
    );

    final isNew = city.id.trim().isEmpty;
    final doc = isNew ? _cities.doc() : _cities.doc(city.id);

    await doc.set(
      city.toMap(includeCreatedAt: isNew),
      SetOptions(merge: true),
    );

    return doc.id;
  }

  // =========================================================
  // AREAS / SUB-DISTRICTS
  // =========================================================

  Stream<List<ServiceArea>> watchAreas(String cityId) {
    return _areas
        .where('cityId', isEqualTo: cityId)
        .snapshots()
        .map((snapshot) {
          final result = snapshot.docs
              .map(
                (doc) => ServiceArea.fromMap(
                  doc.id,
                  doc.data(),
                ),
              )
              .toList();

          result.sort(
            (a, b) => a.name.toLowerCase().compareTo(
                  b.name.toLowerCase(),
                ),
          );

          return result;
        });
  }

  Future<String> saveArea(ServiceArea area) async {
    _validateName(area.name, 'Area/Sub-district name');

    final city = await getCity(area.cityId);

    if (city == null) {
      throw StateError('The selected city/district does not exist.');
    }

    if (area.countryId != city.countryId ||
        area.stateId != city.stateId) {
      throw StateError(
        'Area country/state must match its parent city/district.',
      );
    }

    if (area.isServiceActive && !city.isServiceActive) {
      throw StateError(
        'Activate the parent city/district before activating this area.',
      );
    }

    _validateBoundary(
      boundary: area.boundary,
      boundaryVerified: area.boundaryVerified,
      boundarySource: area.boundarySource,
      isServiceActive: area.isServiceActive,
    );

    final isNew = area.id.trim().isEmpty;
    final doc = isNew ? _areas.doc() : _areas.doc(area.id);

    await doc.set(
      area.toMap(includeCreatedAt: isNew),
      SetOptions(merge: true),
    );

    return doc.id;
  }

  // =========================================================
  // LOCALITIES / VILLAGES
  // =========================================================

  Stream<List<ServiceLocality>> watchLocalities({
    required String cityId,
    required String areaId,
  }) {
    return _localities
        .where('cityId', isEqualTo: cityId)
        .where('areaId', isEqualTo: areaId)
        .snapshots()
        .map((snapshot) {
          final result = snapshot.docs
              .map(
                (doc) => ServiceLocality.fromMap(
                  doc.id,
                  doc.data(),
                ),
              )
              .toList();

          result.sort(
            (a, b) => a.name.toLowerCase().compareTo(
                  b.name.toLowerCase(),
                ),
          );

          return result;
        });
  }

  Future<String> saveLocality(ServiceLocality locality) async {
    _validateName(locality.name, 'Locality/Village name');

    final city = await getCity(locality.cityId);

    if (city == null) {
      throw StateError('The selected city/district does not exist.');
    }

    final areaData = await _requireDocument(
      _areas,
      locality.areaId,
      'area',
    );

    final area = ServiceArea.fromMap(
      locality.areaId,
      areaData,
    );

    if (area.cityId != locality.cityId) {
      throw StateError('The selected area does not belong to this city.');
    }

    if (locality.countryId != city.countryId ||
        locality.stateId != city.stateId ||
        locality.countryId != area.countryId ||
        locality.stateId != area.stateId) {
      throw StateError(
        'Locality country/state must match its parent locations.',
      );
    }

    if (locality.isServiceActive &&
        (!city.isServiceActive || !area.isServiceActive)) {
      throw StateError(
        'The parent city/district and area must both be active.',
      );
    }

    _validateBoundary(
      boundary: locality.boundary,
      boundaryVerified: locality.boundaryVerified,
      boundarySource: locality.boundarySource,
      isServiceActive: locality.isServiceActive,
    );

    final isNew = locality.id.trim().isEmpty;
    final doc = isNew
        ? _localities.doc()
        : _localities.doc(locality.id);

    await doc.set(
      locality.toMap(includeCreatedAt: isNew),
      SetOptions(merge: true),
    );

    return doc.id;
  }

  // =========================================================
  // IMPORT AUDIT RECORDS
  // =========================================================

  Stream<List<ServiceLocationImport>> watchImports() {
    return _imports.orderBy(
      'importedAt',
      descending: true,
    ).snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ServiceLocationImport.fromMap(
                  doc.id,
                  doc.data(),
                ),
              )
              .toList(),
        );
  }

  Future<String> saveImport(ServiceLocationImport record) async {
    _validateName(record.source, 'Import source');
    _validateName(record.fileName, 'Import file name');
    _validateName(record.status, 'Import status');
    _validateName(record.importedBy, 'Importer');
    _validateName(
      record.verificationStatus,
      'Verification status',
    );

    final doc = _imports.doc();

    await doc.set(record.toMap());

    return doc.id;
  }

  // =========================================================
  // SERVICE STATUS HELPERS
  // =========================================================

  Future<void> setCityServiceStatus({
    required String cityId,
    required bool isActive,
  }) async {
    final city = await getCity(cityId);

    if (city == null) {
      throw StateError('City/district not found.');
    }

    if (isActive) {
      final country = await _requireDocument(
        _countries,
        city.countryId,
        'country',
      );

      final state = await _requireDocument(
        _states,
        city.stateId,
        'state',
      );

      if (country['isActive'] != true || state['isActive'] != true) {
        throw StateError(
          'Activate the parent country and state first.',
        );
      }
    }

    _validateBoundary(
      boundary: city.boundary,
      boundaryVerified: city.boundaryVerified,
      boundarySource: city.boundarySource,
      isServiceActive: isActive,
    );

    await _cities.doc(cityId).update({
      'isServiceActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setAreaServiceStatus({
    required String areaId,
    required bool isActive,
  }) async {
    final data = await _requireDocument(
      _areas,
      areaId,
      'area',
    );

    final area = ServiceArea.fromMap(areaId, data);

    if (isActive) {
      final city = await getCity(area.cityId);

      if (city == null || !city.isServiceActive) {
        throw StateError(
          'Activate the parent city/district first.',
        );
      }
    }

    _validateBoundary(
      boundary: area.boundary,
      boundaryVerified: area.boundaryVerified,
      boundarySource: area.boundarySource,
      isServiceActive: isActive,
    );

    await _areas.doc(areaId).update({
      'isServiceActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setLocalityServiceStatus({
    required String localityId,
    required bool isActive,
  }) async {
    final data = await _requireDocument(
      _localities,
      localityId,
      'locality',
    );

    final locality = ServiceLocality.fromMap(localityId, data);

    if (isActive) {
      final city = await getCity(locality.cityId);

      if (city == null || !city.isServiceActive) {
        throw StateError(
          'Activate the parent city/district first.',
        );
      }

      final areaData = await _requireDocument(
        _areas,
        locality.areaId,
        'area',
      );

      final area = ServiceArea.fromMap(
        locality.areaId,
        areaData,
      );

      if (!area.isServiceActive) {
        throw StateError('Activate the parent area first.');
      }
    }

    _validateBoundary(
      boundary: locality.boundary,
      boundaryVerified: locality.boundaryVerified,
      boundarySource: locality.boundarySource,
      isServiceActive: isActive,
    );

    await _localities.doc(localityId).update({
      'isServiceActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

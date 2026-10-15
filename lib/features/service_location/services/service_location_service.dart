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

  String _normalizeName(String name) {
    return name
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();
  }

  /// Checks whether the normalized name already exists
  /// under the selected parent.
  ///
  /// Existing document IDs are preserved.
  /// The current document is excluded during updates.
  ///
  /// Note: This query-based check does not by itself guarantee
  /// uniqueness when concurrent requests save the same name.
  Future<void> _ensureUniqueName({
    required CollectionReference<Map<String, dynamic>>
        collection,
    required String name,
    required String label,
    required List<String> parentFields,
    required List<String> parentIds,
    String? excludeId,
  }) async {
    _validateName(name, label);

    if (parentFields.length != parentIds.length) {
      throw StateError(
        'Invalid parent configuration for $label.',
      );
    }

    Query<Map<String, dynamic>> query = collection;

    for (var i = 0; i < parentFields.length; i++) {
      final parentId = parentIds[i].trim();

      if (parentId.isEmpty) {
        throw ArgumentError(
          'A valid parent must be selected for $label.',
        );
      }

      query = query.where(
        parentFields[i],
        isEqualTo: parentId,
      );
    }

    final snapshot = await query.get();
    final normalizedName = _normalizeName(name);

    for (final document in snapshot.docs) {
      if (excludeId != null &&
          excludeId.isNotEmpty &&
          document.id == excludeId) {
        continue;
      }

      final existingName =
          document.data()['name']?.toString() ?? '';

      if (_normalizeName(existingName) == normalizedName) {
        throw StateError(
          '$label "$name" already exists under the selected parent.',
        );
      }
    }
  }

  void _validateBoundary({
    required List<GeoPoint> boundary,
    required bool boundaryVerified,
    required String boundarySource,
    required bool isServiceActive,
  }) {
    for (final point in boundary) {
      if (!point.latitude.isFinite ||
          !point.longitude.isFinite ||
          point.latitude < -90 ||
          point.latitude > 90 ||
          point.longitude < -180 ||
          point.longitude > 180) {
        throw StateError(
          'Boundary contains invalid coordinates.',
        );
      }
    }

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
  }

  Future<Map<String, dynamic>> _requireDocument(
    CollectionReference<Map<String, dynamic>> collection,
    String id,
    String label,
  ) async {
    if (id.trim().isEmpty) {
      throw ArgumentError('$label must be selected.');
    }

    final snapshot = await collection.doc(id).get();

    if (!snapshot.exists || snapshot.data() == null) {
      throw StateError('Selected $label does not exist.');
    }

    return snapshot.data()!;
  }

  Future<void> _requireActiveCountry(String countryId) async {
    final country = await _requireDocument(
      _countries,
      countryId,
      'country',
    );

    if (country['isActive'] != true) {
      throw StateError('Activate the parent country first.');
    }
  }

  Future<void> _requireActiveState(String stateId) async {
    final state = await _requireDocument(
      _states,
      stateId,
      'state',
    );

    if (state['isActive'] != true) {
      throw StateError('Activate the parent state first.');
    }

    await _requireActiveCountry(
      state['countryId']?.toString() ?? '',
    );
  }

  Future<void> _requireActiveCity(String cityId) async {
    final city = await getCity(cityId);

    if (city == null || !city.isServiceActive) {
      throw StateError(
        'Activate the parent city/district first.',
      );
    }

    await _requireActiveCountry(city.countryId);
    await _requireActiveState(city.stateId);
  }

  Future<void> _requireActiveArea(String areaId) async {
    final data = await _requireDocument(
      _areas,
      areaId,
      'area',
    );

    final area = ServiceArea.fromMap(areaId, data);

    if (!area.isServiceActive) {
      throw StateError('Activate the parent area first.');
    }

    await _requireActiveCity(area.cityId);
  }

  Future<void> _requireExistingForUpdate(
    CollectionReference<Map<String, dynamic>> collection,
    String id,
    String label,
  ) async {
    if (id.trim().isEmpty) return;

    await _requireDocument(collection, id, label);
  }

  Future<bool> _hasActiveChild(
    CollectionReference<Map<String, dynamic>> collection,
    String parentField,
    String parentId,
    String statusField,
  ) async {
    final snapshot = await collection
        .where(parentField, isEqualTo: parentId)
        .where(statusField, isEqualTo: true)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<void> _ensureNoActiveChildren({
    required String parentId,
    required String parentLabel,
    required List<CollectionReference<Map<String, dynamic>>>
        collections,
    required List<String> parentFields,
    required List<String> statusFields,
  }) async {
    for (var i = 0; i < collections.length; i++) {
      final hasChildren = await _hasActiveChild(
        collections[i],
        parentFields[i],
        parentId,
        statusFields[i],
      );

      if (hasChildren) {
        throw StateError(
          'Deactivate active child locations before '
          'deactivating this $parentLabel.',
        );
      }
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

    await _ensureUniqueName(
      collection: _countries,
      name: country.name,
      label: 'Country',
      parentFields: const [],
      parentIds: const [],
      excludeId: isNew ? null : country.id,
    );

    if (!isNew) {
      await _requireExistingForUpdate(
        _countries,
        country.id,
        'country',
      );
    }

    final doc = isNew
        ? _countries.doc()
        : _countries.doc(country.id);

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
    await _requireDocument(
      _countries,
      countryId,
      'country',
    );

    if (!isActive) {
      await _ensureNoActiveChildren(
        parentId: countryId,
        parentLabel: 'country',
        collections: [
          _states,
          _cities,
          _areas,
          _localities,
        ],
        parentFields: [
          'countryId',
          'countryId',
          'countryId',
          'countryId',
        ],
        statusFields: [
          'isActive',
          'isServiceActive',
          'isServiceActive',
          'isServiceActive',
        ],
      );
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

    if (state.isActive) {
      await _requireActiveCountry(state.countryId);
    }

    final isNew = state.id.trim().isEmpty;

    await _ensureUniqueName(
      collection: _states,
      name: state.name,
      label: 'State',
      parentFields: const ['countryId'],
      parentIds: [state.countryId],
      excludeId: isNew ? null : state.id,
    );

    if (!isNew) {
      await _requireExistingForUpdate(
        _states,
        state.id,
        'state',
      );
    }

    final doc = isNew
        ? _states.doc()
        : _states.doc(state.id);

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
      await _requireActiveCountry(
        data['countryId']?.toString() ?? '',
      );
    } else {
      await _ensureNoActiveChildren(
        parentId: stateId,
        parentLabel: 'state',
        collections: [
          _cities,
          _areas,
          _localities,
        ],
        parentFields: [
          'stateId',
          'stateId',
          'stateId',
        ],
        statusFields: [
          'isServiceActive',
          'isServiceActive',
          'isServiceActive',
        ],
      );
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
      query = query.where(
        'countryId',
        isEqualTo: countryId,
      );
    }

    if (stateId != null && stateId.trim().isNotEmpty) {
      query = query.where(
        'stateId',
        isEqualTo: stateId,
      );
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

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return ServiceCity.fromMap(
      doc.id,
      doc.data()!,
    );
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
      throw StateError(
        'Selected state does not belong to this country.',
      );
    }

    if (city.isServiceActive) {
      if (country['isActive'] != true ||
          state['isActive'] != true) {
        throw StateError(
          'The country and state must be active '
          'before activating this city.',
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

    await _ensureUniqueName(
      collection: _cities,
      name: city.name,
      label: 'City/District',
      parentFields: const ['stateId'],
      parentIds: [city.stateId],
      excludeId: isNew ? null : city.id,
    );

    if (!isNew) {
      await _requireExistingForUpdate(
        _cities,
        city.id,
        'city/district',
      );
    }

    final doc = isNew
        ? _cities.doc()
        : _cities.doc(city.id);

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
      throw StateError(
        'The selected city/district does not exist.',
      );
    }

    final country = await _requireDocument(
      _countries,
      area.countryId,
      'country',
    );

    final state = await _requireDocument(
      _states,
      area.stateId,
      'state',
    );

    if (area.countryId != city.countryId ||
        area.stateId != city.stateId) {
      throw StateError(
        'Area country/state must match its parent city/district.',
      );
    }

    if (state['countryId'] != area.countryId) {
      throw StateError(
        'Selected state does not belong to this country.',
      );
    }

    if (area.isServiceActive) {
      if (country['isActive'] != true ||
          state['isActive'] != true ||
          !city.isServiceActive) {
        throw StateError(
          'Activate the parent country, state and city/district '
          'before activating this area.',
        );
      }
    }

    _validateBoundary(
      boundary: area.boundary,
      boundaryVerified: area.boundaryVerified,
      boundarySource: area.boundarySource,
      isServiceActive: area.isServiceActive,
    );

    final isNew = area.id.trim().isEmpty;

    await _ensureUniqueName(
      collection: _areas,
      name: area.name,
      label: 'Area/Sub-district',
      parentFields: const ['cityId'],
      parentIds: [area.cityId],
      excludeId: isNew ? null : area.id,
    );

    if (!isNew) {
      await _requireExistingForUpdate(
        _areas,
        area.id,
        'area',
      );
    }

    final doc = isNew
        ? _areas.doc()
        : _areas.doc(area.id);

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

  Future<String> saveLocality(
    ServiceLocality locality,
  ) async {
    _validateName(
      locality.name,
      'Locality/Village name',
    );

    final city = await getCity(locality.cityId);

    if (city == null) {
      throw StateError(
        'The selected city/district does not exist.',
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

    final country = await _requireDocument(
      _countries,
      locality.countryId,
      'country',
    );

    final state = await _requireDocument(
      _states,
      locality.stateId,
      'state',
    );

    if (area.cityId != locality.cityId) {
      throw StateError(
        'The selected area does not belong to this city.',
      );
    }

    if (locality.countryId != city.countryId ||
        locality.stateId != city.stateId ||
        locality.countryId != area.countryId ||
        locality.stateId != area.stateId ||
        state['countryId'] != locality.countryId) {
      throw StateError(
        'Locality country/state must match its parent locations.',
      );
    }

    if (locality.isServiceActive) {
      if (country['isActive'] != true ||
          state['isActive'] != true ||
          !city.isServiceActive ||
          !area.isServiceActive) {
        throw StateError(
          'Activate the parent country, state, city/district '
          'and area before activating this locality.',
        );
      }
    }

    _validateBoundary(
      boundary: locality.boundary,
      boundaryVerified: locality.boundaryVerified,
      boundarySource: locality.boundarySource,
      isServiceActive: locality.isServiceActive,
    );

    final isNew = locality.id.trim().isEmpty;

    await _ensureUniqueName(
      collection: _localities,
      name: locality.name,
      label: 'Locality/Village',
      parentFields: const ['areaId'],
      parentIds: [locality.areaId],
      excludeId: isNew ? null : locality.id,
    );

    if (!isNew) {
      await _requireExistingForUpdate(
        _localities,
        locality.id,
        'locality',
      );
    }

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
    return _imports
        .orderBy('importedAt', descending: true)
        .snapshots()
        .map(
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

  Future<String> saveImport(
    ServiceLocationImport record,
  ) async {
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
  // CITY SERVICE STATUS
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
      await _requireActiveCountry(city.countryId);
      await _requireActiveState(city.stateId);

      final state = await _requireDocument(
        _states,
        city.stateId,
        'state',
      );

      if (state['countryId'] != city.countryId) {
        throw StateError(
          'City state does not belong to its country.',
        );
      }
    } else {
      await _ensureNoActiveChildren(
        parentId: cityId,
        parentLabel: 'city/district',
        collections: [
          _areas,
          _localities,
        ],
        parentFields: [
          'cityId',
          'cityId',
        ],
        statusFields: [
          'isServiceActive',
          'isServiceActive',
        ],
      );
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

  // =========================================================
  // AREA SERVICE STATUS
  // =========================================================

  Future<void> setAreaServiceStatus({
    required String areaId,
    required bool isActive,
  }) async {
    final data = await _requireDocument(
      _areas,
      areaId,
      'area',
    );

    final area = ServiceArea.fromMap(
      areaId,
      data,
    );

    if (isActive) {
      await _requireActiveCity(area.cityId);

      final city = await getCity(area.cityId);

      if (city == null ||
          city.countryId != area.countryId ||
          city.stateId != area.stateId) {
        throw StateError(
          'Area country/state must match its parent city/district.',
        );
      }
    } else {
      await _ensureNoActiveChildren(
        parentId: areaId,
        parentLabel: 'area',
        collections: [_localities],
        parentFields: ['areaId'],
        statusFields: ['isServiceActive'],
      );
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

  // =========================================================
  // LOCALITY SERVICE STATUS
  // =========================================================

  Future<void> setLocalityServiceStatus({
    required String localityId,
    required bool isActive,
  }) async {
    final data = await _requireDocument(
      _localities,
      localityId,
      'locality',
    );

    final locality = ServiceLocality.fromMap(
      localityId,
      data,
    );

    if (isActive) {
      await _requireActiveCity(locality.cityId);
      await _requireActiveArea(locality.areaId);

      final city = await getCity(locality.cityId);

      final areaData = await _requireDocument(
        _areas,
        locality.areaId,
        'area',
      );

      final area = ServiceArea.fromMap(
        locality.areaId,
        areaData,
      );

      if (city == null ||
          area.cityId != locality.cityId ||
          locality.countryId != city.countryId ||
          locality.stateId != city.stateId ||
          locality.countryId != area.countryId ||
          locality.stateId != area.stateId) {
        throw StateError(
          'Locality parent locations do not match.',
        );
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

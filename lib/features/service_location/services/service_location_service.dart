import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

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

  CollectionReference<Map<String, dynamic>> get _nameIndexes =>
      _db.collection('service_location_name_indexes');

  // =========================================================
  // COMMON VALIDATION
  // =========================================================

  void _validateName(String name, String label) {
    if (name.trim().isEmpty) {
      throw ArgumentError('$label is required.');
    }
  }

  String _normalizeName(String name) {
    return name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  String _makeNameIndexId({
    required String collectionPath,
    required List<String> parentIds,
    required String name,
  }) {
    final normalizedName = _normalizeName(name);

    final key = jsonEncode([
      collectionPath,
      ...parentIds,
      normalizedName,
    ]);

    return sha256.convert(utf8.encode(key)).toString();
  }

  /// Atomically reserves a normalized name and saves its document.
  ///
  /// All transaction reads happen before any transaction writes.
  /// Existing document IDs are preserved.
  ///
  /// Uniqueness scope:
  /// - Country: global.
  /// - State: within country.
  /// - City: within state.
  /// - Area: within city.
  /// - Locality: within area.
  Future<String> _saveUniqueNamedDocument({
    required CollectionReference<Map<String, dynamic>> collection,
    required String documentId,
    required String name,
    required String label,
    required List<String> parentFields,
    required List<String> parentIds,
    required Map<String, dynamic> data,
    required bool includeCreatedAt,
  }) async {
    _validateName(name, label);

    if (parentFields.length != parentIds.length) {
      throw StateError('Invalid parent configuration for $label.');
    }

    for (final parentId in parentIds) {
      if (parentId.trim().isEmpty) {
        throw ArgumentError('A valid parent must be selected for $label.');
      }
    }

    final isNew = documentId.trim().isEmpty;
    final targetRef =
        isNew ? collection.doc() : collection.doc(documentId);

    final newIndexId = _makeNameIndexId(
      collectionPath: collection.path,
      parentIds: parentIds,
      name: name,
    );

    final newIndexRef = _nameIndexes.doc(newIndexId);

    return _db.runTransaction<String>((transaction) async {
      // READ 1: existing target document.
      final targetSnapshot = await transaction.get(targetRef);

      if (!isNew && !targetSnapshot.exists) {
        throw StateError('Selected $label does not exist.');
      }

      // READ 2: index for the requested name.
      final newIndexSnapshot = await transaction.get(newIndexRef);

      // Determine the old index for an update.
      DocumentReference<Map<String, dynamic>>? oldIndexRef;
      DocumentSnapshot<Map<String, dynamic>>? oldIndexSnapshot;

      if (!isNew) {
        final oldData = targetSnapshot.data() ?? <String, dynamic>{};
        final oldName = oldData['name']?.toString() ?? '';

        final oldParentIds = <String>[];

        for (final field in parentFields) {
          oldParentIds.add(oldData[field]?.toString() ?? '');
        }

        if (oldName.trim().isNotEmpty &&
            oldParentIds.every((id) => id.trim().isNotEmpty)) {
          final oldIndexId = _makeNameIndexId(
            collectionPath: collection.path,
            parentIds: oldParentIds,
            name: oldName,
          );

          if (oldIndexId != newIndexId) {
            oldIndexRef = _nameIndexes.doc(oldIndexId);

            // READ 3: old index, if the name or parent is changing.
            oldIndexSnapshot = await transaction.get(oldIndexRef);
          }
        }
      }

      // All reads are complete. Writes begin below.
      if (newIndexSnapshot.exists) {
        final ownerId =
            newIndexSnapshot.data()?['ownerId']?.toString() ?? '';

        if (ownerId != targetRef.id) {
          throw StateError(
            '$label "$name" already exists under the selected parent.',
          );
        }
      }

      if (oldIndexRef != null && oldIndexSnapshot != null) {
        final oldOwnerId =
            oldIndexSnapshot.data()?['ownerId']?.toString() ?? '';

        if (oldIndexSnapshot.exists && oldOwnerId == targetRef.id) {
          transaction.delete(oldIndexRef);
        }
      }

      transaction.set(
        newIndexRef,
        {
          'ownerId': targetRef.id,
          'collectionName': collection.id,
          'parentIds': parentIds,
          'normalizedName': _normalizeName(name),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      final documentData = Map<String, dynamic>.from(data);

      // Ensure createdAt is retained on updates.
      if (!includeCreatedAt && targetSnapshot.exists) {
        final oldData = targetSnapshot.data();

        if (oldData != null && oldData.containsKey('createdAt')) {
          documentData['createdAt'] = oldData['createdAt'];
        }
      }

      transaction.set(
        targetRef,
        documentData,
        SetOptions(merge: true),
      );

      return targetRef.id;
    });
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
        throw StateError('Boundary contains invalid coordinates.');
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
    required List<CollectionReference<Map<String, dynamic>>> collections,
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

  /// Blocks moving a location to a different parent when it has
  /// any descendants, including inactive descendants.
  Future<void> _ensureNoChildrenForReparent({
    required String parentId,
    required String parentLabel,
    required List<CollectionReference<Map<String, dynamic>>> collections,
    required List<String> parentFields,
  }) async {
    for (var i = 0; i < collections.length; i++) {
      final snapshot = await collections[i]
          .where(parentFields[i], isEqualTo: parentId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        throw StateError(
          'Cannot change the parent of this $parentLabel because '
          'child locations already exist. Create a new location '
          'or move the children first.',
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
          .map((doc) => ServiceCountry.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  Future<String> saveCountry(ServiceCountry country) async {
    _validateName(country.name, 'Country name');
    _validateName(country.code, 'Country code');

    final isNew = country.id.trim().isEmpty;

    if (!isNew) {
      await _requireExistingForUpdate(
        _countries,
        country.id,
        'country',
      );
    }

    return _saveUniqueNamedDocument(
      collection: _countries,
      documentId: country.id,
      name: country.name,
      label: 'Country',
      parentFields: const [],
      parentIds: const [],
      data: country.toMap(includeCreatedAt: isNew),
      includeCreatedAt: isNew,
    );
  }

  Future<void> setCountryStatus({
    required String countryId,
    required bool isActive,
  }) async {
    await _requireDocument(_countries, countryId, 'country');

    if (!isActive) {
      await _ensureNoActiveChildren(
        parentId: countryId,
        parentLabel: 'country',
        collections: [_states, _cities, _areas, _localities],
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
          .map((doc) => ServiceState.fromMap(doc.id, doc.data()))
          .toList();

      result.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      return result;
    });
  }

  Future<String> saveState(ServiceState state) async {
    _validateName(state.name, 'State name');

    await _requireDocument(_countries, state.countryId, 'country');

    if (state.isActive) {
      await _requireActiveCountry(state.countryId);
    }

    final isNew = state.id.trim().isEmpty;

    if (!isNew) {
      final oldData = await _requireDocument(
        _states,
        state.id,
        'state',
      );

      final oldCountryId = oldData['countryId']?.toString() ?? '';

      if (oldCountryId != state.countryId) {
        await _ensureNoChildrenForReparent(
          parentId: state.id,
          parentLabel: 'state',
          collections: [_cities, _areas, _localities],
          parentFields: ['stateId', 'stateId', 'stateId'],
        );
      }
    }

    return _saveUniqueNamedDocument(
      collection: _states,
      documentId: state.id,
      name: state.name,
      label: 'State',
      parentFields: const ['countryId'],
      parentIds: [state.countryId],
      data: state.toMap(includeCreatedAt: isNew),
      includeCreatedAt: isNew,
    );
  }

  Future<void> setStateStatus({
    required String stateId,
    required bool isActive,
  }) async {
    final data = await _requireDocument(_states, stateId, 'state');

    if (isActive) {
      await _requireActiveCountry(
        data['countryId']?.toString() ?? '',
      );
    } else {
      await _ensureNoActiveChildren(
        parentId: stateId,
        parentLabel: 'state',
        collections: [_cities, _areas, _localities],
        parentFields: ['stateId', 'stateId', 'stateId'],
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
      query = query.where('countryId', isEqualTo: countryId);
    }

    if (stateId != null && stateId.trim().isNotEmpty) {
      query = query.where('stateId', isEqualTo: stateId);
    }

    return query.snapshots().map((snapshot) {
      final result = snapshot.docs
          .map((doc) => ServiceCity.fromMap(doc.id, doc.data()))
          .toList();

      result.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      return result;
    });
  }

  Future<ServiceCity?> getCity(String cityId) async {
    final doc = await _cities.doc(cityId).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

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
      throw StateError(
        'Selected state does not belong to this country.',
      );
    }

    if (city.isServiceActive &&
        (country['isActive'] != true || state['isActive'] != true)) {
      throw StateError(
        'The country and state must be active '
        'before activating this city.',
      );
    }

    _validateBoundary(
      boundary: city.boundary,
      boundaryVerified: city.boundaryVerified,
      boundarySource: city.boundarySource,
      isServiceActive: city.isServiceActive,
    );

    final isNew = city.id.trim().isEmpty;

    if (!isNew) {
      final oldData = await _requireDocument(
        _cities,
        city.id,
        'city/district',
      );

      final oldStateId = oldData['stateId']?.toString() ?? '';

      if (oldStateId != city.stateId) {
        await _ensureNoChildrenForReparent(
          parentId: city.id,
          parentLabel: 'city/district',
          collections: [_areas, _localities],
          parentFields: ['cityId', 'cityId'],
        );
      }
    }

    return _saveUniqueNamedDocument(
      collection: _cities,
      documentId: city.id,
      name: city.name,
      label: 'City/District',
      parentFields: const ['stateId'],
      parentIds: [city.stateId],
      data: city.toMap(includeCreatedAt: isNew),
      includeCreatedAt: isNew,
    );
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
          .map((doc) => ServiceArea.fromMap(doc.id, doc.data()))
          .toList();

      result.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
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

    if (area.isServiceActive &&
        (country['isActive'] != true ||
            state['isActive'] != true ||
            !city.isServiceActive)) {
      throw StateError(
        'Activate the parent country, state and city/district '
        'before activating this area.',
      );
    }

    _validateBoundary(
      boundary: area.boundary,
      boundaryVerified: area.boundaryVerified,
      boundarySource: area.boundarySource,
      isServiceActive: area.isServiceActive,
    );

    final isNew = area.id.trim().isEmpty;

    if (!isNew) {
      final oldData = await _requireDocument(
        _areas,
        area.id,
        'area',
      );

      final oldCityId = oldData['cityId']?.toString() ?? '';

      if (oldCityId != area.cityId) {
        await _ensureNoChildrenForReparent(
          parentId: area.id,
          parentLabel: 'area',
          collections: [_localities],
          parentFields: ['areaId'],
        );
      }
    }

    return _saveUniqueNamedDocument(
      collection: _areas,
      documentId: area.id,
      name: area.name,
      label: 'Area/Sub-district',
      parentFields: const ['cityId'],
      parentIds: [area.cityId],
      data: area.toMap(includeCreatedAt: isNew),
      includeCreatedAt: isNew,
    );
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
          .map((doc) => ServiceLocality.fromMap(doc.id, doc.data()))
          .toList();

      result.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      return result;
    });
  }

  Future<String> saveLocality(ServiceLocality locality) async {
    _validateName(locality.name, 'Locality/Village name');

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

    final area = ServiceArea.fromMap(locality.areaId, areaData);

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

    if (locality.isServiceActive &&
        (country['isActive'] != true ||
            state['isActive'] != true ||
            !city.isServiceActive ||
            !area.isServiceActive)) {
      throw StateError(
        'Activate the parent country, state, city/district '
        'and area before activating this locality.',
      );
    }

    _validateBoundary(
      boundary: locality.boundary,
      boundaryVerified: locality.boundaryVerified,
      boundarySource: locality.boundarySource,
      isServiceActive: locality.isServiceActive,
    );

    final isNew = locality.id.trim().isEmpty;

    if (!isNew) {
      await _requireExistingForUpdate(
        _localities,
        locality.id,
        'locality',
      );
    }

    return _saveUniqueNamedDocument(
      collection: _localities,
      documentId: locality.id,
      name: locality.name,
      label: 'Locality/Village',
      parentFields: const ['areaId'],
      parentIds: [locality.areaId],
      data: locality.toMap(includeCreatedAt: isNew),
      includeCreatedAt: isNew,
    );
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

  Future<String> saveImport(ServiceLocationImport record) async {
    _validateName(record.source, 'Import source');
    _validateName(record.fileName, 'Import file name');
    _validateName(record.status, 'Import status');
    _validateName(record.importedBy, 'Importer');
    _validateName(record.verificationStatus, 'Verification status');

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
        collections: [_areas, _localities],
        parentFields: ['cityId', 'cityId'],
        statusFields: ['isServiceActive', 'isServiceActive'],
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
    final data = await _requireDocument(_areas, areaId, 'area');

    final area = ServiceArea.fromMap(areaId, data);

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

    final locality = ServiceLocality.fromMap(localityId, data);

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

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/service_city.dart';
import '../models/service_area.dart';
import '../models/service_locality.dart';

class ServiceLocationService {
  ServiceLocationService({
    FirebaseFirestore? firestore,
  }) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // Firestore collections
  CollectionReference<Map<String, dynamic>> get _cities =>
      _db.collection('service_cities');

  CollectionReference<Map<String, dynamic>> get _areas =>
      _db.collection('service_areas');

  CollectionReference<Map<String, dynamic>> get _localities =>
      _db.collection('service_localities');

  // =========================================================
  // VALIDATION
  // =========================================================

  void _validateName(String name, String label) {
    if (name.trim().isEmpty) {
      throw ArgumentError('$label is required.');
    }
  }

  void _validateBoundary({
    required List<GeoPoint> boundary,
    required bool boundaryVerified,
    required bool isServiceActive,
  }) {
    if (isServiceActive && !boundaryVerified) {
      throw StateError(
        'Verify the geographic boundary before activating service.',
      );
    }

    if (isServiceActive && boundary.length < 3) {
      throw StateError(
        'A valid boundary with at least 3 points is required.',
      );
    }
  }

  // =========================================================
  // CITIES
  // =========================================================

  Stream<List<ServiceCity>> watchCities() {
    return _cities
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ServiceCity.fromMap(
                  doc.id,
                  doc.data(),
                ),
              )
              .toList(),
        );
  }

  Future<ServiceCity?> getCity(String cityId) async {
    final doc = await _cities.doc(cityId).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return ServiceCity.fromMap(doc.id, doc.data()!);
  }

  Future<String> saveCity(ServiceCity city) async {
    _validateName(city.name, 'City name');
    _validateName(city.state, 'State');
    _validateName(city.country, 'Country');

    _validateBoundary(
      boundary: city.boundary,
      boundaryVerified: city.boundaryVerified,
      isServiceActive: city.isServiceActive,
    );

    if (city.isServiceActive && !city.boundaryVerified) {
      throw StateError(
        'The city boundary must be verified before activation.',
      );
    }

    final isNew = city.id.trim().isEmpty;
    final doc = isNew ? _cities.doc() : _cities.doc(city.id);

    await doc.set(
      city.toMap(includeCreatedAt: isNew),
      SetOptions(merge: true),
    );

    return doc.id;
  }

  // =========================================================
  // AREAS
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
    _validateName(area.name, 'Area name');

    if (area.cityId.trim().isEmpty) {
      throw ArgumentError('A city must be selected.');
    }

    final city = await getCity(area.cityId);

    if (city == null) {
      throw StateError('The selected city does not exist.');
    }

    _validateBoundary(
      boundary: area.boundary,
      boundaryVerified: area.boundaryVerified,
      isServiceActive: area.isServiceActive,
    );

    if (area.isServiceActive && !city.isServiceActive) {
      throw StateError(
        'Activate the parent city before activating this area.',
      );
    }

    final isNew = area.id.trim().isEmpty;
    final doc = isNew ? _areas.doc() : _areas.doc(area.id);

    await doc.set(
      area.toMap(includeCreatedAt: isNew),
      SetOptions(merge: true),
    );

    return doc.id;
  }

  // =========================================================
  // LOCALITIES
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
    _validateName(locality.name, 'Locality name');

    if (locality.cityId.trim().isEmpty) {
      throw ArgumentError('A city must be selected.');
    }

    if (locality.areaId.trim().isEmpty) {
      throw ArgumentError('An area must be selected.');
    }

    final city = await getCity(locality.cityId);

    if (city == null) {
      throw StateError('The selected city does not exist.');
    }

    final areaDoc = await _areas.doc(locality.areaId).get();

    if (!areaDoc.exists || areaDoc.data() == null) {
      throw StateError('The selected area does not exist.');
    }

    final area = ServiceArea.fromMap(
      areaDoc.id,
      areaDoc.data()!,
    );

    if (area.cityId != locality.cityId) {
      throw StateError(
        'The selected area does not belong to this city.',
      );
    }

    _validateBoundary(
      boundary: locality.boundary,
      boundaryVerified: locality.boundaryVerified,
      isServiceActive: locality.isServiceActive,
    );

    if (locality.isServiceActive &&
        (!city.isServiceActive || !area.isServiceActive)) {
      throw StateError(
        'The parent city and area must both be active.',
      );
    }

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
  // STATUS HELPERS
  // =========================================================

  Future<void> setCityServiceStatus({
    required String cityId,
    required bool isActive,
  }) async {
    final city = await getCity(cityId);

    if (city == null) {
      throw StateError('City not found.');
    }

    _validateBoundary(
      boundary: city.boundary,
      boundaryVerified: city.boundaryVerified,
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
    final doc = await _areas.doc(areaId).get();

    if (!doc.exists || doc.data() == null) {
      throw StateError('Area not found.');
    }

    final area = ServiceArea.fromMap(
      doc.id,
      doc.data()!,
    );

    if (isActive) {
      final city = await getCity(area.cityId);

      if (city == null || !city.isServiceActive) {
        throw StateError(
          'Activate the parent city first.',
        );
      }
    }

    _validateBoundary(
      boundary: area.boundary,
      boundaryVerified: area.boundaryVerified,
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
    final doc = await _localities.doc(localityId).get();

    if (!doc.exists || doc.data() == null) {
      throw StateError('Locality not found.');
    }

    final locality = ServiceLocality.fromMap(
      doc.id,
      doc.data()!,
    );

    if (isActive) {
      final city = await getCity(locality.cityId);
      final areaDoc = await _areas.doc(locality.areaId).get();

      if (city == null || !city.isServiceActive) {
        throw StateError(
          'Activate the parent city first.',
        );
      }

      if (!areaDoc.exists ||
          areaDoc.data()?['isServiceActive'] != true) {
        throw StateError(
          'Activate the parent area first.',
        );
      }
    }

    _validateBoundary(
      boundary: locality.boundary,
      boundaryVerified: locality.boundaryVerified,
      isServiceActive: isActive,
    );

    await _localities.doc(localityId).update({
      'isServiceActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

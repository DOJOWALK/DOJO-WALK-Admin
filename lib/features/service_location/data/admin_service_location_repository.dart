import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'admin_location_option.dart';

/// Fresh data-access layer for the service-location form.
///
/// Catalog data is read from Firestore under the active super_admin Rules.
/// All creates go through saveServiceLocationWithNameIndex; the client never
/// writes directly to protected hierarchy collections or name indexes.
class AdminServiceLocationRepository {
  AdminServiceLocationRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'asia-south1');

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> _collection(String type) {
    const names = <String, String>{
      'country': 'service_countries',
      'state': 'service_states',
      'district': 'service_districts',
      'city': 'service_cities',
      'area': 'service_areas',
      'locality': 'service_localities',
    };
    final collection = names[type];
    if (collection == null) throw ArgumentError.value(type, 'type');
    return _firestore.collection(collection);
  }

  Stream<List<AdminLocationOption>> watchOptions(
    String type, {
    String? countryId,
    String? stateId,
    String? districtId,
    String? cityId,
    String? areaId,
  }) {
    Query<Map<String, dynamic>> query = _collection(type);

    void filter(String field, String? value) {
      if (value != null && value.trim().isNotEmpty) {
        query = query.where(field, isEqualTo: value.trim());
      }
    }

    switch (type) {
      case 'country':
        break;
      case 'state':
        filter('countryId', countryId);
        break;
      case 'district':
        filter('countryId', countryId);
        filter('stateId', stateId);
        break;
      case 'city':
        filter('countryId', countryId);
        filter('stateId', stateId);
        filter('districtId', districtId);
        break;
      case 'area':
        filter('countryId', countryId);
        filter('stateId', stateId);
        filter('cityId', cityId);
        break;
      case 'locality':
        filter('countryId', countryId);
        filter('stateId', stateId);
        filter('cityId', cityId);
        filter('areaId', areaId);
        break;
    }

    return query.orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => AdminLocationOption.fromMap(doc.id, doc.data()))
              .where((option) => option.name.trim().isNotEmpty)
              .toList(growable: false),
        );
  }

  Future<String> saveLocation({
    required String type,
    required Map<String, String> parentIds,
    required String name,
    String? code,
    String? pincode,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty || cleanName.length > 120) {
      throw ArgumentError('Name must contain 1 to 120 characters.');
    }

    final payload = <String, dynamic>{'name': cleanName};
    switch (type) {
      case 'country':
        final cleanCode = (code ?? '').trim();
        if (cleanCode.isEmpty || cleanCode.length > 16) {
          throw ArgumentError('Country code is required (maximum 16 characters).');
        }
        payload['code'] = cleanCode;
        break;
      case 'state':
        payload['countryId'] = _parent(parentIds, 'countryId');
        break;
      case 'district':
        payload['countryId'] = _parent(parentIds, 'countryId');
        payload['stateId'] = _parent(parentIds, 'stateId');
        break;
      case 'city':
        payload['countryId'] = _parent(parentIds, 'countryId');
        payload['stateId'] = _parent(parentIds, 'stateId');
        payload['districtId'] = _parent(parentIds, 'districtId');
        break;
      case 'area':
        payload['countryId'] = _parent(parentIds, 'countryId');
        payload['stateId'] = _parent(parentIds, 'stateId');
        payload['cityId'] = _parent(parentIds, 'cityId');
        break;
      case 'locality':
        payload['countryId'] = _parent(parentIds, 'countryId');
        payload['stateId'] = _parent(parentIds, 'stateId');
        payload['cityId'] = _parent(parentIds, 'cityId');
        payload['areaId'] = _parent(parentIds, 'areaId');
        final cleanPin = (pincode ?? '').trim();
        if (cleanPin.isNotEmpty) payload['pincode'] = cleanPin;
        break;
      default:
        throw ArgumentError.value(type, 'type', 'Unsupported location type.');
    }

    final id = _collection(type).doc().id;
    final result = await _functions
        .httpsCallable('saveServiceLocationWithNameIndex')
        .call<Map<String, dynamic>>({
      'locationType': type,
      'locationId': id,
      'payload': payload,
    });
    final savedId = result.data['locationId']?.toString();
    if (savedId != id) {
      throw StateError('Backend returned an unexpected location ID.');
    }
    return id;
  }

  String _parent(Map<String, String> ids, String key) {
    final value = ids[key]?.trim() ?? '';
    if (value.isEmpty) throw ArgumentError('$key is required.');
    return value;
  }
}

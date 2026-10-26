import 'dart:async';

import '../models/service_location_models.dart';

/// Narrow seam for the Add Location dialog.
///
/// Keeping the dialog dependent on this interface allows widget tests to
/// exercise dropdown loading, validation, and save intent without initializing
/// Firebase. Production continues to use [ServiceLocationService].
abstract interface class AddLocationDataSource {
  Stream<List<ServiceCountry>> watchCountries();

  Stream<List<ServiceState>> watchStates({String? countryId});

  Stream<List<ServiceDistrict>> watchDistricts({
    String? countryId,
    String? stateId,
    bool? activeOnly,
  });

  Stream<List<ServiceCity>> watchCities({
    String? countryId,
    String? stateId,
    bool? activeOnly,
  });

  Stream<List<ServiceArea>> watchAreas({
    String? countryId,
    String? stateId,
    String? cityId,
    bool? activeOnly,
  });

  Future<void> saveCountry(ServiceCountry country);
  Future<void> saveState(ServiceState state);
  Future<void> saveDistrict(ServiceDistrict district);
  Future<ServiceCity?> getCity(String cityId);
  Future<void> saveCity(ServiceCity city);
  Future<void> saveArea(ServiceArea area);
  Future<void> saveLocality(ServiceLocality locality);
}

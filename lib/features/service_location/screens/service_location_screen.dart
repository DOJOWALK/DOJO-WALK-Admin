/// DOJO WALK Admin
///
/// Service Locations management screen.
///
/// Boundary lifecycle supported by the current Firestore Rules:
/// Pending -> Verified
/// Pending -> Rejected -> Edit and resubmit
///
/// Important:
/// - New boundaries are saved directly as Pending.
/// - A separate persisted Draft status is not supported by
///   the current Firestore Rules.
/// - Verified boundaries are read-only.
/// - Boundary verification and service activation are separate.
/// - City and Area activation use ServiceLocationService.
/// - Locality activation does not require its own polygon.
/// - Legacy Zones are not modified.

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/service_location_boundary.dart';
import '../models/service_location_models.dart';
import '../services/location_csv_preview_parser.dart';
import '../services/location_csv_lgd_validator.dart';
import '../services/location_csv_import_service.dart';
import '../services/service_location_boundary_service.dart';
import '../services/service_location_service.dart';
import '../widgets/add_location_dialog.dart';
import '../widgets/service_boundary_editor.dart';

const Color _locationOrange = Color(0xFFFF7900);
const Color _locationBackground = Color(0xFFFFFAF5);

const LatLng _defaultMapCenter = LatLng(28.4744, 77.5040);

class ServiceLocationScreen extends StatefulWidget {
  const ServiceLocationScreen({super.key});

  @override
  State<ServiceLocationScreen> createState() =>
      _ServiceLocationScreenState();
}

class _ServiceLocationScreenState
    extends State<ServiceLocationScreen> {
  final ServiceLocationService _service =
      ServiceLocationService();

  final ServiceLocationBoundaryService _boundaryService =
      ServiceLocationBoundaryService();

  final TextEditingController _searchController =
      TextEditingController();

  int _selectedTab = 0;
  String _search = '';

  GoogleMapController? _mapController;
  late Future<Set<Polygon>> _activeBoundaryPolygonsFuture;
  Set<Polygon> _loadedActiveBoundaryPolygons = <Polygon>{};
  String? _lastFittedPolygonSignature;

  static const List<String> _tabNames = [
    'Countries',
    'States',
    'Districts',
    'Cities',
    'Areas / Sub-districts',
    'Localities / Villages',
    'Import History',
  ];

  @override
  void initState() {
    super.initState();
    _activeBoundaryPolygonsFuture = _loadActiveBoundaryPolygons();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showError(Object error) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Action could not be completed'),
        content: SelectableText(error.toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  bool _matches(String value) {
    final query = _search.trim().toLowerCase();

    if (query.isEmpty) return true;

    return value.toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 600;

    return Scaffold(
      backgroundColor: _locationBackground,
      appBar: AppBar(
        toolbarHeight: isMobile ? 68 : 76,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF242424),
        elevation: 0,
        titleSpacing: 18,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _locationOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: _locationOrange,
                size: 23,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Service Locations',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Coverage & boundary management',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: isMobile ? 8 : 20),
            child: Center(
              child: FilledButton.icon(
                onPressed: _showAddLocationDialog,
                icon: const Icon(Icons.add_location_alt_outlined, size: 19),
                label: Text(isMobile ? 'Add' : 'Add Location'),
                style: FilledButton.styleFrom(
                  backgroundColor: _locationOrange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 18,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 12 : 20, 12, isMobile ? 12 : 20, 0,
            ),
            child: SizedBox(
              width: double.infinity,
              height: isMobile ? 172 : 228,
              child: _buildMapPreview(),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 12 : 20, 12, isMobile ? 12 : 20, 8,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _search = value.trim()),
              decoration: InputDecoration(
                hintText: 'Search state, city, area or code',
                hintStyle: const TextStyle(fontSize: 13, color: Colors.black45),
                prefixIcon: const Icon(Icons.search_rounded, color: _locationOrange),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFECE5DE)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _locationOrange, width: 1.5),
                ),
              ),
            ),
          ),
          _buildTabs(),
          const Divider(height: 1, color: Color(0xFFECE5DE)),
          Expanded(
            child: Container(
              color: Colors.white,
              child: _buildSelectedList(),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(isMobile ? 12 : 20, 14, isMobile ? 12 : 20, 0),
      padding: EdgeInsets.all(isMobile ? 13 : 17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFFF8F0)],
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFFFE1C5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9B5B25).withValues(alpha: 0.045),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Coverage overview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: _locationOrange.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, size: 14, color: _locationOrange),
                    SizedBox(width: 5),
                    Text(
                      'Verification required',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _locationOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 5,
            runSpacing: 6,
            children: [
              _hierarchyChip('Country'),
              _hierarchyArrow(),
              _hierarchyChip('State'),
              _hierarchyArrow(),
              _hierarchyChip('City / District'),
              _hierarchyArrow(),
              _hierarchyChip('Area'),
              _hierarchyArrow(),
              _hierarchyChip('Locality'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, size: 16, color: Colors.black54),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'नई boundaries Pending Review में सेव होती हैं। Verified boundary भी service को अपने आप active नहीं करती।',
                  style: TextStyle(fontSize: 11, height: 1.35, color: Colors.black54),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hierarchyChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEFE3D8)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _hierarchyArrow() => const Icon(
        Icons.chevron_right_rounded,
        size: 16,
        color: _locationOrange,
      );

  // ============================================================
  // MAP PREVIEW
  // ============================================================

  Future<Set<Polygon>> _loadActiveBoundaryPolygons() async {
    final cities = await _service.watchCities().first;
    final areas = await _service.watchAreas().first;
    final boundarySnapshot = await FirebaseFirestore.instance
        .collection('service_location_boundaries')
        .where('verificationStatus', isEqualTo: 'verified')
        .get();
    final boundariesById = {
      for (final document in boundarySnapshot.docs)
        document.id: ServiceLocationBoundary.fromMap(
          document.id,
          document.data(),
        ),
    };
    final polygons = <Polygon>{};

    for (final city in cities.where((item) => item.isServiceActive)) {
      final boundaryId = city.verifiedBoundaryId.trim();
      if (boundaryId.isEmpty) continue;

      final boundary = boundariesById[boundaryId];
      if (boundary == null ||
          !boundary.isVerified ||
          boundary.locationId != city.id ||
          boundary.locationType.toLowerCase() != 'city' ||
          boundary.points.length < 3) {
        continue;
      }

      polygons.add(
        Polygon(
          polygonId: PolygonId('service-city-${city.id}'),
          points: boundary.points
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList(growable: false),
          strokeColor: _locationOrange,
          strokeWidth: 2,
          fillColor: _locationOrange.withValues(alpha: 0.05),
          consumeTapEvents: true,
          onTap: () => _showMessage('Active city boundary: ${city.name}'),
        ),
      );
    }

    for (final area in areas.where((item) => item.isServiceActive)) {
      final boundaryId = area.verifiedBoundaryId.trim();
      if (boundaryId.isEmpty) continue;

      final boundary = boundariesById[boundaryId];
      if (boundary == null ||
          !boundary.isVerified ||
          boundary.locationId != area.id ||
          boundary.locationType.toLowerCase() != 'area' ||
          boundary.points.length < 3) {
        continue;
      }

      polygons.add(
        Polygon(
          polygonId: PolygonId('service-area-${area.id}'),
          points: boundary.points
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList(growable: false),
          strokeColor: _locationOrange,
          strokeWidth: 2,
          fillColor: _locationOrange.withValues(alpha: 0.18),
          consumeTapEvents: true,
          onTap: () => _showMessage('Active service area: ${area.name}'),
        ),
      );
    }

    return polygons;
  }

  Future<void> _fitMapToActiveBoundaries(Set<Polygon> polygons) async {
    final controller = _mapController;
    if (controller == null || polygons.isEmpty) return;

    final ids = polygons.map((polygon) => polygon.polygonId.value).toList()
      ..sort();
    final signature = ids.join('|');
    if (signature == _lastFittedPolygonSignature) return;
    _lastFittedPolygonSignature = signature;

    final points = polygons.expand((polygon) => polygon.points).toList();
    if (points.isEmpty) return;

    var minLat = points.first.latitude;
    var maxLat = minLat;
    var minLng = points.first.longitude;
    var maxLng = minLng;

    for (final point in points.skip(1)) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    if (minLat == maxLat) {
      minLat -= 0.001;
      maxLat += 0.001;
    }
    if (minLng == maxLng) {
      minLng -= 0.001;
      maxLng += 0.001;
    }

    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          24,
        ),
      );
    } catch (_) {
      // A map can still be usable even if the camera cannot fit its bounds.
    }
  }

  Widget _buildMapPreview() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _locationOrange.withValues(alpha: 0.25),
        ),
      ),
      child: FutureBuilder<Set<Polygon>>(
        future: _activeBoundaryPolygonsFuture,
        builder: (context, snapshot) {
          final polygons = snapshot.data ?? <Polygon>{};
          _loadedActiveBoundaryPolygons = polygons;
          if (snapshot.hasData && polygons.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fitMapToActiveBoundaries(polygons);
            });
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: _defaultMapCenter,
                  zoom: 11,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (_loadedActiveBoundaryPolygons.isNotEmpty) {
                    _fitMapToActiveBoundaries(_loadedActiveBoundaryPolygons);
                  }
                },
                polygons: polygons,
                mapType: MapType.normal,
                myLocationButtonEnabled: false,
                myLocationEnabled: false,
                zoomControlsEnabled: true,
                compassEnabled: true,
                mapToolbarEnabled: false,
              ),
              Positioned(
                left: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.map_outlined,
                        size: 18,
                        color: _locationOrange,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        snapshot.connectionState == ConnectionState.waiting
                            ? 'Loading active boundaries…'
                            : 'Active boundaries: ${polygons.length}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.95),
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Refresh active boundaries',
                    onPressed: () {
                      setState(() {
                        _lastFittedPolygonSignature = null;
                        _activeBoundaryPolygonsFuture =
                            _loadActiveBoundaryPolygons();
                      });
                    },
                    icon: const Icon(Icons.refresh, color: _locationOrange),
                  ),
                ),
              ),
              if (snapshot.hasError)
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 54,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      'Unable to load active boundaries: ${snapshot.error}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Text(
                    'Orange outlines show active verified City/Area boundaries. '
                    'Tap a polygon to identify it; use Manage Boundary to review details.',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // TABS
  // ============================================================

  Widget _buildTabs() {
    return SizedBox(
      height: 54,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 7,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: _tabNames.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ChoiceChip(
            label: Text(_tabNames[index]),
            selected: _selectedTab == index,
            selectedColor:
                _locationOrange.withValues(alpha: 0.18),
            onSelected: (_) {
              setState(() => _selectedTab = index);
            },
          );
        },
      ),
    );
  }

  Widget _buildSelectedList() {
    switch (_selectedTab) {
      case 0:
        return _buildCountries();
      case 1:
        return _buildStates();
      case 2:
        return _buildDistricts();
      case 3:
        return _buildCities();
      case 4:
        return _buildAreas();
      case 5:
        return _buildLocalities();
      case 6:
        return _buildImports();
      default:
        return _buildCountries();
    }
  }

  Widget _emptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_searching,
              size: 44,
              color: _locationOrange,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: _locationOrange,
      ),
    );
  }

  // ============================================================
  // COUNTRIES
  // ============================================================

  Widget _buildCountries() {
    return StreamBuilder<List<ServiceCountry>>(
      stream: _service.watchCountries(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _emptyState(
            'Unable to load countries:\n${snapshot.error}',
          );
        }

        if (!snapshot.hasData) {
          return _loadingState();
        }

        final items = snapshot.data!
            .where(
              (item) => _matches(
                '${item.id} ${item.name} ${item.code}',
              ),
            )
            .toList();

        if (items.isEmpty) {
          return _emptyState('No countries found.');
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];

            return _locationCard(
              title: item.name,
              subtitle:
                  'ID: ${item.id} · Code: ${item.code}',
              active: item.isActive,
              icon: Icons.public,
              onToggle: (value) async {
                try {
                  await _service.setCountryStatus(
                    countryId: item.id,
                    isActive: value,
                  );
                } catch (error) {
                  await _showError(error);
                }
              },
            );
          },
        );
      },
    );
  }

  // ============================================================
  // STATES
  // ============================================================

  Widget _buildStates() {
    return StreamBuilder<List<ServiceCountry>>(
      stream: _service.watchCountries(),
      builder: (context, countrySnapshot) {
        if (countrySnapshot.hasError) {
          return _emptyState('${countrySnapshot.error}');
        }

        if (!countrySnapshot.hasData) {
          return _loadingState();
        }

        final countries = countrySnapshot.data!;

        if (countries.isEmpty) {
          return _emptyState('Add a country first.');
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            for (final country in countries)
              StreamBuilder<List<ServiceState>>(
                stream: _service.watchStates(
                  countryId: country.id,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final items = snapshot.data!
                      .where(
                        (item) => _matches(
                          '${item.id} ${item.name} '
                          '${country.id} ${country.name}',
                        ),
                      )
                      .toList();

                  if (items.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(country.name),
                      for (final item in items)
                        _locationCard(
                          title: item.name,
                          subtitle:
                              'ID: ${item.id} · Country: ${country.name}',
                          active: item.isActive,
                          icon: Icons.map_outlined,
                          onToggle: (value) async {
                            try {
                              await _service.setStateStatus(
                                stateId: item.id,
                                isActive: value,
                              );
                            } catch (error) {
                              await _showError(error);
                            }
                          },
                        ),
                    ],
                  );
                },
              ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DISTRICTS
  // ============================================================

  Widget _buildDistricts() {
    return StreamBuilder<List<ServiceCountry>>(
      stream: _service.watchCountries(),
      builder: (context, countrySnapshot) {
        if (countrySnapshot.hasError) {
          return _emptyState('Unable to load Countries: ${countrySnapshot.error}');
        }
        if (!countrySnapshot.hasData) return _loadingState();

        return StreamBuilder<List<ServiceState>>(
          stream: _service.watchStates(),
          builder: (context, stateSnapshot) {
            if (stateSnapshot.hasError) {
              return _emptyState('Unable to load States: ${stateSnapshot.error}');
            }
            if (!stateSnapshot.hasData) return _loadingState();

            return StreamBuilder<List<ServiceDistrict>>(
              stream: _service.watchDistricts(),
              builder: (context, districtSnapshot) {
                if (districtSnapshot.hasError) {
                  return _emptyState(
                    'Unable to load Districts: ${districtSnapshot.error}',
                  );
                }
                if (!districtSnapshot.hasData) return _loadingState();

                final countriesById = {
                  for (final country in countrySnapshot.data!) country.id: country,
                };
                final statesById = {
                  for (final state in stateSnapshot.data!) state.id: state,
                };
                final districts = districtSnapshot.data!.where((district) {
                  final state = statesById[district.stateId];
                  final country = countriesById[district.countryId];
                  return _matches(
                    '${district.id} ${district.name} '
                    '${district.stateId} ${state?.name ?? ""} '
                    '${district.countryId} ${country?.name ?? ""}',
                  );
                }).toList();

                if (districts.isEmpty) {
                  return _emptyState(
                    _search.isEmpty
                        ? 'No Districts yet. Use Add Location to create a District under a State.'
                        : 'No Districts match your search.',
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _sectionTitle('Districts · ${districts.length}'),
                    for (final district in districts)
                      _locationCard(
                        title: district.name,
                        subtitle: 'State: ${statesById[district.stateId]?.name ?? "Unknown State"}\\n'
                            'Country: ${countriesById[district.countryId]?.name ?? "Unknown Country"}\\n'
                            'Service: ${district.isActive ? "Active" : "Inactive"}',
                        active: district.isActive,
                        icon: Icons.map_outlined,
                        onToggle: (value) async {
                          try {
                            await _service.setDistrictStatus(
                              districtId: district.id,
                              isActive: value,
                            );
                            _showMessage(
                              value
                                  ? 'District activated.'
                                  : 'District deactivated.',
                            );
                          } catch (error) {
                            await _showError(error);
                          }
                        },
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // ============================================================
  // CITIES / DISTRICTS
  // ============================================================

  Widget _buildCities() {
    return StreamBuilder<List<ServiceCountry>>(
      stream: _service.watchCountries(),
      builder: (context, countrySnapshot) {
        if (countrySnapshot.hasError) {
          return _emptyState('${countrySnapshot.error}');
        }
        if (!countrySnapshot.hasData) return _loadingState();

        return StreamBuilder<List<ServiceState>>(
          stream: _service.watchStates(),
          builder: (context, stateSnapshot) {
            if (stateSnapshot.hasError) {
              return _emptyState('${stateSnapshot.error}');
            }
            if (!stateSnapshot.hasData) return _loadingState();

            return StreamBuilder<List<ServiceDistrict>>(
              stream: _service.watchDistricts(),
              builder: (context, districtSnapshot) {
                if (districtSnapshot.hasError) {
                  return _emptyState('${districtSnapshot.error}');
                }
                if (!districtSnapshot.hasData) return _loadingState();

                final districtsById = {
                  for (final district in districtSnapshot.data!)
                    district.id: district,
                };

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    for (final country in countrySnapshot.data!)
                      for (final state in stateSnapshot.data!.where(
                        (item) => item.countryId == country.id,
                      ))
                        StreamBuilder<List<ServiceCity>>(
                          stream: _service.watchCities(
                            countryId: country.id,
                            stateId: state.id,
                          ),
                          builder: (context, citySnapshot) {
                            if (citySnapshot.hasError ||
                                !citySnapshot.hasData) {
                              return const SizedBox.shrink();
                            }

                            final cities = citySnapshot.data!.where((item) {
                              final district = districtsById[item.districtId];
                              return _matches(
                                '${item.id} ${item.name} '
                                '${state.id} ${state.name} '
                                '${country.id} ${country.name} '
                                '${item.districtId} ${district?.name ?? "Legacy City"}',
                              );
                            }).toList();

                            if (cities.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionTitle('${state.name} · ${country.name}'),
                                for (final item in cities)
                                  _locationCard(
                                    title: item.name,
                                    subtitle:
                                        'ID: ${item.id}\\n'
                                        'District: ${districtsById[item.districtId]?.name ?? (item.districtId.isEmpty ? "Not linked (legacy City)" : "Unknown District")}\\n'
                                        'Legacy boundary points: ${item.boundary.length}\\n'
                                        'Legacy verified: ${item.boundaryVerified ? "Yes" : "No"}\\n'
                                        'Service: ${item.isServiceActive ? "Active" : "Inactive"}',
                                    active: item.isServiceActive,
                                    icon: Icons.location_city,
                                    onManageBoundary: () => _manageBoundary(
                                      locationId: item.id,
                                      locationName: item.name,
                                      locationType: 'city',
                                    ),
                                    onToggle: (value) async {
                                      try {
                                        await _service.setCityServiceStatus(
                                          cityId: item.id,
                                          isActive: value,
                                        );
                                        _showMessage(
                                          value
                                              ? 'City service activated.'
                                              : 'City service deactivated.',
                                        );
                                      } catch (error) {
                                        await _showError(error);
                                      }
                                    },
                                  ),
                              ],
                            );
                          },
                        ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // ============================================================
  // AREAS / SUB-DISTRICTS
  // ============================================================

  Widget _buildAreas() {
    return StreamBuilder<List<ServiceCity>>(
      stream: _service.watchCities(),
      builder: (context, citySnapshot) {
        if (citySnapshot.hasError) {
          return _emptyState('${citySnapshot.error}');
        }

        if (!citySnapshot.hasData) {
          return _loadingState();
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            for (final city in citySnapshot.data!)
              StreamBuilder<List<ServiceArea>>(
                stream: _service.watchAreas(
                  cityId: city.id,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final areas = snapshot.data!
                      .where(
                        (item) => _matches(
                          '${item.id} ${item.name} '
                          '${city.id} ${city.name} ${city.districtId}',
                        ),
                      )
                      .toList();

                  if (areas.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(city.name),
                      for (final item in areas)
                        _locationCard(
                          title: item.name,
                          subtitle:
                              'ID: ${item.id}\n'
                              'City: ${city.name}\n'
                              '${city.districtId.isEmpty ? "District: Legacy City (not linked)" : "District ID: ${city.districtId}"}\n'
                              'Legacy boundary points: '
                              '${item.boundary.length} · '
                              'Legacy verified: '
                              '${item.boundaryVerified ? "Yes" : "No"}\n'
                              'Service: ${item.isServiceActive ? "Active" : "Inactive"}',
                          active: item.isServiceActive,
                          icon: Icons.grid_view,
                          onManageBoundary: () =>
                              _manageBoundary(
                            locationId: item.id,
                            locationName: item.name,
                            locationType: 'area',
                          ),
                          onToggle: (value) async {
                            try {
                              await _service.setAreaServiceStatus(
                                areaId: item.id,
                                isActive: value,
                              );

                              _showMessage(
                                value
                                    ? 'Area service activated.'
                                    : 'Area service deactivated.',
                              );
                            } catch (error) {
                              await _showError(error);
                            }
                          },
                        ),
                    ],
                  );
                },
              ),
          ],
        );
      },
    );
  }

  // ============================================================
  // LOCALITIES / VILLAGES
  // ============================================================

  Widget _buildLocalities() {
    return StreamBuilder<List<ServiceCity>>(
      stream: _service.watchCities(),
      builder: (context, citySnapshot) {
        if (citySnapshot.hasError) {
          return _emptyState('${citySnapshot.error}');
        }

        if (!citySnapshot.hasData) {
          return _loadingState();
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            for (final city in citySnapshot.data!)
              StreamBuilder<List<ServiceArea>>(
                stream: _service.watchAreas(
                  cityId: city.id,
                ),
                builder: (context, areaSnapshot) {
                  if (areaSnapshot.hasError ||
                      !areaSnapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    children: [
                      for (final area in areaSnapshot.data!)
                        StreamBuilder<List<ServiceLocality>>(
                          stream: _service.watchLocalities(
                            cityId: city.id,
                            areaId: area.id,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.hasError ||
                                !snapshot.hasData) {
                              return const SizedBox.shrink();
                            }

                            final items = snapshot.data!
                                .where(
                                  (item) => _matches(
                                    '${item.id} ${item.name} '
                                    '${item.pincode} ${item.areaId} '
                                    '${area.name} ${item.cityId} '
                                    '${city.name}',
                                  ),
                                )
                                .toList();

                            if (items.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            return Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                _sectionTitle(
                                  '${city.name} · ${area.name}',
                                ),
                                for (final item in items)
                                  _locationCard(
                                    title: item.name,
                                    subtitle:
                                        'ID: ${item.id}\n'
                                        '${city.name} · ${area.name}'
                                        '${item.pincode.isEmpty ? "" : " · PIN ${item.pincode}"}\n'
                                        'Legacy boundary: '
                                        '${item.boundaryVerified ? "Verified" : "Not verified"}\n'
                                        'Service: ${item.isServiceActive ? "Active" : "Inactive"}',
                                    active: item.isServiceActive,
                                    icon: Icons.place_outlined,
                                    onToggle: (value) async {
                                      try {
                                        await _service
                                            .setLocalityServiceStatus(
                                          localityId: item.id,
                                          isActive: value,
                                        );

                                        _showMessage(
                                          value
                                              ? 'Locality service activated.'
                                              : 'Locality service deactivated.',
                                        );
                                      } catch (error) {
                                        await _showError(error);
                                      }
                                    },
                                  ),
                              ],
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
          ],
        );
      },
    );
  }

  // ============================================================
  // GUARDED CSV IMPORT
  // ============================================================

  Future<void> _runValidatedCsvImport({
    required LocationCsvPreview preview,
    required String sourceName,
  }) async {
    String? runId;
    try {
      final countries = await _service.watchCountries().first;
      final available = countries.where((country) => country.isActive).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      if (available.isEmpty) {
        throw StateError(
          'No active service country exists. Add and activate a country before importing locations.',
        );
      }

      final selectedCountryId = await showDialog<String>(
        context: context,
        builder: (dialogContext) => SimpleDialog(
          title: const Text('Select target country'),
          children: [
            for (final country in available)
              SimpleDialogOption(
                onPressed: () => Navigator.of(dialogContext).pop(country.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Text('${country.name} (${country.code})'),
                ),
              ),
          ],
        ),
      );
      if (!mounted || selectedCountryId == null) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Confirm location import'),
          content: Text(
            'Import ${preview.rows.length} CSV rows from "$sourceName"? '
            'The importer will create missing State → District → City → Area '
            'records as inactive. It will not create boundaries or activate service. '
            'A partial run is not automatically retried.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Confirm Import'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;

      runId = 'csv-${DateTime.now().toUtc().microsecondsSinceEpoch}';
      final result = await LocationCsvImportService().importPreview(
        preview: preview,
        countryId: selectedCountryId,
        fileName: sourceName,
        importRunId: runId,
      );
      if (!mounted) return;
      _showMessage(
        'Import complete: ${result.createdRecords} created, '
        '${result.reusedRecords} reused. Run ID: $runId',
      );
    } catch (error) {
      final message = runId == null
          ? error.toString()
          : 'Import did not complete. Keep run ID "$runId" and use '
              '"Inspect / Reconcile Import Run" before attempting anything again. '
              'The importer does not automatically retry partial runs. Details: $error';
      await _showError(StateError(message));
    }
  }

  // ============================================================
  // CSV PREVIEW AND VALIDATED IMPORT
  // ============================================================

  Future<void> _showCsvPreviewDialog() async {
    final controller = TextEditingController();
    final parser = LocationCsvPreviewParser();
    LocationCsvPreview? preview;
    List<String> mappingReport = [];
    bool checkingParents = false;
    String sourceName = 'Pasted CSV';
    LocationCsvPreview? requestedImport;
    String requestedImportSource = '';

    String normalizeLocationName(String value) =>
        value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    List<String> optionalSourceHeaders(LocationCsvPreview value) =>
        value.headers.where((header) {
          final normalized = header
              .trim()
              .toLowerCase()
              .replaceAll(RegExp(r'[ _-]+'), '');
          return !const {'state', 'district', 'city', 'area'}
              .contains(normalized);
        }).toList();

    String rowPreviewSubtitle(LocationCsvRow row) {
      final validation = row.errors.isEmpty
          ? 'Validation passed'
          : row.errors.join('\n');
      final metadata = row.sourceValues.entries
          .where((entry) {
            final normalized = entry.key
                .trim()
                .toLowerCase()
                .replaceAll(RegExp(r'[ _-]+'), '');
            return !const {'state', 'district', 'city', 'area'}
                    .contains(normalized) &&
                entry.value.isNotEmpty;
          })
          .map((entry) => '${entry.key}: ${entry.value}')
          .join(' · ');
      return metadata.isEmpty
          ? validation
          : '$validation\nSource metadata: $metadata';
    }

    Future<void> checkParentMapping(StateSetter setDialogState) async {
      final currentPreview = preview;
      if (currentPreview == null || !currentPreview.isSyntacticallyValid) {
        setDialogState(() {
          mappingReport = ['Run a clean CSV validation before checking parents.'];
        });
        return;
      }

      setDialogState(() {
        checkingParents = true;
        mappingReport = [];
      });

      try {
        final states = await _service.watchStates().first;
        final districts = await _service.watchDistricts().first;
        final cities = await _service.watchCities().first;
        final areas = await _service.watchAreas().first;
        final report = <String>[];
        var matched = 0;
        var lgdMatched = 0;

        for (final row in currentPreview.rows) {
          final lgdMatch = matchCsvStateDistrictToLgd(row);
          if (lgdMatch.isMatched) {
            lgdMatched++;
          } else {
            report.add('Line ${row.lineNumber}: LGD check — ${lgdMatch.message}');
          }

          final stateName = row.values['state'] ?? '';
          final cityName = row.values['city'] ?? '';
          final areaName = row.values['area'] ?? '';

          final stateMatches = states.where(
            (item) => normalizeLocationName(item.name) ==
                normalizeLocationName(stateName),
          ).toList();

          if (stateMatches.length != 1) {
            report.add(
              'Line ${row.lineNumber}: State "$stateName" '
              '${stateMatches.isEmpty ? 'not found' : 'is ambiguous'} '
              'in existing Service Locations.',
            );
            continue;
          }

          final state = stateMatches.single;
          final districtName = row.values['district'] ?? '';
          final districtMatches = districts.where(
            (item) =>
                item.stateId == state.id &&
                normalizeLocationName(item.name) ==
                    normalizeLocationName(districtName),
          ).toList();

          if (districtMatches.length != 1) {
            report.add(
              'Line ${row.lineNumber}: District "$districtName" under '
              '$stateName ${districtMatches.isEmpty ? 'not found' : 'is ambiguous'} '
              'in existing Service Locations.',
            );
            continue;
          }

          final district = districtMatches.single;
          final sameNameCities = cities.where(
            (item) =>
                item.stateId == state.id &&
                normalizeLocationName(item.name) ==
                    normalizeLocationName(cityName),
          ).toList();
          final cityMatches = sameNameCities.where(
            (item) => item.districtId == district.id,
          ).toList();

          if (cityMatches.length != 1) {
            final legacyUnlinked = sameNameCities.any(
              (item) => item.districtId.trim().isEmpty,
            );
            final detail = cityMatches.isEmpty
                ? (legacyUnlinked
                    ? 'exists but is not linked to District "$districtName"'
                    : 'not found under District "$districtName"')
                : 'is ambiguous under District "$districtName"';
            report.add(
              'Line ${row.lineNumber}: City "$cityName" $detail.',
            );
            continue;
          }

          final city = cityMatches.single;
          final areaMatches = areas.where(
            (item) =>
                item.cityId == city.id &&
                normalizeLocationName(item.name) ==
                    normalizeLocationName(areaName),
          ).toList();

          if (areaMatches.length != 1) {
            report.add(
              'Line ${row.lineNumber}: Area "$areaName" under '
              '$cityName ${areaMatches.isEmpty ? 'not found' : 'is ambiguous'}.',
            );
            continue;
          }

          matched++;
        }

        report.insert(
          0,
          'LGD State/District reference matches: $lgdMatched / ${currentPreview.rows.length} rows. This uses the bundled reference snapshot only.',
        );
        report.insert(
          1,
          'Existing Service State/City/Area name matches: $matched / ${currentPreview.rows.length} rows.',
        );
        report.insert(
          2,
          'District mapping uses existing Service District records and requires each matched City to carry the matching districtId. Legacy unlinked Cities are reported, not guessed. This check never writes data.',
        );

        setDialogState(() {
          mappingReport = report;
        });
      } catch (error) {
        setDialogState(() {
          mappingReport = ['Could not read existing parent records: $error'];
        });
      } finally {
        setDialogState(() {
          checkingParents = false;
        });
      }
    }

    Future<void> pickCsvFile(StateSetter setDialogState) async {
      try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: const ['csv'],
          allowMultiple: false,
          withData: true,
        );
        if (result == null || result.files.isEmpty) return;

        final file = result.files.single;
        final bytes = file.bytes;
        if (bytes == null) {
          throw const FormatException(
            'CSV file bytes are unavailable. Please try another file.',
          );
        }

        final contents = utf8.decode(bytes, allowMalformed: false);
        controller.text = contents;
        setDialogState(() {
          sourceName = file.name;
          preview = parser.parse(contents);
          // A new file invalidates any parent-mapping report from the old preview.
          mappingReport = [];
        });
      } catch (error) {
        setDialogState(() {
          preview = LocationCsvPreview(
            headers: const [],
            rows: const [],
            fileErrors: ['Could not read selected CSV: $error'],
          );
          // Do not leave stale mapping results visible after a file-read error.
          mappingReport = [];
        });
      }
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Preview location CSV'),
          content: SizedBox(
            width: 760,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Paste CSV text below. Required columns: State, District, City, Area. '
                    'This preview does not save or activate any locations.',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => pickCsvFile(setDialogState),
                    icon: const Icon(Icons.upload_file_outlined),
                    label: const Text('Choose CSV file'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    onChanged: (_) {
                      setDialogState(() {
                        sourceName = 'Pasted CSV';
                        preview = null;
                        mappingReport = [];
                      });
                    },
                    minLines: 6,
                    maxLines: 12,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      hintText: 'State,District,City,Area\n'
                          'Uttar Pradesh,Gautam Buddha Nagar,Greater Noida,Gaur City',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (preview != null) ...[
                    SelectableText('Source: $sourceName'),
                    SelectableText(
                      'SHA-256: ${sha256.convert(utf8.encode(controller.text))}',
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text('Rows: ${preview!.rows.length}')),
                        Chip(label: Text('Valid: ${preview!.validRowCount}')),
                        Chip(label: Text('Invalid: ${preview!.invalidRowCount}')),
                      ],
                    ),
                    if (optionalSourceHeaders(preview!).isNotEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blueGrey.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Optional source metadata · preview only',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: optionalSourceHeaders(preview!)
                                  .map((header) => Chip(
                                        visualDensity: VisualDensity.compact,
                                        label: Text(header),
                                      ))
                                  .toList(),
                            ),
                            const Text(
                              'Source codes and versions are displayed as provided; they are not verified against an authoritative source.',
                            ),
                          ],
                        ),
                      ),
                    for (final error in preview!.fileErrors)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          error,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    for (final row in preview!.rows.take(20))
                      Card(
                        margin: const EdgeInsets.only(top: 6),
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            row.isValid ? Icons.check_circle_outline : Icons.error_outline,
                            color: row.isValid ? Colors.green : Colors.red,
                          ),
                          title: Text(
                            'Line ${row.lineNumber}: ${row.values['state']} · '
                            '${row.values['district']} · ${row.values['city']} · '
                            '${row.values['area']}',
                          ),
                          subtitle: Text(rowPreviewSubtitle(row)),
                        ),
                      ),
                    if (preview!.rows.length > 20)
                      Text('Showing first 20 of ${preview!.rows.length} rows.'),
                    if (preview!.isSyntacticallyValid)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _locationOrange.withValues(alpha: 0.45),
                          ),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CSV validation passed. Review carefully before importing.',
                              style: TextStyle(
                                color: _locationOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Import is restricted to an active super_admin. New records remain inactive and require separate boundary verification and service activation. Each run is audited; uncertain or partial runs must be reconciled and are never automatically retried.',
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: checkingParents
                          ? null
                          : () => checkParentMapping(setDialogState),
                      icon: checkingParents
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.account_tree_outlined),
                      label: Text(
                        checkingParents
                            ? 'Checking existing parents…'
                            : 'Check Existing Parent Mapping',
                      ),
                    ),
                    for (final line in mappingReport)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          line,
                          style: TextStyle(
                            color: line.startsWith('Existing State/City/Area name matches')
                                ? Colors.green.shade800
                                : Colors.deepOrange.shade800,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => setDialogState(() {
                controller.clear();
                preview = null;
                mappingReport = [];
                sourceName = 'Pasted CSV';
              }),
              child: const Text('Clear'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
            if (preview?.isSyntacticallyValid == true)
              FilledButton.icon(
                onPressed: () {
                  requestedImport = preview;
                  requestedImportSource = sourceName;
                  Navigator.of(dialogContext).pop();
                },
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Import Inactive Locations'),
              ),
            FilledButton.icon(
              onPressed: () => setDialogState(() {
                preview = parser.parse(controller.text);
                mappingReport = [];
              }),
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Validate CSV'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    final importPreview = requestedImport;
    if (importPreview != null) {
      await _runValidatedCsvImport(
        preview: importPreview,
        sourceName: requestedImportSource,
      );
    }
  }

  // ============================================================
  // READ-ONLY IMPORT RUN RECONCILIATION
  // ============================================================

  Future<void> _showImportRunReconciliationDialog() async {
    final runIdController = TextEditingController();
    final fingerprintController = TextEditingController();
    var busy = false;
    String? resultText;
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> runCheck({required bool reconcile}) async {
            final runId = runIdController.text.trim();
            final fingerprint = fingerprintController.text.trim();
            if (runId.isEmpty ||
                !RegExp(r'^[A-Za-z0-9_-]{1,150}
    return StreamBuilder<List<ServiceLocationImport>>(
      stream: _service.watchImports(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _emptyState(
            'Unable to load import history:\n${snapshot.error}',
          );
        }

        if (!snapshot.hasData) {
          return _loadingState();
        }

        final items = snapshot.data!
            .where(
              (item) => _matches(
                '${item.id} ${item.fileName} ${item.source} '
                '${item.status} ${item.verificationStatus}',
              ),
            )
            .toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CSV Import Preview',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Validate State, District, City and Area rows before any future import. '
                      'Preview only — no Firestore writes or activation.',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          onPressed: _showCsvPreviewDialog,
                          icon: const Icon(Icons.preview_outlined),
                          label: const Text('Paste CSV and Preview'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _locationOrange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _showImportRunReconciliationDialog,
                          icon: const Icon(Icons.rule_folder_outlined),
                          label: const Text('Inspect / Reconcile Import Run'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text('No import history records found yet.'),
              ),
            for (final item in items)
              Card(
                color: Colors.white,
                child: ListTile(
                  leading: const Icon(Icons.file_present, color: _locationOrange),
                  title: Text(item.fileName),
                  subtitle: Text(
                    'ID: ${item.id}\n'
                    'Source: ${item.source}\n'
                    'Status: ${item.status}\n'
                    'Verification: ${item.verificationStatus}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    tooltip: item.inputFingerprint.trim().isEmpty
                        ? 'Legacy record cannot be reconciled'
                        : 'Inspect and reconcile (read-only)',
                    onPressed: item.inputFingerprint.trim().isEmpty
                        ? null
                        : () => _inspectAndReconcileImportRun(item),
                    icon: const Icon(
                      Icons.fact_check_outlined,
                      color: _locationOrange,
                    ),
                  ),
                ),
              ),
          ],
        );

      },
    );
  }

  Future<void> _reconcileImportPlan(ServiceLocationImport item) async {
    if (item.id.trim().isEmpty || item.inputFingerprint.trim().isEmpty) {
      _showMessage('इस पुराने import record में reconciliation के लिए आवश्यक fingerprint नहीं है।');
      return;
    }

    try {
      final result = await _service.reconcileImportPlan(
        runId: item.id,
        inputFingerprint: item.inputFingerprint,
      );
      if (!mounted) return;

      final status = result['status']?.toString() ?? 'unknown';
      final missing = (result['missingIds'] as List?)?.map((value) => value.toString()).toList() ?? const <String>[];
      // Backend contract uses `mismatchIds`; accept the earlier UI alias too
      // so a rolling deploy never hides known reconciliation differences.
      final mismatchValues = result['mismatchIds'] ?? result['mismatchedIds'];
      final mismatched = (mismatchValues as List?)?.map((value) => value.toString()).toList() ?? const <String>[];
      final details = <String>[
        'Run ID: ${item.id}',
        'Status: $status',
        'Read-only: ${result['readOnly'] == true ? 'Yes' : 'Not confirmed'}',
        if (result['expectedRecords'] != null) 'Expected records: ${result['expectedRecords']}',
        if (result['storedRecords'] != null) 'Stored plan records: ${result['storedRecords']}',
        if (missing.isNotEmpty) 'Missing IDs: ${missing.take(20).join(', ')}',
        if (mismatched.isNotEmpty) 'Mismatched IDs: ${mismatched.take(20).join(', ')}',
        if (result['truncated'] == true) 'More differences exist; the response is truncated.',
      ];

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Import Reconciliation'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: SelectableText(details.join('\n')),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) await _showError(error);
    }
  }

  // ============================================================
  // BOUNDARY MANAGEMENT
  // ============================================================

  Future<void> _manageBoundary({
    required String locationId,
    required String locationName,
    required String locationType,
  }) async {
    try {
      final boundaries = await _boundaryService
          .watchForLocation(
            locationId,
            locationType: locationType,
          )
          .first;

      if (!mounted) return;

      final verified = boundaries
          .where((boundary) => boundary.isVerified)
          .toList();

      // When more than one record exists, let the administrator explicitly
      // choose which boundary to inspect/edit/review instead of silently
      // selecting the first record by status.
      final existing = boundaries.length <= 1
          ? (boundaries.isEmpty ? null : boundaries.single)
          : await _chooseBoundaryRecord(
              locationName: locationName,
              boundaries: boundaries,
            );

      // A null result means the chooser was cancelled. For a location with
      // no records, null is the intentional "create first boundary" state.
      if (boundaries.length > 1 && existing == null) return;

      final initialPoints = existing == null
          ? <LatLng>[]
          : existing.points
              .map(
                (point) => LatLng(
                  point.latitude,
                  point.longitude,
                ),
              )
              .toList();

      await _showBoundaryEditor(
        locationId: locationId,
        locationName: locationName,
        locationType: locationType,
        existingBoundary: existing,
        initialPoints: initialPoints,
        hasVerifiedBoundary: verified.isNotEmpty,
      );
    } catch (error) {
      await _showError(error);
    }
  }

  Future<ServiceLocationBoundary?> _chooseBoundaryRecord({
    required String locationName,
    required List<ServiceLocationBoundary> boundaries,
  }) {
    String statusLabel(BoundaryVerificationStatus status) {
      switch (status) {
        case BoundaryVerificationStatus.pending:
          return 'Pending review';
        case BoundaryVerificationStatus.verified:
          return 'Verified · read-only';
        case BoundaryVerificationStatus.rejected:
          return 'Rejected · can edit/resubmit';
        case BoundaryVerificationStatus.notAvailable:
          return 'Status unavailable';
      }
    }

    String dateLabel(DateTime value) {
      final local = value.toLocal();
      String two(int n) => n.toString().padLeft(2, '0');
      return '${local.year}-${two(local.month)}-${two(local.day)} '
          '${two(local.hour)}:${two(local.minute)}';
    }

    final ordered = sortBoundariesForChooser(boundaries);

    return showDialog<ServiceLocationBoundary>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Choose Boundary · $locationName'),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'एक रिकॉर्ड चुनें। Verified रिकॉर्ड read-only है; '
                  'पुराना Verified रिकॉर्ड हटाया या बदला नहीं जाएगा।',
                ),
                const SizedBox(height: 10),
                for (final boundary in ordered)
                  Card(
                    child: ListTile(
                      leading: Icon(
                        boundary.isVerified
                            ? Icons.verified_outlined
                            : boundary.verificationStatus ==
                                    BoundaryVerificationStatus.rejected
                                ? Icons.error_outline
                                : Icons.map_outlined,
                      ),
                      title: Text(statusLabel(boundary.verificationStatus)),
                      subtitle: Text(
                        'Updated: ${dateLabel(boundary.updatedAt)}\n'
                        'Source: ${boundary.sourceName.isEmpty ? "Not specified" : boundary.sourceName}\n'
                        'ID: ${boundary.id}',
                      ),
                      isThreeLine: true,
                      onTap: () => Navigator.of(dialogContext).pop(boundary),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBoundaryEditor({
    required String locationId,
    required String locationName,
    required String locationType,
    required ServiceLocationBoundary? existingBoundary,
    required List<LatLng> initialPoints,
    bool hasVerifiedBoundary = false,
  }) async {
    final sourceNameController = TextEditingController(
      text: existingBoundary?.sourceName ?? '',
    );

    final sourceReferenceController = TextEditingController(
      text: existingBoundary?.sourceReference ?? '',
    );

    final notesController = TextEditingController();

    var sourceType = existingBoundary?.sourceType ??
        BoundarySourceType.manuallyDrawn;

    var currentPoints = List<LatLng>.of(initialPoints);
    var isSaving = false;

    final isVerified =
        existingBoundary?.verificationStatus ==
            BoundaryVerificationStatus.verified;

    final isRejected =
        existingBoundary?.verificationStatus ==
            BoundaryVerificationStatus.rejected;

    final isPending =
        existingBoundary?.verificationStatus ==
            BoundaryVerificationStatus.pending;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> saveBoundary(
                List<GeoPoint> points,
              ) async {
                if (isVerified) {
                  _showMessage(
                    'Verified Boundary read-only है।',
                  );
                  return;
                }

                if (isSaving) return;

                final sourceName =
                    sourceNameController.text.trim();

                final sourceReference =
                    sourceReferenceController.text.trim();

                if (sourceName.isEmpty ||
                    sourceReference.isEmpty) {
                  _showMessage(
                    'Source name और source reference भरें।',
                  );
                  return;
                }

                setDialogState(() => isSaving = true);

                try {
                  final now = DateTime.now();

                  final boundary = ServiceLocationBoundary(
                    id: existingBoundary?.id ?? '',
                    locationId: locationId,
                    locationType: locationType,
                    points: List<GeoPoint>.of(points),
                    sourceType: sourceType,
                    sourceName: sourceName,
                    sourceReference: sourceReference,
                    verificationStatus:
                        BoundaryVerificationStatus.pending,
                    verifiedBy: null,
                    verifiedAt: null,
                    verificationNotes: null,
                    createdAt:
                        existingBoundary?.createdAt ?? now,
                    updatedAt: now,
                  );

                  final errors = boundary.validate();

                  if (errors.isNotEmpty) {
                    throw ArgumentError(errors.join('\n'));
                  }

                  await _boundaryService.saveDraft(boundary);

                  if (!dialogContext.mounted) return;

                  Navigator.of(dialogContext).pop();

                  _showMessage(
                    isRejected
                        ? 'Boundary के बदलाव सेव हो गए और Boundary Pending Review में भेज दी गई।'
                        : isPending
                            ? 'Boundary अपडेट हो गई। इसका status Pending Review है।'
                            : 'Boundary सेव हो गई और Pending Review में भेज दी गई।',
                  );
                } catch (error) {
                  if (dialogContext.mounted) {
                    setDialogState(() => isSaving = false);
                  }

                  await _showError(error);
                }
              }

              return AlertDialog(
                title: Text('Manage Boundary · $locationName'),
                content: SizedBox(
                  width: 900,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Location type: $locationType',
                          style: const TextStyle(
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),

                        _boundaryStatusBanner(existingBoundary),

                        if (hasVerifiedBoundary && !isVerified) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _locationOrange.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _locationOrange.withValues(alpha: 0.35),
                              ),
                            ),
                            child: const Text(
                              'इस location की पुरानी Verified Boundary सुरक्षित है। '
                              'यह अलग replacement record है। Firebase replacement '
                              'verify करने से पहले location का inactive होना जरूरी है; '
                              'यह स्क्रीन service को अपने-आप deactivate नहीं करेगी।',
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),

                        if (isRejected) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              'Previous rejection reason:\n'
                              '${existingBoundary?.verificationNotes?.trim().isNotEmpty == true ? existingBoundary!.verificationNotes : "No rejection reason recorded."}',
                              style: const TextStyle(
                                color: Colors.red,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        if (!isVerified) ...[
                          DropdownButtonFormField<BoundarySourceType>(
                            initialValue: sourceType,
                            decoration: const InputDecoration(
                              labelText: 'Boundary source type',
                              border: OutlineInputBorder(),
                            ),
                            items: BoundarySourceType.values
                                .map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(
                                      _sourceTypeLabel(type),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;

                              setDialogState(() {
                                sourceType = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: sourceNameController,
                            decoration: const InputDecoration(
                              labelText: 'Source name *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: sourceReferenceController,
                            decoration: const InputDecoration(
                              labelText: 'Source reference *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Save करने पर Boundary Pending Review में जाएगी।',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        ServiceBoundaryEditor(
                          initialPoints: currentPoints,
                          initialCenter: _defaultMapCenter,
                          initialZoom: 12,
                          readOnly: isVerified,
                          onBoundaryChanged: (points) {
                            currentPoints = List<LatLng>.of(points);
                          },
                          onSaveRequested: saveBoundary,
                        ),

                        if (existingBoundary != null) ...[
                          const SizedBox(height: 16),
                          _boundaryDetails(existingBoundary),
                        ],
                      ],
                    ),
                  ),
                ),
                actions: [
                  if (isRejected &&
                      existingBoundary != null &&
                      existingBoundary.id.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              try {
                                final latest =
                                    await _boundaryService.getById(
                                  existingBoundary.id,
                                );

                                if (latest == null) {
                                  throw StateError(
                                    'Boundary नहीं मिली।',
                                  );
                                }

                                if (latest.verificationStatus !=
                                    BoundaryVerificationStatus.rejected) {
                                  throw StateError(
                                    'Boundary अब Rejected status में नहीं है।',
                                  );
                                }

                                if (!dialogContext.mounted) return;

                                final confirmed =
                                    await _confirmResubmit(
                                  locationName,
                                );

                                if (confirmed != true) return;

                                await _boundaryService
                                    .requestVerification(latest.id);

                                if (!dialogContext.mounted) return;

                                Navigator.of(dialogContext).pop();

                                _showMessage(
                                  'Boundary Review के लिए भेज दी गई।',
                                );
                              } catch (error) {
                                await _showError(error);
                              }
                            },
                      icon: const Icon(Icons.send_outlined),
                      label: const Text('Resubmit for Review'),
                    ),

                  if (isPending && existingBoundary != null)
                    TextButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              try {
                                final latest =
                                    await _boundaryService.getById(
                                  existingBoundary.id,
                                );

                                if (latest == null ||
                                    latest.verificationStatus !=
                                        BoundaryVerificationStatus.pending) {
                                  throw StateError(
                                    'केवल Pending Boundary को Reject किया जा सकता है।',
                                  );
                                }

                                if (!dialogContext.mounted) return;

                                final reason =
                                    await _askForReviewNotes(
                                  approve: false,
                                );

                                if (reason == null) return;

                                await _boundaryService.rejectBoundary(
                                  boundaryId: latest.id,
                                  reason: reason,
                                );

                                if (!dialogContext.mounted) return;

                                Navigator.of(dialogContext).pop();

                                _showMessage(
                                  'Boundary Reject कर दी गई।',
                                );
                              } catch (error) {
                                await _showError(error);
                              }
                            },
                      icon: const Icon(
                        Icons.close,
                        color: Colors.red,
                      ),
                      label: const Text(
                        'Reject',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),

                  if (isPending && existingBoundary != null)
                    FilledButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              try {
                                final latest =
                                    await _boundaryService.getById(
                                  existingBoundary.id,
                                );

                                if (latest == null ||
                                    latest.verificationStatus !=
                                        BoundaryVerificationStatus.pending) {
                                  throw StateError(
                                    'केवल Pending Boundary Verify हो सकती है।',
                                  );
                                }

                                final errors = latest.validate();

                                if (errors.isNotEmpty) {
                                  throw StateError(
                                    errors.join('\n'),
                                  );
                                }

                                if (!dialogContext.mounted) return;

                                final notes =
                                    await _askForReviewNotes(
                                  approve: true,
                                );

                                if (notes == null) return;

                                await _boundaryService.markVerified(
                                  boundaryId: latest.id,
                                  verificationNotes: notes,
                                );

                                if (!dialogContext.mounted) return;

                                Navigator.of(dialogContext).pop();

                                _showMessage(
                                  'Boundary Verified हो गई। Service activation अलग से होगी।',
                                );
                              } catch (error) {
                                await _showError(error);
                              }
                            },
                      icon: const Icon(Icons.verified_outlined),
                      label: const Text('Verify'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),

                  if (isVerified)
                    OutlinedButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              Navigator.of(dialogContext).pop();
                              await Future<void>.delayed(Duration.zero);
                              if (!mounted) return;
                              await _showBoundaryEditor(
                                locationId: locationId,
                                locationName: locationName,
                                locationType: locationType,
                                existingBoundary: null,
                                initialPoints: const <LatLng>[],
                              );
                            },
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: const Text('Create replacement boundary'),
                    ),

                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Close'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      sourceNameController.dispose();
      sourceReferenceController.dispose();
      notesController.dispose();
    }
  }

  Future<bool?> _confirmResubmit(String locationName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resubmit Boundary?'),
        content: Text(
          '$locationName की Boundary Review में भेजी जाएगी। '
          'क्या आपने polygon और source details जाँच लिए हैं?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Resubmit'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOUNDARY STATUS
  // ============================================================

  Widget _boundaryStatusBanner(
    ServiceLocationBoundary? boundary,
  ) {
    if (boundary == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'नई Boundary बनाएँ और source details भरें। '
          'Save करने पर वह Pending Review में जाएगी।',
        ),
      );
    }

    final status = boundary.verificationStatus;

    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;

    switch (status) {
      case BoundaryVerificationStatus.notAvailable:
        statusColor = Colors.grey;
        statusLabel = 'Not available';
        statusIcon = Icons.help_outline;
        break;

      case BoundaryVerificationStatus.pending:
        statusColor = Colors.orange;
        statusLabel = 'Pending review';
        statusIcon = Icons.hourglass_top;
        break;

      case BoundaryVerificationStatus.verified:
        statusColor = Colors.green;
        statusLabel = 'Verified';
        statusIcon = Icons.verified;
        break;

      case BoundaryVerificationStatus.rejected:
        statusColor = Colors.red;
        statusLabel = 'Rejected';
        statusIcon = Icons.cancel_outlined;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Boundary ID: ${boundary.id}'),
          Text('Vertices: ${boundary.points.length}'),
          Text('Source: ${boundary.sourceName}'),
          if (boundary.verificationNotes != null &&
              boundary.verificationNotes!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              status == BoundaryVerificationStatus.rejected
                  ? 'Rejection reason: ${boundary.verificationNotes}'
                  : 'Review notes: ${boundary.verificationNotes}',
            ),
          ],
          if (boundary.verifiedBy != null)
            Text('Reviewer UID: ${boundary.verifiedBy}'),
          if (boundary.verifiedAt != null)
            Text(
              'Reviewed: ${boundary.verifiedAt!.toLocal()}',
            ),
          if (boundary.isVerified) ...[
            const SizedBox(height: 8),
            const Text(
              'Verified Boundary read-only है।',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _boundaryDetails(
    ServiceLocationBoundary boundary,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Boundary review information',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Source type: ${_sourceTypeLabel(boundary.sourceType)}',
          ),
          Text('Source name: ${boundary.sourceName}'),
          Text('Source reference: ${boundary.sourceReference}'),
          Text('Status: ${boundary.verificationStatus.name}'),
          if (boundary.verificationNotes != null &&
              boundary.verificationNotes!.isNotEmpty)
            Text('Notes: ${boundary.verificationNotes}'),
        ],
      ),
    );
  }

  Future<String?> _askForReviewNotes({
    required bool approve,
  }) async {
    final controller = TextEditingController();

    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            approve ? 'Verify Boundary' : 'Reject Boundary',
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  approve
                      ? 'Source और polygon जाँचने के बाद verification notes लिखें।'
                      : 'Boundary Reject करने का स्पष्ट कारण लिखें।',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: approve
                        ? 'Verification notes *'
                        : 'Rejection reason *',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: approve ? Colors.green : Colors.red,
              ),
              onPressed: () {
                final notes = controller.text.trim();

                if (notes.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'कृपया टिप्पणी या कारण लिखें।',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext, notes);
              },
              child: Text(approve ? 'Verify' : 'Reject'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  String _sourceTypeLabel(BoundarySourceType type) {
    switch (type) {
      case BoundarySourceType.governmentGis:
        return 'Government GIS';
      case BoundarySourceType.governmentCadastralMap:
        return 'Government cadastral map';
      case BoundarySourceType.importedGeoJson:
        return 'Imported GeoJSON';
      case BoundarySourceType.manuallyDrawn:
        return 'Manually drawn';
    }
  }

  // ============================================================
  // SHARED WIDGETS
  // ============================================================

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: _locationOrange,
          ),
        ),
      ),
    );
  }

  Widget _locationCard({
    required String title,
    required String subtitle,
    required bool active,
    required IconData icon,
    required ValueChanged<bool> onToggle,
    VoidCallback? onManageBoundary,
  }) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              _locationOrange.withValues(alpha: 0.12),
          child: Icon(icon, color: _locationOrange),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        isThreeLine: subtitle.contains('\n'),
        trailing: SizedBox(
          width: onManageBoundary == null ? 65 : 190,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onManageBoundary != null)
                IconButton(
                  tooltip: 'Manage Boundary',
                  onPressed: onManageBoundary,
                  icon: const Icon(
                    Icons.edit_location_alt_outlined,
                    color: _locationOrange,
                  ),
                ),
              Switch(
                value: active,
                activeThumbColor: _locationOrange,
                onChanged: onToggle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ADD LOCATION
  // ============================================================

  Future<void> _showAddLocationDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddLocationDialog(
        service: _service,
        onSaved: (tab) {
          if (!mounted) return;

          setState(() => _selectedTab = tab);
          _showMessage('Location saved successfully.');
        },
      ),
    );
  }
}).hasMatch(runId)) {
              setDialogState(() {
                errorText = 'Enter a valid import run ID.';
                resultText = null;
              });
              return;
            }
            if (!RegExp(r'^sha256:[0-9a-f]{64}
    return StreamBuilder<List<ServiceLocationImport>>(
      stream: _service.watchImports(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _emptyState(
            'Unable to load import history:\n${snapshot.error}',
          );
        }

        if (!snapshot.hasData) {
          return _loadingState();
        }

        final items = snapshot.data!
            .where(
              (item) => _matches(
                '${item.id} ${item.fileName} ${item.source} '
                '${item.status} ${item.verificationStatus}',
              ),
            )
            .toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CSV Import Preview',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Validate State, District, City and Area rows before any future import. '
                      'Preview only — no Firestore writes or activation.',
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed: _showCsvPreviewDialog,
                        icon: const Icon(Icons.preview_outlined),
                        label: const Text('Paste CSV and Preview'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _locationOrange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text('No import history records found yet.'),
              ),
            for (final item in items)
              Card(
                color: Colors.white,
                child: ListTile(
                  leading: const Icon(Icons.file_present, color: _locationOrange),
                  title: Text(item.fileName),
                  subtitle: Text(
                    'ID: ${item.id}\n'
                    'Source: ${item.source}\n'
                    'Status: ${item.status}\n'
                    'Verification: ${item.verificationStatus}',
                  ),
                  isThreeLine: true,
                  trailing: item.inputFingerprint.trim().isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Reconcile import plan (read-only)',
                          icon: const Icon(Icons.fact_check_outlined),
                          onPressed: () => _reconcileImportPlan(item),
                        ),
                ),
              ),
          ],
        );

      },
    );
  }

  // ============================================================
  // BOUNDARY MANAGEMENT
  // ============================================================

  Future<void> _manageBoundary({
    required String locationId,
    required String locationName,
    required String locationType,
  }) async {
    try {
      final boundaries = await _boundaryService
          .watchForLocation(
            locationId,
            locationType: locationType,
          )
          .first;

      if (!mounted) return;

      final verified = boundaries
          .where((boundary) => boundary.isVerified)
          .toList();

      // When more than one record exists, let the administrator explicitly
      // choose which boundary to inspect/edit/review instead of silently
      // selecting the first record by status.
      final existing = boundaries.length <= 1
          ? (boundaries.isEmpty ? null : boundaries.single)
          : await _chooseBoundaryRecord(
              locationName: locationName,
              boundaries: boundaries,
            );

      // A null result means the chooser was cancelled. For a location with
      // no records, null is the intentional "create first boundary" state.
      if (boundaries.length > 1 && existing == null) return;

      final initialPoints = existing == null
          ? <LatLng>[]
          : existing.points
              .map(
                (point) => LatLng(
                  point.latitude,
                  point.longitude,
                ),
              )
              .toList();

      await _showBoundaryEditor(
        locationId: locationId,
        locationName: locationName,
        locationType: locationType,
        existingBoundary: existing,
        initialPoints: initialPoints,
        hasVerifiedBoundary: verified.isNotEmpty,
      );
    } catch (error) {
      await _showError(error);
    }
  }

  Future<ServiceLocationBoundary?> _chooseBoundaryRecord({
    required String locationName,
    required List<ServiceLocationBoundary> boundaries,
  }) {
    String statusLabel(BoundaryVerificationStatus status) {
      switch (status) {
        case BoundaryVerificationStatus.pending:
          return 'Pending review';
        case BoundaryVerificationStatus.verified:
          return 'Verified · read-only';
        case BoundaryVerificationStatus.rejected:
          return 'Rejected · can edit/resubmit';
        case BoundaryVerificationStatus.notAvailable:
          return 'Status unavailable';
      }
    }

    String dateLabel(DateTime value) {
      final local = value.toLocal();
      String two(int n) => n.toString().padLeft(2, '0');
      return '${local.year}-${two(local.month)}-${two(local.day)} '
          '${two(local.hour)}:${two(local.minute)}';
    }

    final ordered = sortBoundariesForChooser(boundaries);

    return showDialog<ServiceLocationBoundary>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Choose Boundary · $locationName'),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'एक रिकॉर्ड चुनें। Verified रिकॉर्ड read-only है; '
                  'पुराना Verified रिकॉर्ड हटाया या बदला नहीं जाएगा।',
                ),
                const SizedBox(height: 10),
                for (final boundary in ordered)
                  Card(
                    child: ListTile(
                      leading: Icon(
                        boundary.isVerified
                            ? Icons.verified_outlined
                            : boundary.verificationStatus ==
                                    BoundaryVerificationStatus.rejected
                                ? Icons.error_outline
                                : Icons.map_outlined,
                      ),
                      title: Text(statusLabel(boundary.verificationStatus)),
                      subtitle: Text(
                        'Updated: ${dateLabel(boundary.updatedAt)}\n'
                        'Source: ${boundary.sourceName.isEmpty ? "Not specified" : boundary.sourceName}\n'
                        'ID: ${boundary.id}',
                      ),
                      isThreeLine: true,
                      onTap: () => Navigator.of(dialogContext).pop(boundary),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBoundaryEditor({
    required String locationId,
    required String locationName,
    required String locationType,
    required ServiceLocationBoundary? existingBoundary,
    required List<LatLng> initialPoints,
    bool hasVerifiedBoundary = false,
  }) async {
    final sourceNameController = TextEditingController(
      text: existingBoundary?.sourceName ?? '',
    );

    final sourceReferenceController = TextEditingController(
      text: existingBoundary?.sourceReference ?? '',
    );

    final notesController = TextEditingController();

    var sourceType = existingBoundary?.sourceType ??
        BoundarySourceType.manuallyDrawn;

    var currentPoints = List<LatLng>.of(initialPoints);
    var isSaving = false;

    final isVerified =
        existingBoundary?.verificationStatus ==
            BoundaryVerificationStatus.verified;

    final isRejected =
        existingBoundary?.verificationStatus ==
            BoundaryVerificationStatus.rejected;

    final isPending =
        existingBoundary?.verificationStatus ==
            BoundaryVerificationStatus.pending;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> saveBoundary(
                List<GeoPoint> points,
              ) async {
                if (isVerified) {
                  _showMessage(
                    'Verified Boundary read-only है।',
                  );
                  return;
                }

                if (isSaving) return;

                final sourceName =
                    sourceNameController.text.trim();

                final sourceReference =
                    sourceReferenceController.text.trim();

                if (sourceName.isEmpty ||
                    sourceReference.isEmpty) {
                  _showMessage(
                    'Source name और source reference भरें।',
                  );
                  return;
                }

                setDialogState(() => isSaving = true);

                try {
                  final now = DateTime.now();

                  final boundary = ServiceLocationBoundary(
                    id: existingBoundary?.id ?? '',
                    locationId: locationId,
                    locationType: locationType,
                    points: List<GeoPoint>.of(points),
                    sourceType: sourceType,
                    sourceName: sourceName,
                    sourceReference: sourceReference,
                    verificationStatus:
                        BoundaryVerificationStatus.pending,
                    verifiedBy: null,
                    verifiedAt: null,
                    verificationNotes: null,
                    createdAt:
                        existingBoundary?.createdAt ?? now,
                    updatedAt: now,
                  );

                  final errors = boundary.validate();

                  if (errors.isNotEmpty) {
                    throw ArgumentError(errors.join('\n'));
                  }

                  await _boundaryService.saveDraft(boundary);

                  if (!dialogContext.mounted) return;

                  Navigator.of(dialogContext).pop();

                  _showMessage(
                    isRejected
                        ? 'Boundary के बदलाव सेव हो गए और Boundary Pending Review में भेज दी गई।'
                        : isPending
                            ? 'Boundary अपडेट हो गई। इसका status Pending Review है।'
                            : 'Boundary सेव हो गई और Pending Review में भेज दी गई।',
                  );
                } catch (error) {
                  if (dialogContext.mounted) {
                    setDialogState(() => isSaving = false);
                  }

                  await _showError(error);
                }
              }

              return AlertDialog(
                title: Text('Manage Boundary · $locationName'),
                content: SizedBox(
                  width: 900,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Location type: $locationType',
                          style: const TextStyle(
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),

                        _boundaryStatusBanner(existingBoundary),

                        if (hasVerifiedBoundary && !isVerified) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _locationOrange.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _locationOrange.withValues(alpha: 0.35),
                              ),
                            ),
                            child: const Text(
                              'इस location की पुरानी Verified Boundary सुरक्षित है। '
                              'यह अलग replacement record है। Firebase replacement '
                              'verify करने से पहले location का inactive होना जरूरी है; '
                              'यह स्क्रीन service को अपने-आप deactivate नहीं करेगी।',
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),

                        if (isRejected) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              'Previous rejection reason:\n'
                              '${existingBoundary?.verificationNotes?.trim().isNotEmpty == true ? existingBoundary!.verificationNotes : "No rejection reason recorded."}',
                              style: const TextStyle(
                                color: Colors.red,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        if (!isVerified) ...[
                          DropdownButtonFormField<BoundarySourceType>(
                            initialValue: sourceType,
                            decoration: const InputDecoration(
                              labelText: 'Boundary source type',
                              border: OutlineInputBorder(),
                            ),
                            items: BoundarySourceType.values
                                .map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(
                                      _sourceTypeLabel(type),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;

                              setDialogState(() {
                                sourceType = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: sourceNameController,
                            decoration: const InputDecoration(
                              labelText: 'Source name *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: sourceReferenceController,
                            decoration: const InputDecoration(
                              labelText: 'Source reference *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Save करने पर Boundary Pending Review में जाएगी।',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        ServiceBoundaryEditor(
                          initialPoints: currentPoints,
                          initialCenter: _defaultMapCenter,
                          initialZoom: 12,
                          readOnly: isVerified,
                          onBoundaryChanged: (points) {
                            currentPoints = List<LatLng>.of(points);
                          },
                          onSaveRequested: saveBoundary,
                        ),

                        if (existingBoundary != null) ...[
                          const SizedBox(height: 16),
                          _boundaryDetails(existingBoundary),
                        ],
                      ],
                    ),
                  ),
                ),
                actions: [
                  if (isRejected &&
                      existingBoundary != null &&
                      existingBoundary.id.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              try {
                                final latest =
                                    await _boundaryService.getById(
                                  existingBoundary.id,
                                );

                                if (latest == null) {
                                  throw StateError(
                                    'Boundary नहीं मिली।',
                                  );
                                }

                                if (latest.verificationStatus !=
                                    BoundaryVerificationStatus.rejected) {
                                  throw StateError(
                                    'Boundary अब Rejected status में नहीं है।',
                                  );
                                }

                                if (!dialogContext.mounted) return;

                                final confirmed =
                                    await _confirmResubmit(
                                  locationName,
                                );

                                if (confirmed != true) return;

                                await _boundaryService
                                    .requestVerification(latest.id);

                                if (!dialogContext.mounted) return;

                                Navigator.of(dialogContext).pop();

                                _showMessage(
                                  'Boundary Review के लिए भेज दी गई।',
                                );
                              } catch (error) {
                                await _showError(error);
                              }
                            },
                      icon: const Icon(Icons.send_outlined),
                      label: const Text('Resubmit for Review'),
                    ),

                  if (isPending && existingBoundary != null)
                    TextButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              try {
                                final latest =
                                    await _boundaryService.getById(
                                  existingBoundary.id,
                                );

                                if (latest == null ||
                                    latest.verificationStatus !=
                                        BoundaryVerificationStatus.pending) {
                                  throw StateError(
                                    'केवल Pending Boundary को Reject किया जा सकता है।',
                                  );
                                }

                                if (!dialogContext.mounted) return;

                                final reason =
                                    await _askForReviewNotes(
                                  approve: false,
                                );

                                if (reason == null) return;

                                await _boundaryService.rejectBoundary(
                                  boundaryId: latest.id,
                                  reason: reason,
                                );

                                if (!dialogContext.mounted) return;

                                Navigator.of(dialogContext).pop();

                                _showMessage(
                                  'Boundary Reject कर दी गई।',
                                );
                              } catch (error) {
                                await _showError(error);
                              }
                            },
                      icon: const Icon(
                        Icons.close,
                        color: Colors.red,
                      ),
                      label: const Text(
                        'Reject',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),

                  if (isPending && existingBoundary != null)
                    FilledButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              try {
                                final latest =
                                    await _boundaryService.getById(
                                  existingBoundary.id,
                                );

                                if (latest == null ||
                                    latest.verificationStatus !=
                                        BoundaryVerificationStatus.pending) {
                                  throw StateError(
                                    'केवल Pending Boundary Verify हो सकती है।',
                                  );
                                }

                                final errors = latest.validate();

                                if (errors.isNotEmpty) {
                                  throw StateError(
                                    errors.join('\n'),
                                  );
                                }

                                if (!dialogContext.mounted) return;

                                final notes =
                                    await _askForReviewNotes(
                                  approve: true,
                                );

                                if (notes == null) return;

                                await _boundaryService.markVerified(
                                  boundaryId: latest.id,
                                  verificationNotes: notes,
                                );

                                if (!dialogContext.mounted) return;

                                Navigator.of(dialogContext).pop();

                                _showMessage(
                                  'Boundary Verified हो गई। Service activation अलग से होगी।',
                                );
                              } catch (error) {
                                await _showError(error);
                              }
                            },
                      icon: const Icon(Icons.verified_outlined),
                      label: const Text('Verify'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),

                  if (isVerified)
                    OutlinedButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              Navigator.of(dialogContext).pop();
                              await Future<void>.delayed(Duration.zero);
                              if (!mounted) return;
                              await _showBoundaryEditor(
                                locationId: locationId,
                                locationName: locationName,
                                locationType: locationType,
                                existingBoundary: null,
                                initialPoints: const <LatLng>[],
                              );
                            },
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: const Text('Create replacement boundary'),
                    ),

                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Close'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      sourceNameController.dispose();
      sourceReferenceController.dispose();
      notesController.dispose();
    }
  }

  Future<bool?> _confirmResubmit(String locationName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resubmit Boundary?'),
        content: Text(
          '$locationName की Boundary Review में भेजी जाएगी। '
          'क्या आपने polygon और source details जाँच लिए हैं?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Resubmit'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOUNDARY STATUS
  // ============================================================

  Widget _boundaryStatusBanner(
    ServiceLocationBoundary? boundary,
  ) {
    if (boundary == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'नई Boundary बनाएँ और source details भरें। '
          'Save करने पर वह Pending Review में जाएगी।',
        ),
      );
    }

    final status = boundary.verificationStatus;

    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;

    switch (status) {
      case BoundaryVerificationStatus.notAvailable:
        statusColor = Colors.grey;
        statusLabel = 'Not available';
        statusIcon = Icons.help_outline;
        break;

      case BoundaryVerificationStatus.pending:
        statusColor = Colors.orange;
        statusLabel = 'Pending review';
        statusIcon = Icons.hourglass_top;
        break;

      case BoundaryVerificationStatus.verified:
        statusColor = Colors.green;
        statusLabel = 'Verified';
        statusIcon = Icons.verified;
        break;

      case BoundaryVerificationStatus.rejected:
        statusColor = Colors.red;
        statusLabel = 'Rejected';
        statusIcon = Icons.cancel_outlined;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Boundary ID: ${boundary.id}'),
          Text('Vertices: ${boundary.points.length}'),
          Text('Source: ${boundary.sourceName}'),
          if (boundary.verificationNotes != null &&
              boundary.verificationNotes!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              status == BoundaryVerificationStatus.rejected
                  ? 'Rejection reason: ${boundary.verificationNotes}'
                  : 'Review notes: ${boundary.verificationNotes}',
            ),
          ],
          if (boundary.verifiedBy != null)
            Text('Reviewer UID: ${boundary.verifiedBy}'),
          if (boundary.verifiedAt != null)
            Text(
              'Reviewed: ${boundary.verifiedAt!.toLocal()}',
            ),
          if (boundary.isVerified) ...[
            const SizedBox(height: 8),
            const Text(
              'Verified Boundary read-only है।',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _boundaryDetails(
    ServiceLocationBoundary boundary,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Boundary review information',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Source type: ${_sourceTypeLabel(boundary.sourceType)}',
          ),
          Text('Source name: ${boundary.sourceName}'),
          Text('Source reference: ${boundary.sourceReference}'),
          Text('Status: ${boundary.verificationStatus.name}'),
          if (boundary.verificationNotes != null &&
              boundary.verificationNotes!.isNotEmpty)
            Text('Notes: ${boundary.verificationNotes}'),
        ],
      ),
    );
  }

  Future<String?> _askForReviewNotes({
    required bool approve,
  }) async {
    final controller = TextEditingController();

    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            approve ? 'Verify Boundary' : 'Reject Boundary',
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  approve
                      ? 'Source और polygon जाँचने के बाद verification notes लिखें।'
                      : 'Boundary Reject करने का स्पष्ट कारण लिखें।',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: approve
                        ? 'Verification notes *'
                        : 'Rejection reason *',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: approve ? Colors.green : Colors.red,
              ),
              onPressed: () {
                final notes = controller.text.trim();

                if (notes.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'कृपया टिप्पणी या कारण लिखें।',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext, notes);
              },
              child: Text(approve ? 'Verify' : 'Reject'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  String _sourceTypeLabel(BoundarySourceType type) {
    switch (type) {
      case BoundarySourceType.governmentGis:
        return 'Government GIS';
      case BoundarySourceType.governmentCadastralMap:
        return 'Government cadastral map';
      case BoundarySourceType.importedGeoJson:
        return 'Imported GeoJSON';
      case BoundarySourceType.manuallyDrawn:
        return 'Manually drawn';
    }
  }

  // ============================================================
  // SHARED WIDGETS
  // ============================================================

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: _locationOrange,
          ),
        ),
      ),
    );
  }

  Widget _locationCard({
    required String title,
    required String subtitle,
    required bool active,
    required IconData icon,
    required ValueChanged<bool> onToggle,
    VoidCallback? onManageBoundary,
  }) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              _locationOrange.withValues(alpha: 0.12),
          child: Icon(icon, color: _locationOrange),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        isThreeLine: subtitle.contains('\n'),
        trailing: SizedBox(
          width: onManageBoundary == null ? 65 : 190,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onManageBoundary != null)
                IconButton(
                  tooltip: 'Manage Boundary',
                  onPressed: onManageBoundary,
                  icon: const Icon(
                    Icons.edit_location_alt_outlined,
                    color: _locationOrange,
                  ),
                ),
              Switch(
                value: active,
                activeThumbColor: _locationOrange,
                onChanged: onToggle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ADD LOCATION
  // ============================================================

  Future<void> _showAddLocationDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddLocationDialog(
        service: _service,
        onSaved: (tab) {
          if (!mounted) return;

          setState(() => _selectedTab = tab);
          _showMessage('Location saved successfully.');
        },
      ),
    );
  }
}).hasMatch(fingerprint)) {
              setDialogState(() {
                errorText = 'Enter the full SHA-256 fingerprint (sha256: followed by 64 lowercase hex characters).';
                resultText = null;
              });
              return;
            }

            setDialogState(() {
              busy = true;
              errorText = null;
              resultText = null;
            });
            try {
              final data = reconcile
                  ? await _service.reconcileImportPlan(
                      runId: runId,
                      inputFingerprint: fingerprint,
                    )
                  : await _service.inspectImportRun(
                      runId: runId,
                      inputFingerprint: fingerprint,
                    );
              if (!dialogContext.mounted) return;
              setDialogState(() {
                resultText = const JsonEncoder.withIndent('  ').convert(data);
              });
            } catch (error) {
              if (!dialogContext.mounted) return;
              setDialogState(() {
                errorText = error.toString();
              });
            } finally {
              if (dialogContext.mounted) {
                setDialogState(() {
                  busy = false;
                });
              }
            }
          }

          return AlertDialog(
            title: const Text('Import Run Reconciliation'),
            content: SizedBox(
              width: 680,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Read-only diagnostic. It does not resume, repair, finalize, or write any location records. Use the exact run ID and input fingerprint from the original import attempt.',
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: runIdController,
                      enabled: !busy,
                      decoration: const InputDecoration(
                        labelText: 'Import run ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: fingerprintController,
                      enabled: !busy,
                      minLines: 1,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Input fingerprint',
                        hintText: 'sha256:...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      SelectableText(
                        errorText!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    if (resultText != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _locationBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: SelectableText(
                          resultText!,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'A matching result confirms the stored plan and current hierarchy comparison only. It does not approve activation or prove that a production release is complete.',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: busy
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: const Text('Close'),
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : () => runCheck(reconcile: false),
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Inspect Run'),
              ),
              FilledButton.icon(
                onPressed: busy ? null : () => runCheck(reconcile: true),
                icon: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.rule_folder_outlined),
                label: const Text('Reconcile Plan'),
                style: FilledButton.styleFrom(
                  backgroundColor: _locationOrange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );

    runIdController.dispose();
    fingerprintController.dispose();
  }

  // ============================================================
  // IMPORT HISTORY
  // ============================================================

  Future<void> _inspectAndReconcileImportRun(
    ServiceLocationImport item,
  ) async {
    final fingerprint = item.inputFingerprint.trim();
    if (fingerprint.isEmpty) {
      await _showError(StateError(
        'This is a legacy import record without an input fingerprint. '
        'It cannot be safely reconciled from the web screen.',
      ));
      return;
    }

    try {
      final service = ServiceLocationService();
      final run = await service.inspectImportRun(
        runId: item.id,
        inputFingerprint: fingerprint,
      );
      final reconciliation = await service.reconcileImportPlan(
        runId: item.id,
        inputFingerprint: fingerprint,
      );
      if (!mounted) return;

      final missingIds = (reconciliation['missingIds'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(growable: false);
      final mismatchIds = (reconciliation['mismatchIds'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(growable: false);
      final status = reconciliation['status']?.toString() ?? 'unknown';
      final details = <String>[
        'Run ID: ${item.id}',
        'Run status: ${run['status'] ?? 'unknown'}',
        'Reconciliation: $status',
        'Planned records: ${reconciliation['plannedRecords'] ?? run['plannedRecords'] ?? 0}',
        'Matching records: ${reconciliation['matchingRecords'] ?? 0}',
        'Missing records: ${reconciliation['missingCount'] ?? 0}',
        'Mismatched records: ${reconciliation['mismatchCount'] ?? 0}',
        'Read-only: ${reconciliation['readOnly'] == true ? 'Yes' : 'No'}',
        if (missingIds.isNotEmpty) 'Missing IDs: ${missingIds.join(', ')}',
        if (mismatchIds.isNotEmpty) 'Mismatched IDs: ${mismatchIds.join(', ')}',
        if (reconciliation['truncated'] == true)
          'Only the first 50 missing/mismatched IDs are shown.',
      ];

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Import Run Reconciliation'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: SelectableText(details.join('\n')),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (error) {
      await _showError(error);
    }
  }

  Future<void> _reconcileImport(ServiceLocationImport item) async {
    final runId = item.id.trim();
    final fingerprint = item.inputFingerprint.trim();
    if (runId.isEmpty || fingerprint.isEmpty) {
      await _showError(StateError(
        'This import has no run ID or input fingerprint and cannot be reconciled.',
      ));
      return;
    }

    try {
      final result = await _service.reconcileImportPlan(
        runId: runId,
        inputFingerprint: fingerprint,
      );
      if (!mounted) return;
      final status = result['status']?.toString() ?? 'unknown';
      final details = <String>[
        'Run ID: $runId',
        'Result: $status',
        if (result['expectedRecords'] != null)
          'Expected records: ${result['expectedRecords']}',
        if (result['storedRecords'] != null)
          'Stored plan records: ${result['storedRecords']}',
        if (result['matchingRecords'] != null)
          'Matching records: ${result['matchingRecords']}',
        if (result['missingCount'] != null)
          'Missing records: ${result['missingCount']}',
        if (result['mismatchCount'] != null)
          'Mismatched records: ${result['mismatchCount']}',
        if (result['missingIds'] is List &&
            (result['missingIds'] as List).isNotEmpty)
          'Missing IDs: ${(result['missingIds'] as List).join(', ')}',
        if (result['mismatchIds'] is List &&
            (result['mismatchIds'] as List).isNotEmpty)
          'Mismatched IDs: ${(result['mismatchIds'] as List).join(', ')}',
        if (result['truncated'] == true)
          'Only the first reported mismatches are shown.',
        'This check is read-only. It does not resume or repair an import.',
      ];
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Import consistency result'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: SelectableText(details.join('\n')),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (error) {
      await _showError(error);
    }
  }

  Widget _buildImports() {
    return StreamBuilder<List<ServiceLocationImport>>(
      stream: _service.watchImports(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _emptyState(
            'Unable to load import history:\n${snapshot.error}',
          );
        }

        if (!snapshot.hasData) {
          return _loadingState();
        }

        final items = snapshot.data!
            .where(
              (item) => _matches(
                '${item.id} ${item.fileName} ${item.source} '
                '${item.status} ${item.verificationStatus}',
              ),
            )
            .toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CSV Import Preview',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Validate State, District, City and Area rows before any future import. '
                      'Preview only — no Firestore writes or activation.',
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed: _showCsvPreviewDialog,
                        icon: const Icon(Icons.preview_outlined),
                        label: const Text('Paste CSV and Preview'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _locationOrange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text('No import history records found yet.'),
              ),
            for (final item in items)
              Card(
                color: Colors.white,
                child: ListTile(
                  leading: const Icon(Icons.file_present, color: _locationOrange),
                  title: Text(item.fileName),
                  subtitle: Text(
                    'ID: ${item.id}\n'
                    'Source: ${item.source}\n'
                    'Status: ${item.status}\n'
                    'Verification: ${item.verificationStatus}',
                  ),
                  isThreeLine: true,
                  trailing: item.inputFingerprint.trim().isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Read-only consistency check',
                          icon: const Icon(Icons.fact_check_outlined),
                          onPressed: () => _reconcileImport(item),
                        ),
                ),
              ),
          ],
        );

      },
    );
  }

  // ============================================================
  // BOUNDARY MANAGEMENT
  // ============================================================

  Future<void> _manageBoundary({
    required String locationId,
    required String locationName,
    required String locationType,
  }) async {
    try {
      final boundaries = await _boundaryService
          .watchForLocation(
            locationId,
            locationType: locationType,
          )
          .first;

      if (!mounted) return;

      final verified = boundaries
          .where((boundary) => boundary.isVerified)
          .toList();

      // When more than one record exists, let the administrator explicitly
      // choose which boundary to inspect/edit/review instead of silently
      // selecting the first record by status.
      final existing = boundaries.length <= 1
          ? (boundaries.isEmpty ? null : boundaries.single)
          : await _chooseBoundaryRecord(
              locationName: locationName,
              boundaries: boundaries,
            );

      // A null result means the chooser was cancelled. For a location with
      // no records, null is the intentional "create first boundary" state.
      if (boundaries.length > 1 && existing == null) return;

      final initialPoints = existing == null
          ? <LatLng>[]
          : existing.points
              .map(
                (point) => LatLng(
                  point.latitude,
                  point.longitude,
                ),
              )
              .toList();

      await _showBoundaryEditor(
        locationId: locationId,
        locationName: locationName,
        locationType: locationType,
        existingBoundary: existing,
        initialPoints: initialPoints,
        hasVerifiedBoundary: verified.isNotEmpty,
      );
    } catch (error) {
      await _showError(error);
    }
  }

  Future<ServiceLocationBoundary?> _chooseBoundaryRecord({
    required String locationName,
    required List<ServiceLocationBoundary> boundaries,
  }) {
    String statusLabel(BoundaryVerificationStatus status) {
      switch (status) {
        case BoundaryVerificationStatus.pending:
          return 'Pending review';
        case BoundaryVerificationStatus.verified:
          return 'Verified · read-only';
        case BoundaryVerificationStatus.rejected:
          return 'Rejected · can edit/resubmit';
        case BoundaryVerificationStatus.notAvailable:
          return 'Status unavailable';
      }
    }

    String dateLabel(DateTime value) {
      final local = value.toLocal();
      String two(int n) => n.toString().padLeft(2, '0');
      return '${local.year}-${two(local.month)}-${two(local.day)} '
          '${two(local.hour)}:${two(local.minute)}';
    }

    final ordered = sortBoundariesForChooser(boundaries);

    return showDialog<ServiceLocationBoundary>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Choose Boundary · $locationName'),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'एक रिकॉर्ड चुनें। Verified रिकॉर्ड read-only है; '
                  'पुराना Verified रिकॉर्ड हटाया या बदला नहीं जाएगा।',
                ),
                const SizedBox(height: 10),
                for (final boundary in ordered)
                  Card(
                    child: ListTile(
                      leading: Icon(
                        boundary.isVerified
                            ? Icons.verified_outlined
                            : boundary.verificationStatus ==
                                    BoundaryVerificationStatus.rejected
                                ? Icons.error_outline
                                : Icons.map_outlined,
                      ),
                      title: Text(statusLabel(boundary.verificationStatus)),
                      subtitle: Text(
                        'Updated: ${dateLabel(boundary.updatedAt)}\n'
                        'Source: ${boundary.sourceName.isEmpty ? "Not specified" : boundary.sourceName}\n'
                        'ID: ${boundary.id}',
                      ),
                      isThreeLine: true,
                      onTap: () => Navigator.of(dialogContext).pop(boundary),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBoundaryEditor({
    required String locationId,
    required String locationName,
    required String locationType,
    required ServiceLocationBoundary? existingBoundary,
    required List<LatLng> initialPoints,
    bool hasVerifiedBoundary = false,
  }) async {
    final sourceNameController = TextEditingController(
      text: existingBoundary?.sourceName ?? '',
    );

    final sourceReferenceController = TextEditingController(
      text: existingBoundary?.sourceReference ?? '',
    );

    final notesController = TextEditingController();

    var sourceType = existingBoundary?.sourceType ??
        BoundarySourceType.manuallyDrawn;

    var currentPoints = List<LatLng>.of(initialPoints);
    var isSaving = false;

    final isVerified =
        existingBoundary?.verificationStatus ==
            BoundaryVerificationStatus.verified;

    final isRejected =
        existingBoundary?.verificationStatus ==
            BoundaryVerificationStatus.rejected;

    final isPending =
        existingBoundary?.verificationStatus ==
            BoundaryVerificationStatus.pending;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> saveBoundary(
                List<GeoPoint> points,
              ) async {
                if (isVerified) {
                  _showMessage(
                    'Verified Boundary read-only है।',
                  );
                  return;
                }

                if (isSaving) return;

                final sourceName =
                    sourceNameController.text.trim();

                final sourceReference =
                    sourceReferenceController.text.trim();

                if (sourceName.isEmpty ||
                    sourceReference.isEmpty) {
                  _showMessage(
                    'Source name और source reference भरें।',
                  );
                  return;
                }

                setDialogState(() => isSaving = true);

                try {
                  final now = DateTime.now();

                  final boundary = ServiceLocationBoundary(
                    id: existingBoundary?.id ?? '',
                    locationId: locationId,
                    locationType: locationType,
                    points: List<GeoPoint>.of(points),
                    sourceType: sourceType,
                    sourceName: sourceName,
                    sourceReference: sourceReference,
                    verificationStatus:
                        BoundaryVerificationStatus.pending,
                    verifiedBy: null,
                    verifiedAt: null,
                    verificationNotes: null,
                    createdAt:
                        existingBoundary?.createdAt ?? now,
                    updatedAt: now,
                  );

                  final errors = boundary.validate();

                  if (errors.isNotEmpty) {
                    throw ArgumentError(errors.join('\n'));
                  }

                  await _boundaryService.saveDraft(boundary);

                  if (!dialogContext.mounted) return;

                  Navigator.of(dialogContext).pop();

                  _showMessage(
                    isRejected
                        ? 'Boundary के बदलाव सेव हो गए और Boundary Pending Review में भेज दी गई।'
                        : isPending
                            ? 'Boundary अपडेट हो गई। इसका status Pending Review है।'
                            : 'Boundary सेव हो गई और Pending Review में भेज दी गई।',
                  );
                } catch (error) {
                  if (dialogContext.mounted) {
                    setDialogState(() => isSaving = false);
                  }

                  await _showError(error);
                }
              }

              return AlertDialog(
                title: Text('Manage Boundary · $locationName'),
                content: SizedBox(
                  width: 900,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Location type: $locationType',
                          style: const TextStyle(
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),

                        _boundaryStatusBanner(existingBoundary),

                        if (hasVerifiedBoundary && !isVerified) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _locationOrange.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _locationOrange.withValues(alpha: 0.35),
                              ),
                            ),
                            child: const Text(
                              'इस location की पुरानी Verified Boundary सुरक्षित है। '
                              'यह अलग replacement record है। Firebase replacement '
                              'verify करने से पहले location का inactive होना जरूरी है; '
                              'यह स्क्रीन service को अपने-आप deactivate नहीं करेगी।',
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),

                        if (isRejected) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              'Previous rejection reason:\n'
                              '${existingBoundary?.verificationNotes?.trim().isNotEmpty == true ? existingBoundary!.verificationNotes : "No rejection reason recorded."}',
                              style: const TextStyle(
                                color: Colors.red,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        if (!isVerified) ...[
                          DropdownButtonFormField<BoundarySourceType>(
                            initialValue: sourceType,
                            decoration: const InputDecoration(
                              labelText: 'Boundary source type',
                              border: OutlineInputBorder(),
                            ),
                            items: BoundarySourceType.values
                                .map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(
                                      _sourceTypeLabel(type),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;

                              setDialogState(() {
                                sourceType = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: sourceNameController,
                            decoration: const InputDecoration(
                              labelText: 'Source name *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: sourceReferenceController,
                            decoration: const InputDecoration(
                              labelText: 'Source reference *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Save करने पर Boundary Pending Review में जाएगी।',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        ServiceBoundaryEditor(
                          initialPoints: currentPoints,
                          initialCenter: _defaultMapCenter,
                          initialZoom: 12,
                          readOnly: isVerified,
                          onBoundaryChanged: (points) {
                            currentPoints = List<LatLng>.of(points);
                          },
                          onSaveRequested: saveBoundary,
                        ),

                        if (existingBoundary != null) ...[
                          const SizedBox(height: 16),
                          _boundaryDetails(existingBoundary),
                        ],
                      ],
                    ),
                  ),
                ),
                actions: [
                  if (isRejected &&
                      existingBoundary != null &&
                      existingBoundary.id.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              try {
                                final latest =
                                    await _boundaryService.getById(
                                  existingBoundary.id,
                                );

                                if (latest == null) {
                                  throw StateError(
                                    'Boundary नहीं मिली।',
                                  );
                                }

                                if (latest.verificationStatus !=
                                    BoundaryVerificationStatus.rejected) {
                                  throw StateError(
                                    'Boundary अब Rejected status में नहीं है।',
                                  );
                                }

                                if (!dialogContext.mounted) return;

                                final confirmed =
                                    await _confirmResubmit(
                                  locationName,
                                );

                                if (confirmed != true) return;

                                await _boundaryService
                                    .requestVerification(latest.id);

                                if (!dialogContext.mounted) return;

                                Navigator.of(dialogContext).pop();

                                _showMessage(
                                  'Boundary Review के लिए भेज दी गई।',
                                );
                              } catch (error) {
                                await _showError(error);
                              }
                            },
                      icon: const Icon(Icons.send_outlined),
                      label: const Text('Resubmit for Review'),
                    ),

                  if (isPending && existingBoundary != null)
                    TextButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              try {
                                final latest =
                                    await _boundaryService.getById(
                                  existingBoundary.id,
                                );

                                if (latest == null ||
                                    latest.verificationStatus !=
                                        BoundaryVerificationStatus.pending) {
                                  throw StateError(
                                    'केवल Pending Boundary को Reject किया जा सकता है।',
                                  );
                                }

                                if (!dialogContext.mounted) return;

                                final reason =
                                    await _askForReviewNotes(
                                  approve: false,
                                );

                                if (reason == null) return;

                                await _boundaryService.rejectBoundary(
                                  boundaryId: latest.id,
                                  reason: reason,
                                );

                                if (!dialogContext.mounted) return;

                                Navigator.of(dialogContext).pop();

                                _showMessage(
                                  'Boundary Reject कर दी गई।',
                                );
                              } catch (error) {
                                await _showError(error);
                              }
                            },
                      icon: const Icon(
                        Icons.close,
                        color: Colors.red,
                      ),
                      label: const Text(
                        'Reject',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),

                  if (isPending && existingBoundary != null)
                    FilledButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              try {
                                final latest =
                                    await _boundaryService.getById(
                                  existingBoundary.id,
                                );

                                if (latest == null ||
                                    latest.verificationStatus !=
                                        BoundaryVerificationStatus.pending) {
                                  throw StateError(
                                    'केवल Pending Boundary Verify हो सकती है।',
                                  );
                                }

                                final errors = latest.validate();

                                if (errors.isNotEmpty) {
                                  throw StateError(
                                    errors.join('\n'),
                                  );
                                }

                                if (!dialogContext.mounted) return;

                                final notes =
                                    await _askForReviewNotes(
                                  approve: true,
                                );

                                if (notes == null) return;

                                await _boundaryService.markVerified(
                                  boundaryId: latest.id,
                                  verificationNotes: notes,
                                );

                                if (!dialogContext.mounted) return;

                                Navigator.of(dialogContext).pop();

                                _showMessage(
                                  'Boundary Verified हो गई। Service activation अलग से होगी।',
                                );
                              } catch (error) {
                                await _showError(error);
                              }
                            },
                      icon: const Icon(Icons.verified_outlined),
                      label: const Text('Verify'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),

                  if (isVerified)
                    OutlinedButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              Navigator.of(dialogContext).pop();
                              await Future<void>.delayed(Duration.zero);
                              if (!mounted) return;
                              await _showBoundaryEditor(
                                locationId: locationId,
                                locationName: locationName,
                                locationType: locationType,
                                existingBoundary: null,
                                initialPoints: const <LatLng>[],
                              );
                            },
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: const Text('Create replacement boundary'),
                    ),

                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Close'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      sourceNameController.dispose();
      sourceReferenceController.dispose();
      notesController.dispose();
    }
  }

  Future<bool?> _confirmResubmit(String locationName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resubmit Boundary?'),
        content: Text(
          '$locationName की Boundary Review में भेजी जाएगी। '
          'क्या आपने polygon और source details जाँच लिए हैं?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Resubmit'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOUNDARY STATUS
  // ============================================================

  Widget _boundaryStatusBanner(
    ServiceLocationBoundary? boundary,
  ) {
    if (boundary == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'नई Boundary बनाएँ और source details भरें। '
          'Save करने पर वह Pending Review में जाएगी।',
        ),
      );
    }

    final status = boundary.verificationStatus;

    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;

    switch (status) {
      case BoundaryVerificationStatus.notAvailable:
        statusColor = Colors.grey;
        statusLabel = 'Not available';
        statusIcon = Icons.help_outline;
        break;

      case BoundaryVerificationStatus.pending:
        statusColor = Colors.orange;
        statusLabel = 'Pending review';
        statusIcon = Icons.hourglass_top;
        break;

      case BoundaryVerificationStatus.verified:
        statusColor = Colors.green;
        statusLabel = 'Verified';
        statusIcon = Icons.verified;
        break;

      case BoundaryVerificationStatus.rejected:
        statusColor = Colors.red;
        statusLabel = 'Rejected';
        statusIcon = Icons.cancel_outlined;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Boundary ID: ${boundary.id}'),
          Text('Vertices: ${boundary.points.length}'),
          Text('Source: ${boundary.sourceName}'),
          if (boundary.verificationNotes != null &&
              boundary.verificationNotes!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              status == BoundaryVerificationStatus.rejected
                  ? 'Rejection reason: ${boundary.verificationNotes}'
                  : 'Review notes: ${boundary.verificationNotes}',
            ),
          ],
          if (boundary.verifiedBy != null)
            Text('Reviewer UID: ${boundary.verifiedBy}'),
          if (boundary.verifiedAt != null)
            Text(
              'Reviewed: ${boundary.verifiedAt!.toLocal()}',
            ),
          if (boundary.isVerified) ...[
            const SizedBox(height: 8),
            const Text(
              'Verified Boundary read-only है।',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _boundaryDetails(
    ServiceLocationBoundary boundary,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Boundary review information',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Source type: ${_sourceTypeLabel(boundary.sourceType)}',
          ),
          Text('Source name: ${boundary.sourceName}'),
          Text('Source reference: ${boundary.sourceReference}'),
          Text('Status: ${boundary.verificationStatus.name}'),
          if (boundary.verificationNotes != null &&
              boundary.verificationNotes!.isNotEmpty)
            Text('Notes: ${boundary.verificationNotes}'),
        ],
      ),
    );
  }

  Future<String?> _askForReviewNotes({
    required bool approve,
  }) async {
    final controller = TextEditingController();

    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            approve ? 'Verify Boundary' : 'Reject Boundary',
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  approve
                      ? 'Source और polygon जाँचने के बाद verification notes लिखें।'
                      : 'Boundary Reject करने का स्पष्ट कारण लिखें।',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: approve
                        ? 'Verification notes *'
                        : 'Rejection reason *',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: approve ? Colors.green : Colors.red,
              ),
              onPressed: () {
                final notes = controller.text.trim();

                if (notes.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'कृपया टिप्पणी या कारण लिखें।',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext, notes);
              },
              child: Text(approve ? 'Verify' : 'Reject'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  String _sourceTypeLabel(BoundarySourceType type) {
    switch (type) {
      case BoundarySourceType.governmentGis:
        return 'Government GIS';
      case BoundarySourceType.governmentCadastralMap:
        return 'Government cadastral map';
      case BoundarySourceType.importedGeoJson:
        return 'Imported GeoJSON';
      case BoundarySourceType.manuallyDrawn:
        return 'Manually drawn';
    }
  }

  // ============================================================
  // SHARED WIDGETS
  // ============================================================

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: _locationOrange,
          ),
        ),
      ),
    );
  }

  Widget _locationCard({
    required String title,
    required String subtitle,
    required bool active,
    required IconData icon,
    required ValueChanged<bool> onToggle,
    VoidCallback? onManageBoundary,
  }) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              _locationOrange.withValues(alpha: 0.12),
          child: Icon(icon, color: _locationOrange),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        isThreeLine: subtitle.contains('\n'),
        trailing: SizedBox(
          width: onManageBoundary == null ? 65 : 190,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onManageBoundary != null)
                IconButton(
                  tooltip: 'Manage Boundary',
                  onPressed: onManageBoundary,
                  icon: const Icon(
                    Icons.edit_location_alt_outlined,
                    color: _locationOrange,
                  ),
                ),
              Switch(
                value: active,
                activeThumbColor: _locationOrange,
                onChanged: onToggle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ADD LOCATION
  // ============================================================

  Future<void> _showAddLocationDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddLocationDialog(
        service: _service,
        onSaved: (tab) {
          if (!mounted) return;

          setState(() => _selectedTab = tab);
          _showMessage('Location saved successfully.');
        },
      ),
    );
  }
}
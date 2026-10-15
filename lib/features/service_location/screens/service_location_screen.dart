import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/service_city.dart';
import '../models/service_area.dart';
import '../models/service_locality.dart';
import '../services/service_location_service.dart';

const Color serviceLocationOrange = Color(0xFFFF7900);
const Color serviceLocationBackground = Color(0xFFFFFAF5);
const Color serviceLocationText = Color(0xFF252525);

class ServiceLocationScreen extends StatefulWidget {
  const ServiceLocationScreen({super.key});

  @override
  State<ServiceLocationScreen> createState() =>
      _ServiceLocationScreenState();
}

class _ServiceLocationScreenState
    extends State<ServiceLocationScreen>
    with SingleTickerProviderStateMixin {
  final ServiceLocationService _service = ServiceLocationService();
  final TextEditingController _searchController =
      TextEditingController();

  late final TabController _tabController;

  GoogleMapController? _mapController;

  ServiceCity? _selectedCity;
  ServiceArea? _selectedArea;
  ServiceLocality? _selectedLocality;

  String _search = '';

  static const LatLng _defaultLocation =
      LatLng(28.5355, 77.3910);

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: serviceLocationText,
      ),
    );
  }

  List<LatLng> _toLatLng(List<GeoPoint> points) {
    return points
        .map((point) => LatLng(
              point.latitude,
              point.longitude,
            ))
        .toList();
  }

  Set<Polygon> _buildPolygons() {
    final points = _selectedLocality != null
        ? _selectedLocality!.boundary
        : _selectedArea != null
            ? _selectedArea!.boundary
            : _selectedCity?.boundary ?? <GeoPoint>[];

    if (points.length < 3) {
      return {};
    }

    return {
      Polygon(
        polygonId: const PolygonId('selected_boundary'),
        points: _toLatLng(points),
        fillColor: serviceLocationOrange.withValues(alpha: 0.18),
        strokeColor: serviceLocationOrange,
        strokeWidth: 3,
      ),
    };
  }

  Future<void> _focusBoundary(List<GeoPoint> points) async {
    if (points.isEmpty || _mapController == null) return;

    if (points.length == 1) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(
            points.first.latitude,
            points.first.longitude,
          ),
          14,
        ),
      );
      return;
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    if (minLat == maxLat && minLng == maxLng) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(minLat, minLng),
          14,
        ),
      );
      return;
    }

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        48,
      ),
    );
  }

  bool _matches(String value) {
    return value.toLowerCase().contains(_search.toLowerCase());
  }

  String get _selectedType {
    switch (_tabController.index) {
      case 0:
        return 'City';
      case 1:
        return 'Area';
      default:
        return 'Locality';
    }
  }

  String get _boundaryStatus {
    final verified = _selectedLocality?.boundaryVerified ??
        _selectedArea?.boundaryVerified ??
        _selectedCity?.boundaryVerified ??
        false;

    final points = _selectedLocality?.boundary ??
        _selectedArea?.boundary ??
        _selectedCity?.boundary ??
        <GeoPoint>[];

    if (!verified) return 'Not verified';
    if (points.length < 3) return 'Boundary incomplete';

    return 'Verified';
  }

  bool get _serviceStatus {
    return _selectedLocality?.isServiceActive ??
        _selectedArea?.isServiceActive ??
        _selectedCity?.isServiceActive ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: serviceLocationBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearch(),
            _buildMap(),
            _buildBoundaryInformation(),
            _buildTabs(),
            Expanded(child: _buildSelectedList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: serviceLocationOrange,
        foregroundColor: Colors.white,
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: Text('Add $_selectedType'),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: serviceLocationOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: serviceLocationOrange,
              size: 27,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Service Locations',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: serviceLocationText,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Manage cities, areas and localities',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() => _search = value.trim());
        },
        decoration: InputDecoration(
          hintText: 'Search $_selectedType...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _search.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _search = '');
                  },
                  icon: const Icon(Icons.close),
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFEAEAEA)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFEAEAEA)),
          ),
        ),
      ),
    );
  }

  Widget _buildMap() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 270,
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: _defaultLocation,
                  zoom: 10,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                polygons: _buildPolygons(),
                mapToolbarEnabled: false,
                zoomControlsEnabled: true,
                myLocationButtonEnabled: false,
                compassEnabled: true,
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: 17,
                        color: serviceLocationOrange,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Boundary Preview',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoundaryInformation() {
    final hasSelection = _selectedCity != null ||
        _selectedArea != null ||
        _selectedLocality != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0E7DE)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: serviceLocationOrange,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasSelection
                      ? (_selectedLocality?.name ??
                          _selectedArea?.name ??
                          _selectedCity?.name ??
                          '')
                      : 'No location selected',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasSelection
                      ? 'Boundary: $_boundaryStatus'
                      : 'Select a location from the list below.',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (hasSelection)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _serviceStatus
                    ? const Color(0xFFE6F5EA)
                    : const Color(0xFFFFF0E5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _serviceStatus ? 'ACTIVE' : 'INACTIVE',
                style: TextStyle(
                  color: _serviceStatus
                      ? Colors.green.shade800
                      : serviceLocationOrange,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: serviceLocationOrange,
        unselectedLabelColor: Colors.black54,
        indicatorColor: serviceLocationOrange,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
        tabs: const [
          Tab(text: 'Cities'),
          Tab(text: 'Areas'),
          Tab(text: 'Localities'),
        ],
      ),
    );
  }

  Widget _buildSelectedList() {
    switch (_tabController.index) {
      case 0:
        return _buildCities();
      case 1:
        return _buildAreas();
      default:
        return _buildLocalities();
    }
  }

  Widget _buildCities() {
    return StreamBuilder<List<ServiceCity>>(
      stream: _service.watchCities(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _errorState(snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final cities = (snapshot.data ?? [])
            .where((city) => _matches(city.name))
            .toList();

        if (cities.isEmpty) {
          return _emptyState(
            'No cities found',
            'Add a city to start setting up service locations.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
          itemCount: cities.length,
          itemBuilder: (context, index) {
            final city = cities[index];

            return _locationCard(
              title: city.name,
              subtitle: '${city.state}, ${city.country}',
              active: city.isServiceActive,
              verified: city.boundaryVerified,
              selected: _selectedCity?.id == city.id &&
                  _tabController.index == 0,
              onTap: () {
                setState(() {
                  _selectedCity = city;
                  _selectedArea = null;
                  _selectedLocality = null;
                });
                _focusBoundary(city.boundary);
              },
              onStatusTap: () => _toggleCityStatus(city),
            );
          },
        );
      },
    );
  }

  Widget _buildAreas() {
    final city = _selectedCity;

    if (city == null) {
      return _emptyState(
        'Select a city first',
        'Open Cities and select a city before viewing its areas.',
      );
    }

    return StreamBuilder<List<ServiceArea>>(
      stream: _service.watchAreas(city.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _errorState(snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final areas = (snapshot.data ?? [])
            .where((area) => _matches(area.name))
            .toList();

        if (areas.isEmpty) {
          return _emptyState(
            'No areas found',
            'Add an area under ${city.name}.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
          itemCount: areas.length,
          itemBuilder: (context, index) {
            final area = areas[index];

            return _locationCard(
              title: area.name,
              subtitle: 'City: ${city.name}',
              active: area.isServiceActive,
              verified: area.boundaryVerified,
              selected: _selectedArea?.id == area.id,
              onTap: () {
                setState(() {
                  _selectedArea = area;
                  _selectedLocality = null;
                });
                _focusBoundary(area.boundary);
              },
              onStatusTap: () => _toggleAreaStatus(area),
            );
          },
        );
      },
    );
  }

  Widget _buildLocalities() {
    final city = _selectedCity;
    final area = _selectedArea;

    if (city == null || area == null) {
      return _emptyState(
        'Select a city and area first',
        'Choose a city, then select an area before viewing localities.',
      );
    }

    return StreamBuilder<List<ServiceLocality>>(
      stream: _service.watchLocalities(
        cityId: city.id,
        areaId: area.id,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _errorState(snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final localities = (snapshot.data ?? [])
            .where((locality) => _matches(locality.name))
            .toList();

        if (localities.isEmpty) {
          return _emptyState(
            'No localities found',
            'Add a locality under ${area.name}.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
          itemCount: localities.length,
          itemBuilder: (context, index) {
            final locality = localities[index];

            return _locationCard(
              title: locality.name,
              subtitle: '${city.name} • ${area.name}',
              active: locality.isServiceActive,
              verified: locality.boundaryVerified,
              selected: _selectedLocality?.id == locality.id,
              onTap: () {
                setState(() {
                  _selectedLocality = locality;
                });
                _focusBoundary(locality.boundary);
              },
              onStatusTap: () => _toggleLocalityStatus(locality),
            );
          },
        );
      },
    );
  }

  Widget _locationCard({
    required String title,
    required String subtitle,
    required bool active,
    required bool verified,
    required bool selected,
    required VoidCallback onTap,
    required VoidCallback onStatusTap,
  }) {
    return Card(
      color: selected ? const Color(0xFFFFF2E7) : Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected
              ? serviceLocationOrange
              : const Color(0xFFEDE7E1),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 5,
        ),
        leading: Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: serviceLocationOrange.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.location_on_outlined,
            color: serviceLocationOrange,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '$subtitle\n${verified ? 'Boundary verified' : 'Boundary not verified'}',
            style: const TextStyle(fontSize: 11),
          ),
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'status') {
              onStatusTap();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'status',
              child: Text(active ? 'Deactivate' : 'Activate'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_searching,
              size: 42,
              color: serviceLocationOrange,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Could not load locations.\n$error',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Future<void> _toggleCityStatus(ServiceCity city) async {
    final next = !city.isServiceActive;

    if (next && !city.boundaryVerified) {
      _showMessage(
        'Verify the city boundary before activation.',
      );
      return;
    }

    try {
      await _service.setCityServiceStatus(
        cityId: city.id,
        isActive: next,
      );
      _showMessage(next ? 'City activated.' : 'City deactivated.');
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  Future<void> _toggleAreaStatus(ServiceArea area) async {
    final next = !area.isServiceActive;

    if (next && !area.boundaryVerified) {
      _showMessage(
        'Verify the area boundary before activation.',
      );
      return;
    }

    try {
      await _service.setAreaServiceStatus(
        areaId: area.id,
        isActive: next,
      );
      _showMessage(next ? 'Area activated.' : 'Area deactivated.');
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  Future<void> _toggleLocalityStatus(
    ServiceLocality locality,
  ) async {
    final next = !locality.isServiceActive;

    if (next && !locality.boundaryVerified) {
      _showMessage(
        'Verify the locality boundary before activation.',
      );
      return;
    }

    try {
      await _service.setLocalityServiceStatus(
        localityId: locality.id,
        isActive: next,
      );
      _showMessage(
        next ? 'Locality activated.' : 'Locality deactivated.',
      );
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  Future<void> _showCreateDialog() async {
    final nameController = TextEditingController();
    final stateController = TextEditingController();
    String? selectedCityId = _selectedCity?.id;
    String? selectedAreaId = _selectedArea?.id;

    final type = _tabController.index;

    if (type == 1 && _selectedCity == null) {
      _showMessage('Select a city first.');
      nameController.dispose();
      stateController.dispose();
      return;
    }

    if (type == 2 &&
        (_selectedCity == null || _selectedArea == null)) {
      _showMessage('Select a city and area first.');
      nameController.dispose();
      stateController.dispose();
      return;
    }

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          bool saving = false;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text('Add $_selectedType'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: '$_selectedType name',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      if (type == 0) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: stateController,
                          decoration: const InputDecoration(
                            labelText: 'State',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Text(
                        'New locations are saved inactive. A real boundary must be imported and verified separately before activation.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: saving
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: serviceLocationOrange,
                    ),
                    onPressed: saving
                        ? null
                        : () async {
                            final name = nameController.text.trim();

                            if (name.isEmpty) {
                              _showMessage(
                                'Please enter a name.',
                              );
                              return;
                            }

                            if (type == 0 &&
                                stateController.text.trim().isEmpty) {
                              _showMessage(
                                'Please enter a state.',
                              );
                              return;
                            }

                            setDialogState(() => saving = true);

                            try {
                              if (type == 0) {
                                await _service.saveCity(
                                  ServiceCity(
                                    name: name,
                                    state: stateController.text.trim(),
                                    country: 'India',
                                  ),
                                );
                              } else if (type == 1) {
                                await _service.saveArea(
                                  ServiceArea(
                                    cityId: selectedCityId!,
                                    name: name,
                                  ),
                                );
                              } else {
                                await _service.saveLocality(
                                  ServiceLocality(
                                    cityId: selectedCityId!,
                                    areaId: selectedAreaId!,
                                    name: name,
                                  ),
                                );
                              }

                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }

                              _showMessage(
                                '$_selectedType saved as inactive.',
                              );
                            } catch (e) {
                              _showMessage(e.toString());
                              setDialogState(() => saving = false);
                            }
                          },
                    child: saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      stateController.dispose();
    }
  }
}

/// DOJO WALK Admin
///
/// Service Locations management screen.
///
/// Features:
/// - Countries, States, Cities, Areas, Localities and Import History.
/// - Search across location lists.
/// - Manage City and Area geographic boundaries.
/// - Save pending boundary drafts.
/// - Verify or reject a boundary with reviewer notes.
/// - Verified boundaries are read-only.
/// - Prefer verified boundaries when multiple records exist.
/// - Legacy Zones are not modified.
///
/// IMPORTANT:
/// The existing ServiceLocationService activation workflow still
/// uses legacy boundary fields. A verified record in
/// service_location_boundaries does not automatically update
/// those legacy fields. Do not treat this screen alone as the
/// complete activation-security implementation.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/service_location_boundary.dart';
import '../models/service_location_models.dart';
import '../services/service_location_boundary_service.dart';
import '../services/service_location_service.dart';
import '../widgets/add_location_dialog.dart';
import '../widgets/service_boundary_editor.dart';

const Color _locationOrange = Color(0xFFFF7900);
const Color _locationBackground = Color(0xFFFFFAF5);

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

  static const List<String> _tabNames = [
    'Countries',
    'States',
    'Cities / Districts',
    'Areas / Sub-districts',
    'Localities / Villages',
    'Import History',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
    return value.toLowerCase().contains(
          _search.toLowerCase(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      backgroundColor: _locationBackground,
      appBar: AppBar(
        title: const Text(
          'Service Locations',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _showAddLocationDialog,
            icon: const Icon(
              Icons.add_location_alt,
              color: _locationOrange,
            ),
            label: const Text(
              'Add Location',
              style: TextStyle(
                color: _locationOrange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              12,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _search = value.trim());
              },
              decoration: InputDecoration(
                hintText:
                    'Search location name, ID or PIN code...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: _locationOrange,
                ),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                        icon: const Icon(Icons.clear),
                      ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: SizedBox(
              width: double.infinity,
              height: isMobile ? 180 : 220,
              child: _buildMapPreview(),
            ),
          ),
          const SizedBox(height: 8),
          _buildTabs(),
          const Divider(height: 1),
          Expanded(child: _buildSelectedList()),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _locationOrange.withValues(alpha: 0.20),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location Hierarchy',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Country → State → City/District → '
            'Area/Sub-district → Locality/Village',
          ),
          SizedBox(height: 6),
          Text(
            'Draft → Review → Verified → Activation',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: _locationOrange,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Boundary verification और service activation अलग-अलग '
            'चरण हैं। सक्रिय करने से पहले parent location और '
            'activation rules भी जाँचें।',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
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
      child: const ColoredBox(
        color: Color(0xFFF1F3F0),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 34,
                  color: _locationOrange,
                ),
                SizedBox(height: 6),
                Text(
                  'Geographic Boundaries',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'City या Area पर Manage Boundary चुनें।',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
        return _buildCities();
      case 3:
        return _buildAreas();
      case 4:
        return _buildLocalities();
      default:
        return _buildImports();
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

  // ============================================================
  // COUNTRIES
  // ============================================================

  Widget _buildCountries() {
    return StreamBuilder<List<ServiceCountry>>(
      stream: _service.watchCountries(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _emptyState(
            'Unable to load countries: ${snapshot.error}',
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
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
          return const Center(
            child: CircularProgressIndicator(),
          );
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
                stream: _service.watchStates(countryId: country.id),
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
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(country.name),
                      for (final item in items)
                        _locationCard(
                          title: item.name,
                          subtitle:
                              'ID: ${item.id} · '
                              'Country: ${country.name}',
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
  // CITIES
  // ============================================================

  Widget _buildCities() {
    return StreamBuilder<List<ServiceCountry>>(
      stream: _service.watchCountries(),
      builder: (context, countrySnapshot) {
        if (countrySnapshot.hasError) {
          return _emptyState('${countrySnapshot.error}');
        }

        if (!countrySnapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final countries = countrySnapshot.data!;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            for (final country in countries)
              StreamBuilder<List<ServiceState>>(
                stream: _service.watchStates(countryId: country.id),
                builder: (context, stateSnapshot) {
                  if (stateSnapshot.hasError ||
                      !stateSnapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    children: [
                      for (final state in stateSnapshot.data!)
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

                            final cities = citySnapshot.data!
                                .where(
                                  (item) => _matches(
                                    '${item.id} ${item.name} '
                                    '${state.id} ${state.name} '
                                    '${country.id} ${country.name}',
                                  ),
                                )
                                .toList();

                            if (cities.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            return Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                _sectionTitle(
                                  '${state.name} · ${country.name}',
                                ),
                                for (final item in cities)
                                  _locationCard(
                                    title: item.name,
                                    subtitle:
                                        'ID: ${item.id}\n'
                                        'Legacy boundary points: '
                                        '${item.boundary.length}\n'
                                        'Legacy verified: '
                                        '${item.boundaryVerified ? "Yes" : "No"}',
                                    active: item.isServiceActive,
                                    icon: Icons.location_city,
                                    onManageBoundary: () =>
                                        _manageBoundary(
                                      locationId: item.id,
                                      locationName: item.name,
                                      locationType: 'city',
                                    ),
                                    onToggle: (value) async {
                                      try {
                                        await _service
                                            .setCityServiceStatus(
                                          cityId: item.id,
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
              ),
          ],
        );
      },
    );
  }

  // ============================================================
  // AREAS
  // ============================================================

  Widget _buildAreas() {
    return StreamBuilder<List<ServiceCity>>(
      stream: _service.watchCities(),
      builder: (context, citySnapshot) {
        if (citySnapshot.hasError) {
          return _emptyState('${citySnapshot.error}');
        }

        if (!citySnapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final cities = citySnapshot.data!;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            for (final city in cities)
              StreamBuilder<List<ServiceArea>>(
                stream: _service.watchAreas(cityId: city.id),
                builder: (context, snapshot) {
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final areas = snapshot.data!
                      .where(
                        (item) => _matches(
                          '${item.id} ${item.name} '
                          '${city.id} ${city.name}',
                        ),
                      )
                      .toList();

                  if (areas.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(city.name),
                      for (final item in areas)
                        _locationCard(
                          title: item.name,
                          subtitle:
                              'ID: ${item.id}\n'
                              'City/District: ${city.name}\n'
                              'Legacy boundary points: '
                              '${item.boundary.length} · '
                              'Legacy verified: '
                              '${item.boundaryVerified ? "Yes" : "No"}',
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
  // LOCALITIES
  // ============================================================

  Widget _buildLocalities() {
    return StreamBuilder<List<ServiceCity>>(
      stream: _service.watchCities(),
      builder: (context, citySnapshot) {
        if (citySnapshot.hasError) {
          return _emptyState('${citySnapshot.error}');
        }

        if (!citySnapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            for (final city in citySnapshot.data!)
              StreamBuilder<List<ServiceArea>>(
                stream: _service.watchAreas(city.id),
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
                                        '${item.boundaryVerified ? "Verified" : "Not verified"}',
                                    active: item.isServiceActive,
                                    icon: Icons.place_outlined,
                                    onToggle: (value) async {
                                      try {
                                        await _service
                                            .setLocalityServiceStatus(
                                          localityId: item.id,
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
              ),
          ],
        );
      },
    );
  }

  // ============================================================
  // IMPORT HISTORY
  // ============================================================

  Widget _buildImports() {
    return StreamBuilder<List<ServiceLocationImport>>(
      stream: _service.watchImports(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _emptyState(
            'Unable to load import history: ${snapshot.error}',
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final items = snapshot.data!
            .where(
              (item) => _matches(
                '${item.id} ${item.fileName} ${item.source} '
                '${item.status} ${item.verificationStatus}',
              ),
            )
            .toList();

        if (items.isEmpty) {
          return _emptyState('No import records found.');
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];

            return Card(
              color: Colors.white,
              child: ListTile(
                leading: const Icon(
                  Icons.file_present,
                  color: _locationOrange,
                ),
                title: Text(item.fileName),
                subtitle: Text(
                  'ID: ${item.id}\n'
                  'Source: ${item.source}\n'
                  'Status: ${item.status}\n'
                  'Verification: ${item.verificationStatus}',
                ),
                isThreeLine: true,
              ),
            );
          },
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

      // Prefer a verified boundary so a newer pending draft
      // does not hide an existing verified record.
      final verified = boundaries
          .where((boundary) => boundary.isVerified)
          .toList();

      final existing = verified.isNotEmpty
          ? verified.first
          : (boundaries.isNotEmpty ? boundaries.first : null);

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
      );
    } catch (error) {
      await _showError(error);
    }
  }

  Future<void> _showBoundaryEditor({
    required String locationId,
    required String locationName,
    required String locationType,
    required ServiceLocationBoundary? existingBoundary,
    required List<LatLng> initialPoints,
  }) async {
    final sourceNameController = TextEditingController(
      text: existingBoundary?.sourceName ?? '',
    );

    final sourceReferenceController = TextEditingController(
      text: existingBoundary?.sourceReference ?? '',
    );

    final notesController = TextEditingController(
      text: existingBoundary?.verificationNotes ?? '',
    );

    var sourceType = existingBoundary?.sourceType ??
        BoundarySourceType.manuallyDrawn;

    var currentPoints = List<LatLng>.of(initialPoints);
    var isSaving = false;

    final isVerified = existingBoundary?.isVerified ?? false;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
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

                  final draft = ServiceLocationBoundary(
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
                    verificationNotes:
                        notesController.text.trim().isEmpty
                            ? null
                            : notesController.text.trim(),
                    createdAt:
                        existingBoundary?.createdAt ?? now,
                    updatedAt: now,
                  );

                  final errors = draft.validate();

                  if (errors.isNotEmpty) {
                    throw ArgumentError(
                      errors.join('\n'),
                    );
                  }

                  await _boundaryService.saveDraft(draft);

                  if (!dialogContext.mounted) return;

                  Navigator.of(dialogContext).pop();

                  _showMessage(
                    'Draft saved. Boundary अभी Verified नहीं है।',
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

                        _boundaryStatusBanner(
                          existingBoundary,
                        ),

                        const SizedBox(height: 12),

                        if (!isVerified) ...[
                          DropdownButtonFormField<
                              BoundarySourceType>(
                            value: sourceType,
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
                              hintText:
                                  'Example: Official government GIS',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: sourceReferenceController,
                            decoration: const InputDecoration(
                              labelText: 'Source reference *',
                              hintText:
                                  'Official URL, document ID or dataset reference',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: notesController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Notes (optional)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        ServiceBoundaryEditor(
                          initialPoints: currentPoints,
                          initialCenter:
                              const LatLng(28.4744, 77.5040),
                          initialZoom: 12,
                          readOnly: isVerified,
                          onBoundaryChanged: (points) {
                            currentPoints =
                                List<LatLng>.of(points);
                          },
                          onSaveRequested: isVerified
                              ? null
                              : saveBoundary,
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
                  if (existingBoundary != null &&
                      !existingBoundary.isVerified &&
                      existingBoundary.id.isNotEmpty) ...[
                    TextButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              // Refresh the persisted record before
                              // starting a review action.
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

                                if (latest.isVerified) {
                                  throw StateError(
                                    'यह Boundary पहले से Verified है।',
                                  );
                                }

                                if (!dialogContext.mounted) {
                                  return;
                                }

                                final notes =
                                    await _askForReviewNotes(
                                  approve: false,
                                  initialText:
                                      latest.verificationNotes ?? '',
                                );

                                if (notes == null ||
                                    notes.trim().isEmpty) {
                                  return;
                                }

                                await _boundaryService
                                    .rejectBoundary(
                                  boundaryId: latest.id,
                                  reason: notes,
                                );

                                if (!dialogContext.mounted) {
                                  return;
                                }

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
                    FilledButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              try {
                                // Always review the persisted version,
                                // not unsaved map changes.
                                final latest =
                                    await _boundaryService.getById(
                                  existingBoundary.id,
                                );

                                if (latest == null) {
                                  throw StateError(
                                    'Boundary नहीं मिली।',
                                  );
                                }

                                if (latest.isVerified) {
                                  throw StateError(
                                    'यह Boundary पहले से Verified है।',
                                  );
                                }

                                final validationErrors =
                                    latest.validate();

                                if (validationErrors.isNotEmpty) {
                                  throw StateError(
                                    'Boundary Verify करने से पहले '
                                    'इसे ठीक करें:\n'
                                    '${validationErrors.join('\n')}',
                                  );
                                }

                                if (!dialogContext.mounted) {
                                  return;
                                }

                                final notes =
                                    await _askForReviewNotes(
                                  approve: true,
                                  initialText:
                                      latest.verificationNotes ?? '',
                                );

                                if (notes == null ||
                                    notes.trim().isEmpty) {
                                  return;
                                }

                                await _boundaryService.markVerified(
                                  boundaryId: latest.id,
                                  verificationNotes: notes,
                                );

                                if (!dialogContext.mounted) {
                                  return;
                                }

                                Navigator.of(dialogContext).pop();

                                _showMessage(
                                  'Boundary Verified हो गई। '
                                  'Service activation अलग से जाँची जाएगी।',
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
                  ],
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

  // ============================================================
  // BOUNDARY STATUS / REVIEW
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
          'नई Boundary: polygon बनाएँ और source details भरें। '
          'Draft सेव करने के बाद उसकी समीक्षा की जा सकती है।',
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
      case BoundaryVerificationStatus.pending:
        statusColor = Colors.orange;
        statusLabel = 'Pending review';
        statusIcon = Icons.hourglass_top;
      case BoundaryVerificationStatus.verified:
        statusColor = Colors.green;
        statusLabel = 'Verified';
        statusIcon = Icons.verified;
      case BoundaryVerificationStatus.rejected:
        statusColor = Colors.red;
        statusLabel = 'Rejected';
        statusIcon = Icons.cancel_outlined;
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
              'Review notes: ${boundary.verificationNotes}',
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
              'Verified Boundary read-only है। सामान्य Draft '
              'सेव द्वारा इसे बदला नहीं जा सकता।',
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
          Text('Source type: ${_sourceTypeLabel(boundary.sourceType)}'),
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
    String initialText = '',
  }) async {
    final controller = TextEditingController(
      text: initialText,
    );

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
                      ? 'Source और polygon की जाँच के बाद verification notes लिखें।'
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
                backgroundColor:
                    approve ? Colors.green : Colors.red,
              ),
              onPressed: () {
                final notes = controller.text.trim();

                if (notes.isEmpty) {
                  ScaffoldMessenger.of(dialogContext)
                      .showSnackBar(
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
          width: onManageBoundary == null ? 58 : 190,
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

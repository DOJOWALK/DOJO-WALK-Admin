import 'package:flutter/material.dart';

import '../models/service_location_models.dart';
import '../services/service_location_service.dart';

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
  final ServiceLocationService _service = ServiceLocationService();
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
        content: Text(error.toString()),
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
    return value.toLowerCase().contains(_search.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
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
          _buildTabs(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() {
                _search = value.trim();
              }),
              decoration: InputDecoration(
                hintText: 'Search locations...',
                prefixIcon: const Icon(Icons.search),
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
          Expanded(child: _buildSelectedList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _locationOrange,
        foregroundColor: Colors.white,
        onPressed: _showAddLocationDialog,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Add Location'),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _locationOrange.withValues(alpha: 0.2)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location Hierarchy',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Country → State → City/District → '
            'Area/Sub-district → Locality/Village',
          ),
          SizedBox(height: 8),
          Text(
            'New records remain inactive until their required '
            'parent locations and boundaries are verified.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return SizedBox(
      height: 54,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: _tabNames.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = _selectedTab == index;

          return ChoiceChip(
            label: Text(_tabNames[index]),
            selected: selected,
            selectedColor: _locationOrange.withValues(alpha: 0.18),
            onSelected: (_) => setState(() {
              _selectedTab = index;
            }),
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
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildCountries() {
    return StreamBuilder<List<ServiceCountry>>(
      stream: _service.watchCountries(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _emptyState('Unable to load countries: ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data!
            .where((item) => _matches('${item.name} ${item.code}'))
            .toList();

        if (items.isEmpty) return _emptyState('No countries found.');

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];

            return _locationCard(
              title: item.name,
              subtitle: 'Code: ${item.code}',
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

  Widget _buildStates() {
    return StreamBuilder<List<ServiceCountry>>(
      stream: _service.watchCountries(),
      builder: (context, countriesSnapshot) {
        if (!countriesSnapshot.hasData) {
          if (countriesSnapshot.hasError) {
            return _emptyState('${countriesSnapshot.error}');
          }
          return const Center(child: CircularProgressIndicator());
        }

        final countries = countriesSnapshot.data!;
        final streams = countries
            .map((country) => _service.watchStates(country.id))
            .toList();

        if (streams.isEmpty) return _emptyState('Add a country first.');

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
          children: [
            for (final country in countries)
              StreamBuilder<List<ServiceState>>(
                stream: _service.watchStates(country.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();

                  final items = snapshot.data!
                      .where((item) => _matches('${item.name} ${country.name}'))
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                        child: Text(
                          country.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _locationOrange,
                          ),
                        ),
                      ),
                      for (final item in items)
                        _locationCard(
                          title: item.name,
                          subtitle: 'Country: ${country.name}',
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

  Widget _buildCities() {
    return StreamBuilder<List<ServiceCountry>>(
      stream: _service.watchCountries(),
      builder: (context, countrySnapshot) {
        if (!countrySnapshot.hasData) {
          if (countrySnapshot.hasError) {
            return _emptyState('${countrySnapshot.error}');
          }
          return const Center(child: CircularProgressIndicator());
        }

        final countries = countrySnapshot.data!;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
          children: [
            for (final country in countries)
              StreamBuilder<List<ServiceState>>(
                stream: _service.watchStates(country.id),
                builder: (context, stateSnapshot) {
                  if (!stateSnapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final state in stateSnapshot.data!)
                        StreamBuilder<List<ServiceCity>>(
                          stream: _service.watchCities(
                            countryId: country.id,
                            stateId: state.id,
                          ),
                          builder: (context, citySnapshot) {
                            if (!citySnapshot.hasData) {
                              return const SizedBox.shrink();
                            }

                            final cities = citySnapshot.data!
                                .where((item) => _matches(
                                      '${item.name} ${state.name} ${country.name}',
                                    ))
                                .toList();

                            if (cities.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    4, 12, 4, 4,
                                  ),
                                  child: Text(
                                    '${state.name} · ${country.name}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _locationOrange,
                                    ),
                                  ),
                                ),
                                for (final item in cities)
                                  _locationCard(
                                    title: item.name,
                                    subtitle:
                                        'Boundary points: ${item.boundary.length} · '
                                        'Verified: ${item.boundaryVerified ? "Yes" : "No"}',
                                    active: item.isServiceActive,
                                    icon: Icons.location_city,
                                    onToggle: (value) async {
                                      try {
                                        await _service.setCityServiceStatus(
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

  Widget _buildAreas() {
    return StreamBuilder<List<ServiceCity>>(
      stream: _service.watchCities(),
      builder: (context, citySnapshot) {
        if (!citySnapshot.hasData) {
          if (citySnapshot.hasError) {
            return _emptyState('${citySnapshot.error}');
          }
          return const Center(child: CircularProgressIndicator());
        }

        final cities = citySnapshot.data!;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
          children: [
            for (final city in cities)
              StreamBuilder<List<ServiceArea>>(
                stream: _service.watchAreas(city.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();

                  final areas = snapshot.data!
                      .where((item) => _matches('${item.name} ${city.name}'))
                      .toList();

                  if (areas.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                        child: Text(
                          city.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _locationOrange,
                          ),
                        ),
                      ),
                      for (final item in areas)
                        _locationCard(
                          title: item.name,
                          subtitle:
                              'City/District: ${city.name} · '
                              'Boundary points: ${item.boundary.length}',
                          active: item.isServiceActive,
                          icon: Icons.grid_view,
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

  Widget _buildLocalities() {
    return StreamBuilder<List<ServiceCity>>(
      stream: _service.watchCities(),
      builder: (context, citySnapshot) {
        if (!citySnapshot.hasData) {
          if (citySnapshot.hasError) {
            return _emptyState('${citySnapshot.error}');
          }
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
          children: [
            for (final city in citySnapshot.data!)
              StreamBuilder<List<ServiceArea>>(
                stream: _service.watchAreas(city.id),
                builder: (context, areaSnapshot) {
                  if (!areaSnapshot.hasData) {
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
                            if (!snapshot.hasData) {
                              return const SizedBox.shrink();
                            }

                            final items = snapshot.data!
                                .where((item) => _matches(
                                      '${item.name} ${item.pincode} '
                                      '${area.name} ${city.name}',
                                    ))
                                .toList();

                            return Column(
                              children: [
                                for (final item in items)
                                  _locationCard(
                                    title: item.name,
                                    subtitle:
                                        '${city.name} · ${area.name}'
                                        '${item.pincode.isEmpty ? "" : " · PIN ${item.pincode}"}',
                                    active: item.isServiceActive,
                                    icon: Icons.place_outlined,
                                    onToggle: (value) async {
                                      try {
                                        await _service.setLocalityServiceStatus(
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

  Widget _buildImports() {
    return StreamBuilder<List<ServiceLocationImport>>(
      stream: _service.watchImports(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _emptyState('Unable to load import history.');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data!
            .where((item) => _matches(
                  '${item.fileName} ${item.source} ${item.status}',
                ))
            .toList();

        if (items.isEmpty) return _emptyState('No import records found.');

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
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

  Widget _locationCard({
    required String title,
    required String subtitle,
    required bool active,
    required IconData icon,
    required ValueChanged<bool> onToggle,
  }) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _locationOrange.withValues(alpha: 0.12),
          child: Icon(icon, color: _locationOrange),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        isThreeLine: subtitle.contains('\n'),
        trailing: Switch(
          value: active,
          activeThumbColor: _locationOrange,
          onChanged: onToggle,
        ),
      ),
    );
  }

  Future<void> _showAddLocationDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddLocationDialog(
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

class _AddLocationDialog extends StatefulWidget {
  const _AddLocationDialog({
    required this.service,
    required this.onSaved,
  });

  final ServiceLocationService service;
  final ValueChanged<int> onSaved;

  @override
  State<_AddLocationDialog> createState() => _AddLocationDialogState();
}

class _AddLocationDialogState extends State<_AddLocationDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _pincodeController = TextEditingController();

  int _level = 0;
  String? _countryId;
  String? _stateId;
  String? _cityId;
  String? _areaId;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  String get _levelName {
    switch (_level) {
      case 0:
        return 'Country';
      case 1:
        return 'State';
      case 2:
        return 'City / District';
      case 3:
        return 'Area / Sub-district';
      default:
        return 'Locality / Village';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final name = _nameController.text.trim();
      var savedTab = _level;

      switch (_level) {
        case 0:
          await widget.service.saveCountry(
            ServiceCountry(
              name: name,
              code: _codeController.text.trim().toUpperCase(),
              isActive: false,
            ),
          );
          break;

        case 1:
          await widget.service.saveState(
            ServiceState(
              countryId: _countryId!,
              name: name,
              isActive: false,
            ),
          );
          break;

        case 2:
          await widget.service.saveCity(
            ServiceCity(
              countryId: _countryId!,
              stateId: _stateId!,
              name: name,
              isServiceActive: false,
            ),
          );
          break;

        case 3:
          final city = await widget.service.getCity(_cityId!);

          if (city == null) {
            throw StateError('Selected city/district no longer exists.');
          }

          await widget.service.saveArea(
            ServiceArea(
              countryId: city.countryId,
              stateId: city.stateId,
              cityId: city.id,
              name: name,
              isServiceActive: false,
            ),
          );
          break;

        case 4:
          final city = await widget.service.getCity(_cityId!);

          if (city == null) {
            throw StateError('Selected city/district no longer exists.');
          }

          await widget.service.saveLocality(
            ServiceLocality(
              countryId: city.countryId,
              stateId: city.stateId,
              cityId: city.id,
              areaId: _areaId!,
              name: name,
              pincode: _pincodeController.text.trim(),
              isServiceActive: false,
            ),
          );
          break;
      }

      if (!mounted) return;

      Navigator.of(context).pop();
      widget.onSaved(savedTab);
    } catch (error) {
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unable to save location'),
          content: Text(error.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        items: items,
        onChanged: onChanged,
        validator: (value) => value == null ? 'Please select $label' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Location'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: _level,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Location type',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(
                    5,
                    (index) => DropdownMenuItem(
                      value: index,
                      child: Text([
                        'Country',
                        'State',
                        'City / District',
                        'Area / Sub-district',
                        'Locality / Village',
                      ][index]),
                    ),
                  ),
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            _level = value;
                            _countryId = null;
                            _stateId = null;
                            _cityId = null;
                            _areaId = null;
                            _nameController.clear();
                            _codeController.clear();
                            _pincodeController.clear();
                          });
                        },
                ),
                const SizedBox(height: 12),

                if (_level >= 1)
                  StreamBuilder<List<ServiceCountry>>(
                    stream: widget.service.watchCountries(),
                    builder: (context, snapshot) {
                      final countries = snapshot.data ?? [];

                      return _dropdown<String>(
                        label: 'Country',
                        value: _countryId,
                        items: countries
                            .map(
                              (country) => DropdownMenuItem(
                                value: country.id,
                                child: Text(
                                  '${country.name} (${country.code})',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _countryId = value;
                            _stateId = null;
                            _cityId = null;
                            _areaId = null;
                          });
                        },
                      );
                    },
                  ),

                if (_level >= 2 && _countryId != null)
                  StreamBuilder<List<ServiceState>>(
                    stream: widget.service.watchStates(_countryId!),
                    builder: (context, snapshot) {
                      final states = snapshot.data ?? [];

                      return _dropdown<String>(
                        label: 'State',
                        value: _stateId,
                        items: states
                            .map(
                              (state) => DropdownMenuItem(
                                value: state.id,
                                child: Text(state.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _stateId = value;
                            _cityId = null;
                            _areaId = null;
                          });
                        },
                      );
                    },
                  ),

                if (_level >= 3 && _countryId != null && _stateId != null)
                  StreamBuilder<List<ServiceCity>>(
                    stream: widget.service.watchCities(
                      countryId: _countryId,
                      stateId: _stateId,
                    ),
                    builder: (context, snapshot) {
                      final cities = snapshot.data ?? [];

                      return _dropdown<String>(
                        label: 'City / District',
                        value: _cityId,
                        items: cities
                            .map(
                              (city) => DropdownMenuItem(
                                value: city.id,
                                child: Text(city.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _cityId = value;
                            _areaId = null;
                          });
                        },
                      );
                    },
                  ),

                if (_level >= 4 && _cityId != null)
                  StreamBuilder<List<ServiceArea>>(
                    stream: widget.service.watchAreas(_cityId!),
                    builder: (context, snapshot) {
                      final areas = snapshot.data ?? [];

                      return _dropdown<String>(
                        label: 'Area / Sub-district',
                        value: _areaId,
                        items: areas
                            .map(
                              (area) => DropdownMenuItem(
                                value: area.id,
                                child: Text(area.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => _areaId = value);
                        },
                      );
                    },
                  ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: '$_levelName name',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter $_levelName name';
                    }
                    return null;
                  },
                ),

                if (_level == 0) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Country code (e.g. IN)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter country code';
                      }
                      return null;
                    },
                  ),
                ],

                if (_level == 4) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pincodeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'PIN code (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'This location will be saved as inactive. '
                    'City, Area and Locality require a verified '
                    'geographic boundary before activation.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: Text(_saving ? 'Saving...' : 'Save Location'),
          style: FilledButton.styleFrom(
            backgroundColor: _locationOrange,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

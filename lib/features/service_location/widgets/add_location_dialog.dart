import 'package:flutter/material.dart';

import '../models/location_selection_state.dart';
import '../models/service_location_models.dart';
import '../services/add_location_data_source.dart';
import '../services/optional_indian_pincode_validator.dart';

const Color _addLocationOrange = Color(0xFFFF7900);

class AddLocationDialog extends StatefulWidget {
  const AddLocationDialog({
    super.key,
    required this.service,
    required this.onSaved,
  });

  final AddLocationDataSource service;
  final ValueChanged<int> onSaved;

  @override
  State<AddLocationDialog> createState() =>
      _AddLocationDialogState();
}

class _AddLocationDialogState extends State<AddLocationDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _pincodeController = TextEditingController();

  int _level = 1;

  LocationSelectionState _selection = const LocationSelectionState();

  bool _saving = false;

  static const List<String> _locationTypes = [
    'Country',
    'State',
    'District',
    'City',
    'Area / Sub-district',
    'Locality / Village',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  String get _levelName => _locationTypes[_level];

  Future<void> _save() async {
    if (_saving) return;

    if (_selection.countryId == null || _selection.countryId!.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('India setup required'),
          content: const Text(
            'The India (IN) country master record could not be loaded. '
            'Please check the country master before adding this location.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final name = _nameController.text.trim();

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
              countryId: _selection.countryId!,
              name: name,
              isActive: false,
            ),
          );
          break;

        case 2:
          await widget.service.saveDistrict(
            ServiceDistrict(
              countryId: _selection.countryId!,
              stateId: _selection.stateId!,
              name: name,
              isActive: false,
            ),
          );
          break;

        case 3:
          await widget.service.saveCity(
            ServiceCity(
              countryId: _selection.countryId!,
              stateId: _selection.stateId!,
              districtId: _selection.districtId!,
              name: name,
              isServiceActive: false,
            ),
          );
          break;

        case 4:
          final city = await widget.service.getCity(_selection.cityId!);

          if (city == null) {
            throw StateError(
              'Selected city/district no longer exists.',
            );
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

        case 5:
          final city = await widget.service.getCity(_selection.cityId!);

          if (city == null) {
            throw StateError(
              'Selected city/district no longer exists.',
            );
          }

          await widget.service.saveLocality(
            ServiceLocality(
              countryId: city.countryId,
              stateId: city.stateId,
              cityId: city.id,
              areaId: _selection.areaId!,
              name: name,
              pincode: _pincodeController.text.trim(),
              isServiceActive: false,
            ),
          );
          break;
      }

      if (!mounted) return;

      Navigator.of(context).pop();
      widget.onSaved(_level);
    } catch (error) {
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Unable to save location'),
          content: SelectableText(error.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _dropdownStatus(String message, {bool loading = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (loading) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: loading ? Colors.black54 : Colors.red.shade700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    Key? key,
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T>(
        key: key,
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFFFD8B8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFFFD8B8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _addLocationOrange, width: 1.8),
          ),
        ),
        items: items,
        onChanged: _saving ? null : onChanged,
        validator: (value) =>
            value == null ? 'Please select $label' : null,
      ),
    );
  }

  Widget _buildCountryDropdown() {
    return StreamBuilder<List<ServiceCountry>>(
      stream: widget.service.watchCountries(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _dropdownStatus('Unable to load India country record: ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return _dropdownStatus('Loading India setup…', loading: true);
        }

        final matches = snapshot.data!.where((country) =>
            country.code.trim().toUpperCase() == 'IN' ||
            country.name.trim().toLowerCase() == 'india').toList()
          ..sort((a, b) {
            final aExact = a.code.trim().toUpperCase() == 'IN' ? 0 : 1;
            final bExact = b.code.trim().toUpperCase() == 'IN' ? 0 : 1;
            return aExact.compareTo(bExact);
          });

        if (matches.isEmpty) {
          return _dropdownStatus(
            'India is not configured in the country master yet. '
            'Add the India master record before adding State or lower locations.',
          );
        }

        final india = matches.first;
        if (_selection.countryId != india.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _saving || _selection.countryId == india.id) return;
            setState(() {
              _selection = _selection.selectCountry(india.id);
            });
          });
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFFD8B8)),
          ),
          child: const Row(
            children: [
              Text('🇮🇳', style: TextStyle(fontSize: 22)),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('India', style: TextStyle(fontWeight: FontWeight.w800)),
                    SizedBox(height: 2),
                    Text('Country fixed • Code IN',
                        style: TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
              Icon(Icons.lock_outline, size: 18, color: _addLocationOrange),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStateDropdown() {
    if (_selection.countryId == null) {
      return _dropdown<String>(
        label: 'State',
        value: null,
        items: const [],
        onChanged: (_) {},
      );
    }

    return StreamBuilder<List<ServiceState>>(
      stream: widget.service.watchStates(countryId: _selection.countryId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _dropdownStatus('Unable to load states: ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return _dropdownStatus('Loading states…', loading: true);
        }
        final states = snapshot.data!;

        return _dropdown<String>(
          key: ValueKey<String>('state-${_selection.countryId}'),
          label: 'State',
          value: retainAvailableSelection(
            _selection.stateId,
            states.map((state) => state.id),
          ),
          items: states
              .map(
                (state) => DropdownMenuItem<String>(
                  value: state.id,
                  child: Text(state.name),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              _selection = _selection.selectState(value);
            });
          },
        );
      },
    );
  }

  Widget _buildDistrictDropdown() {
    if (_selection.countryId == null || _selection.stateId == null) {
      return _dropdown<String>(
        label: 'District',
        value: null,
        items: const [],
        onChanged: (_) {},
      );
    }

    return StreamBuilder<List<ServiceDistrict>>(
      stream: widget.service.watchDistricts(
        countryId: _selection.countryId,
        stateId: _selection.stateId,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _dropdownStatus('Unable to load Districts: ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return _dropdownStatus('Loading Districts…', loading: true);
        }
        final districts = snapshot.data!;

        return _dropdown<String>(
          key: ValueKey<String>(
            'district-${_selection.countryId}-${_selection.stateId}',
          ),
          label: 'District',
          value: retainAvailableSelection(
            _selection.districtId,
            districts.map((district) => district.id),
          ),
          items: districts
              .map((district) => DropdownMenuItem<String>(
                    value: district.id,
                    child: Text(district.name),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selection = _selection.selectDistrict(value);
            });
          },
        );
      },
    );
  }

  Widget _buildCityDropdown() {
    if (_selection.countryId == null || _selection.stateId == null ||
        _selection.districtId == null) {
      return _dropdown<String>(
        label: 'City',
        value: null,
        items: const [],
        onChanged: (_) {},
      );
    }
    return StreamBuilder<List<ServiceCity>>(
      stream: widget.service.watchCities(
        countryId: _selection.countryId,
        stateId: _selection.stateId,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _dropdownStatus('Unable to load Cities: ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return _dropdownStatus('Loading Cities…', loading: true);
        }
        final cities = snapshot.data!
            .where((city) => city.districtId == _selection.districtId)
            .toList();
        return _dropdown<String>(
          key: ValueKey<String>('city-${_selection.districtId}'),
          label: 'City',
          value: retainAvailableSelection(_selection.cityId, cities.map((c) => c.id)),
          items: cities.map((city) => DropdownMenuItem<String>(
            value: city.id,
            child: Text(city.name),
          )).toList(),
          onChanged: (value) {
            setState(() => _selection = _selection.selectCity(value));
          },
        );
      },
    );
  }

  Widget _buildAreaDropdown() {
    if (_selection.cityId == null) {
      return _dropdown<String>(
        label: 'Area / Sub-district',
        value: null,
        items: const [],
        onChanged: (_) {},
      );
    }

    return StreamBuilder<List<ServiceArea>>(
      stream: widget.service.watchAreas(cityId: _selection.cityId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _dropdownStatus('Unable to load areas/sub-districts: ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return _dropdownStatus('Loading areas/sub-districts…', loading: true);
        }
        final areas = snapshot.data!;

        return _dropdown<String>(
          key: ValueKey<String>('area-${_selection.cityId}'),
          label: 'Area / Sub-district',
          value: retainAvailableSelection(
            _selection.areaId,
            areas.map((area) => area.id),
          ),
          items: areas
              .map(
                (area) => DropdownMenuItem<String>(
                  value: area.id,
                  child: Text(area.name),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() => _selection = _selection.selectArea(value));
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isCompact = screenSize.width < 600;
    final dialogWidth = isCompact
        ? (screenSize.width - 32).clamp(280.0, 560.0).toDouble()
        : 560.0;

    return AlertDialog(
      constraints: BoxConstraints(
        maxWidth: 600,
        maxHeight: screenSize.height * (isCompact ? 0.88 : 0.86),
      ),
      backgroundColor: const Color(0xFFFFFCF8),
      surfaceTintColor: Colors.transparent,
      elevation: 24,
      shadowColor: _addLocationOrange.withValues(alpha: 0.24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: BorderSide(
          color: _addLocationOrange.withValues(alpha: 0.22),
          width: 1.2,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFB66D), _addLocationOrange, Color(0xFFE75E00)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _addLocationOrange.withValues(alpha: 0.30),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_location_alt_outlined,
              color: _addLocationOrange,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add Location',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 3),
                Text(
                  'Create an inactive service-location record',
                  style: TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: dialogWidth,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD8B8)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.account_tree_outlined,
                          size: 18, color: _addLocationOrange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _level == 0
                              ? 'Start with the country. It will be saved inactive; activation is a separate admin action.'
                              : 'Choose the existing parent locations first. The new record will be saved inactive.',
                          style: const TextStyle(fontSize: 12, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
                DropdownButtonFormField<int>(
                  initialValue: _level,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Location type',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFFFD8B8)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFFFD8B8)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _addLocationOrange, width: 1.8),
                    ),
                  ),
                  items: List.generate(
                    _locationTypes.length - 1,
                    (index) => DropdownMenuItem<int>(
                      value: index + 1,
                      child: Text(_locationTypes[index + 1]),
                    ),
                  ),
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value == null) return;

                          setState(() {
                            _level = value;
                            _selection = const LocationSelectionState();

                            _nameController.clear();
                            _codeController.clear();
                            _pincodeController.clear();
                          });
                        },
                ),

                const SizedBox(height: 12),

                if (_level >= 1) _buildCountryDropdown(),

                if (_level >= 2) _buildStateDropdown(),

                if (_level >= 3) _buildDistrictDropdown(),
                if (_level >= 3) _buildCityDropdown(),
                // Area is created under a selected City; only Locality needs
                // an existing Area as its parent. Never show an Area selector
                // while creating an Area record itself.
                if (_level == 5) _buildAreaDropdown(),

                const SizedBox(height: 4),

                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: '$_levelName name',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFFFD8B8)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFFFD8B8)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _addLocationOrange, width: 1.8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter $_levelName name';
                    }
                    return null;
                  },
                ),

                if (_level == 5) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pincodeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'PIN code (optional)',
                      helperText: 'Leave blank or enter a 6-digit Indian PIN code',
                      border: OutlineInputBorder(),
                    ),
                    validator: validateOptionalIndianPincode,
                  ),
                ],

                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFF0E1), Colors.white],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _addLocationOrange.withValues(alpha: 0.28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _addLocationOrange.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Safety check: this record is saved as inactive. '
                    'City and Area activation requires a verified geographic boundary. '
                    'Saving here does not verify or activate coverage.',
                    style: TextStyle(fontSize: 12, height: 1.4),
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
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(_saving ? 'Saving...' : 'Save Location'),
          style: FilledButton.styleFrom(
            backgroundColor: _addLocationOrange,
            foregroundColor: Colors.white,
            elevation: 5,
            shadowColor: _addLocationOrange.withValues(alpha: 0.32),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}

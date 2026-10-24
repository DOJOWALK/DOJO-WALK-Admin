import 'package:flutter/material.dart';

class AddLocationScreen extends StatefulWidget {
  const AddLocationScreen({super.key});

  @override
  State<AddLocationScreen> createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends State<AddLocationScreen> {
  String? _state;
  String? _district;
  String? _city;
  String? _area;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Service Location')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Service Location Setup',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose the location hierarchy in order. Live catalog data and '
              'save/activation actions will be connected after backend contracts '
              'and permissions are verified.',
            ),
            const SizedBox(height: 24),
            _SelectionField(
              label: 'Country',
              value: 'India',
              options: const ['India'],
              onChanged: (_) {},
            ),
            const SizedBox(height: 16),
            _SelectionField(
              label: 'State / Union Territory',
              value: _state,
              options: const [],
              onChanged: (value) => setState(() {
                _state = value;
                _district = null;
                _city = null;
                _area = null;
              }),
            ),
            const SizedBox(height: 16),
            _SelectionField(
              label: 'District',
              value: _district,
              options: const [],
              onChanged: (value) => setState(() {
                _district = value;
                _city = null;
                _area = null;
              }),
            ),
            const SizedBox(height: 16),
            _SelectionField(
              label: 'City',
              value: _city,
              options: const [],
              onChanged: (value) => setState(() {
                _city = value;
                _area = null;
              }),
            ),
            const SizedBox(height: 16),
            _SelectionField(
              label: 'Area',
              value: _area,
              options: const [],
              onChanged: (value) => setState(() => _area = value),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0E2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFD2AD)),
              ),
              child: const Text(
                'Activation rule: an Area requires a reviewed and verified '
                'boundary polygon. A radius-only circle cannot activate coverage. '
                'This preview does not save data or activate a service area.',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.map_outlined),
              label: const Text('Verify Boundary (integration pending)'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionField extends StatelessWidget {
  const _SelectionField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: options
          .map((option) => DropdownMenuItem(
                value: option,
                child: Text(option),
              ))
          .toList(),
      onChanged: options.isEmpty ? null : onChanged,
    );
  }
}

import 'package:flutter/material.dart';

/// UI-only directory preview. The records are illustrative and are not live data.
class ZoneDirectoryScreen extends StatefulWidget {
  const ZoneDirectoryScreen({super.key});

  @override
  State<ZoneDirectoryScreen> createState() => _ZoneDirectoryScreenState();
}

class _ZoneDirectoryScreenState extends State<ZoneDirectoryScreen> {
  static const _orange = Color(0xFFFF7900);
  static const _ink = Color(0xFF252525);

  final _search = TextEditingController();
  String _status = 'All';

  final List<_ZoneRow> _examples = const [
    _ZoneRow('Example Zone A', 'Example City', 'Pending review', 'Revision 1'),
    _ZoneRow('Example Zone B', 'Example City', 'Needs changes', 'Revision 2'),
    _ZoneRow('Example Zone C', 'Example City', 'Not activated', 'Revision 1'),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final rows = _examples.where((row) {
      final matchesQuery =
          query.isEmpty || '${row.name} ${row.city}'.toLowerCase().contains(query);
      final matchesStatus = _status == 'All' || row.status == _status;
      return matchesQuery && matchesStatus;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF5),
      appBar: AppBar(
        title: const Text('Zone Directory'),
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        surfaceTintColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Service Zone Directory',
                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: _ink),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Browse zone status and revisions. Only Zones can be activated or deactivated. '
                  'This preview uses sample rows; it is not connected to Firestore.',
                  style: TextStyle(color: Colors.black54, height: 1.5),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search zone or city',
                    prefixIcon: const Icon(Icons.search, color: _orange),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['All', 'Pending review', 'Needs changes', 'Not activated']
                      .map((status) => ChoiceChip(
                            label: Text(status),
                            selected: _status == status,
                            selectedColor: _orange.withValues(alpha: 0.15),
                            onSelected: (_) => setState(() => _status = status),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                if (rows.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('No example zones match this filter.')),
                    ),
                  )
                else
                  ...rows.map((row) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, color: _orange),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      row.name,
                                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  _StatusLabel(row.status),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 18,
                                runSpacing: 8,
                                children: [
                                  _Meta('City', row.city),
                                  _Meta('Revision', row.revision),
                                  _Meta('Zone ID', 'Not assigned in preview'),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Activation, deactivation and approval actions remain disabled until '
                                'the authoritative Zone service, permissions and audit logging are connected.',
                                style: TextStyle(color: Colors.black54, fontSize: 12, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      )),
                const SizedBox(height: 8),
                const Text(
                  'Mock data only — no zone has been created, approved or activated.',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ZoneRow {
  const _ZoneRow(this.name, this.city, this.status, this.revision);
  final String name;
  final String city;
  final String status;
  final String revision;
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel(this.status);
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = status == 'Pending review'
        ? Colors.orange
        : status == 'Needs changes'
            ? Colors.red
            : Colors.blueGrey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 11)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      );
}

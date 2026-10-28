import 'package:flutter/material.dart';

/// UI-only audit history prototype based on DOJO WALK POL-040.
/// This screen uses illustrative rows only; it does not read live audit_logs.
class ZoneAuditHistoryScreen extends StatefulWidget {
  const ZoneAuditHistoryScreen({super.key});

  @override
  State<ZoneAuditHistoryScreen> createState() => _ZoneAuditHistoryScreenState();
}

class _ZoneAuditHistoryScreenState extends State<ZoneAuditHistoryScreen> {
  static const _orange = Color(0xFFFF7900);
  static const _background = Color(0xFFFFFAF5);
  final _searchController = TextEditingController();
  String _query = '';


  final List<_AuditEntry> _entries = const [
    _AuditEntry(
      event: 'Zone readiness submitted',
      zone: 'Illustrative Zone A',
      actor: 'Central Admin',
      status: 'Submitted',
      time: 'Example · 28 Oct 2026, 10:15 IST',
      icon: Icons.upload_file_outlined,
    ),
    _AuditEntry(
      event: 'Boundary revision requested',
      zone: 'Illustrative Zone B',
      actor: 'Founder / CEO',
      status: 'Needs changes',
      time: 'Example · 28 Oct 2026, 09:42 IST',
      icon: Icons.edit_location_alt_outlined,
    ),
    _AuditEntry(
      event: 'Zone suspended for safety review',
      zone: 'Illustrative Zone C',
      actor: 'Central Admin',
      status: 'Suspended',
      time: 'Example · 27 Oct 2026, 18:30 IST',
      icon: Icons.pause_circle_outline,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _entries.where((entry) {
      final haystack = '${entry.event} ${entry.zone} ${entry.actor} ${entry.status}'.toLowerCase();
      return haystack.contains(_query.toLowerCase().trim());
    }).toList();

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Zone Audit History'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF252525),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              border: Border.all(color: Colors.amber.shade200),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.brown),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'UI preview only. These sample entries are not real audit records. '
                    'Live audit_logs connection and server-side pagination are not connected yet.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Search event, zone, actor or status',
              prefixIcon: const Icon(Icons.search, color: _orange),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFECE5DE)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFECE5DE)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Recent events',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              Text('${visible.length} examples', style: const TextStyle(color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 8),
          if (visible.isEmpty)
            const Card(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 32, color: Colors.black45),
                    SizedBox(height: 8),
                    Text('No matching example events'),
                  ],
                ),
              ),
            )
          else
            ...visible.map((entry) => Card(
              color: Colors.white,
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFFECE5DE)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                leading: CircleAvatar(
                  backgroundColor: _orange.withValues(alpha: 0.12),
                  child: Icon(entry.icon, color: _orange),
                ),
                title: Text(entry.event, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('${entry.zone}\nActor: ${entry.actor}\n${entry.time}'),
                ),
                isThreeLine: true,
                trailing: Container(
                  constraints: const BoxConstraints(maxWidth: 105),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F1EC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(entry.status, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
                ),
              ),
            )),
        ],
      ),
    );
  }
}

class _AuditEntry {
  const _AuditEntry({
    required this.event,
    required this.zone,
    required this.actor,
    required this.status,
    required this.time,
    required this.icon,
  });

  final String event;
  final String zone;
  final String actor;
  final String status;
  final String time;
  final IconData icon;
}

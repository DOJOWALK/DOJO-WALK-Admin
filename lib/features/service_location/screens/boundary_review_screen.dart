import 'package:flutter/material.dart';

/// UI-only boundary review queue prototype.
/// No records are loaded, approved, rejected, or changed on the server.
class BoundaryReviewScreen extends StatefulWidget {
  const BoundaryReviewScreen({super.key});

  @override
  State<BoundaryReviewScreen> createState() => _BoundaryReviewScreenState();
}

class _BoundaryReviewScreenState extends State<BoundaryReviewScreen> {
  static const _orange = Color(0xFFFF7900);
  static const _ink = Color(0xFF252525);
  String _filter = 'All';

  // Illustrative rows only. Never treat these as live service-location records.
  final List<_ReviewItem> _examples = const [
    _ReviewItem(
      zone: 'Example Zone A',
      city: 'Example City',
      owner: 'Central Admin',
      status: 'Pending review',
      revision: 'Revision 1',
      boundary: 'Not verified',
    ),
    _ReviewItem(
      zone: 'Example Zone B',
      city: 'Example City',
      owner: 'Central Admin',
      status: 'Needs changes',
      revision: 'Revision 2',
      boundary: 'Hash changed',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final items = _filter == 'All'
        ? _examples
        : _examples.where((item) => item.status == _filter).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF5),
      appBar: AppBar(
        title: const Text('Boundary Review'),
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
                  'Zone boundary review',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Central Admin checks zone readiness and evidence. '
                  'Founder/CEO remains the final business approver for launch. '
                  'This screen is a UI preview; it is not connected to live records.',
                  style: TextStyle(color: Colors.black54, height: 1.5),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFD2AC)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Required before approval',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      SizedBox(height: 10),
                      _Requirement('Zone polygon exists and is valid'),
                      _Requirement('Boundary revision and hash are recorded'),
                      _Requirement('State / UT → District → City hierarchy is confirmed'),
                      _Requirement('Readiness evidence and audit trail are available'),
                      _Requirement('Founder/CEO decision is bound to this Zone revision'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['All', 'Pending review', 'Needs changes'].map((value) {
                    final selected = _filter == value;
                    return ChoiceChip(
                      label: Text(value),
                      selected: selected,
                      selectedColor: _orange.withValues(alpha: 0.15),
                      onSelected: (_) => setState(() => _filter = value),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Center(child: Text('No example items in this filter.')),
                    ),
                  )
                else
                  ...items.map((item) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.map_outlined, color: _orange),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item.zone,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  _StatusPill(item.status),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 18,
                                runSpacing: 8,
                                children: [
                                  _Detail('City', item.city),
                                  _Detail('Submitted by', item.owner),
                                  _Detail('Revision', item.revision),
                                  _Detail('Boundary', item.boundary),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Actions are disabled in this prototype. Connect the review service '
                                'and permission checks before enabling decisions.',
                                style: TextStyle(color: Colors.black54, fontSize: 12),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: null,
                                    icon: const Icon(Icons.fact_check_outlined),
                                    label: const Text('Review evidence'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: null,
                                    icon: const Icon(Icons.edit_note_outlined),
                                    label: const Text('Request changes'),
                                  ),
                                  FilledButton.icon(
                                    onPressed: null,
                                    icon: const Icon(Icons.verified_outlined),
                                    label: const Text('Founder decision'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )),
                const SizedBox(height: 8),
                const Text(
                  'Important: example rows are mock data, not actual pending zones. No approval or activation can be performed here.',
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

class _ReviewItem {
  const _ReviewItem({
    required this.zone,
    required this.city,
    required this.owner,
    required this.status,
    required this.revision,
    required this.boundary,
  });

  final String zone;
  final String city;
  final String owner;
  final String status;
  final String revision;
  final String boundary;
}

class _Requirement extends StatelessWidget {
  const _Requirement(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle_outline, size: 18, color: _orange),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
      );

  static const _orange = Color(0xFFFF7900);
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF2E7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFD2AC)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8A4300),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _Detail extends StatelessWidget {
  const _Detail(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 210,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
            const SizedBox(height: 3),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

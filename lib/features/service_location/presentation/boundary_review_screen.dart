import 'package:flutter/material.dart';

import '../data/admin_boundary_review_repository.dart';

class BoundaryReviewScreen extends StatefulWidget {
  const BoundaryReviewScreen({super.key});

  @override
  State<BoundaryReviewScreen> createState() => _BoundaryReviewScreenState();
}

class _BoundaryReviewScreenState extends State<BoundaryReviewScreen> {
  final _repository = AdminBoundaryReviewRepository();
  final Set<String> _reviewing = <String>{};

  Future<void> _review(AdminBoundaryReviewItem item, {required bool approve}) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final notes = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(approve ? 'Verify boundary?' : 'Reject boundary?'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  approve
                      ? 'Approve only after confirming the polygon source and actual geographic boundary.'
                      : 'Explain what must be corrected before resubmission.',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  autofocus: true,
                  maxLength: 2000,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Review notes (required)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'Review notes are required.';
                    if (text.length > 2000) return 'Maximum 2000 characters.';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: Text(approve ? 'Confirm Verify' : 'Confirm Reject'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (notes == null || !mounted) return;

    setState(() => _reviewing.add(item.id));
    try {
      await _repository.review(
        boundaryId: item.id,
        approve: approve,
        notes: notes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? 'Boundary verified by trusted backend. Service is not automatically activated.'
                : 'Boundary rejected. Notes saved by trusted backend.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Review failed: ${error.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _reviewing.remove(item.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Boundary Review',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pending City/Area polygons. Review the original source and geographic coverage before deciding. '
            'The backend re-validates polygon geometry and Area-within-City containment.',
          ),
          const SizedBox(height: 14),
          const _ReviewWarning(),
          const SizedBox(height: 18),
          StreamBuilder<List<AdminBoundaryReviewItem>>(
            stream: _repository.watchPending(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _MessageCard(
                  icon: Icons.lock_outline,
                  message:
                      'Boundary list load nahi hui. Active super_admin access, Firestore Rules aur connection check karein. '
                      '${snapshot.error}',
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final items = snapshot.data!;
              if (items.isEmpty) {
                return const _MessageCard(
                  icon: Icons.verified_outlined,
                  message: 'Abhi koi pending City/Area boundary nahi hai.',
                );
              }
              return Column(
                children: items.map((item) => _BoundaryCard(
                  item: item,
                  busy: _reviewing.contains(item.id),
                  onApprove: () => _review(item, approve: true),
                  onReject: () => _review(item, approve: false),
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReviewWarning extends StatelessWidget {
  const _ReviewWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0E2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD2AD)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Color(0xFFB45309)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Yeh outline sirf polygon shape ka preview hai, map par exact jagah ka proof nahi. '
              'Source/reference ko independently check kiye bina Verify na karein. Verification se City/Area active nahi hota.',
            ),
          ),
        ],
      ),
    );
  }
}

class _BoundaryCard extends StatelessWidget {
  const _BoundaryCard({
    required this.item,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final AdminBoundaryReviewItem item;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.polyline, color: Color(0xFFFF7900), size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${item.locationType.toUpperCase()} • ${item.locationId}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Chip(label: Text('${item.points.length} points')),
              ],
            ),
            const SizedBox(height: 12),
            Text('Boundary ID: ${item.id}'),
            const SizedBox(height: 6),
            Text('Source type: ${item.sourceType}'),
            Text('Source name: ${item.sourceName.isEmpty ? 'Missing' : item.sourceName}'),
            Text('Source reference: ${item.sourceReference.isEmpty ? 'Missing' : item.sourceReference}'),
            const SizedBox(height: 14),
            Container(
              height: 160,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFAF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD2AD)),
              ),
              child: item.points.length < 3
                  ? const Center(child: Text('Polygon preview unavailable: fewer than 3 points.'))
                  : CustomPaint(
                      painter: _PolygonPreviewPainter(item.points),
                      child: const Center(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Text(
                            'Shape preview only — not a geographic map',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('View polygon coordinates'),
              children: [
                for (var i = 0; i < item.points.length; i++)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('${i + 1}. ${item.points[i]}'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: busy ? null : onReject,
                  icon: const Icon(Icons.close),
                  label: const Text('Reject'),
                ),
                FilledButton.icon(
                  onPressed: busy || item.points.length < 3 ||
                          item.sourceName.trim().isEmpty ||
                          item.sourceReference.trim().isEmpty
                      ? null
                      : onApprove,
                  icon: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.verified_outlined),
                  label: const Text('Verify Boundary'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PolygonPreviewPainter extends CustomPainter {
  const _PolygonPreviewPainter(this.coordinates);

  final List<String> coordinates;

  @override
  void paint(Canvas canvas, Size size) {
    final points = <Offset>[];
    for (final coordinate in coordinates) {
      final parts = coordinate.split(',');
      if (parts.length != 2) continue;
      final lat = double.tryParse(parts[0].trim());
      final lng = double.tryParse(parts[1].trim());
      if (lat == null || lng == null) continue;
      points.add(Offset(lng, lat));
    }
    if (points.length < 3) return;

    final minX = points.map((p) => p.dx).reduce((a, b) => a < b ? a : b);
    final maxX = points.map((p) => p.dx).reduce((a, b) => a > b ? a : b);
    final minY = points.map((p) => p.dy).reduce((a, b) => a < b ? a : b);
    final maxY = points.map((p) => p.dy).reduce((a, b) => a > b ? a : b);
    final spanX = (maxX - minX).abs() < 0.000001 ? 0.000001 : (maxX - minX);
    final spanY = (maxY - minY).abs() < 0.000001 ? 0.000001 : (maxY - minY);
    const inset = 18.0;
    final scaleX = (size.width - inset * 2) / spanX;
    final scaleY = (size.height - inset * 2 - 20) / spanY;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    final polygon = points.map((point) => Offset(
      inset + (point.dx - minX) * scale,
      inset + (maxY - point.dy) * scale,
    )).toList();

    final path = Path()..moveTo(polygon.first.dx, polygon.first.dy);
    for (final point in polygon.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    path.close();
    final fill = Paint()
      ..color = const Color(0x33FF7900)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = const Color(0xFFFF7900)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _PolygonPreviewPainter oldDelegate) =>
      oldDelegate.coordinates != coordinates;
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFFFF7900)),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

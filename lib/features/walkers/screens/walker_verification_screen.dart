import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WalkerVerificationScreen extends StatefulWidget {
  const WalkerVerificationScreen({super.key});

  @override
  State<WalkerVerificationScreen> createState() =>
      _WalkerVerificationScreenState();
}

class _WalkerVerificationScreenState
    extends State<WalkerVerificationScreen> {
  String _filter = 'all';

  static const Color orange = Color(0xFFFF6A00);

  Future<void> _updateStatus({
    required String uid,
    required String status,
    String? reason,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final walkerRef = firestore.collection('walkers').doc(uid);

      await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(walkerRef);

        if (!snapshot.exists) {
          throw Exception('Walker application not found.');
        }

        final data = snapshot.data() ?? <String, dynamic>{};

        transaction.update(walkerRef, {
          'verificationStatus': status,
          'status': status == 'approved'
              ? 'approved'
              : status == 'rejected'
                  ? 'rejected'
                  : 'under_review',
          'isApproved': status == 'approved',
          'isActive': false,
          'verificationUpdatedAt': FieldValue.serverTimestamp(),
          if (reason != null) 'rejectionReason': reason,
        });

        // Keep the transaction tied to the existing application.
        if (data.isEmpty) {
          throw Exception('Walker application data is empty.');
        }
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Application updated: $status')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  Future<void> _reject(String uid) async {
    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Walker Application'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'Enter the reason',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                Navigator.pop(dialogContext, value);
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (reason == null || reason.trim().isEmpty) return;

    await _updateStatus(
      uid: uid,
      status: 'rejected',
      reason: reason.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Walker Verification',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Review walker applications and KYC status',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    value: _filter,
                    decoration: const InputDecoration(
                      labelText: 'Application status',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('All Applications'),
                      ),
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text('Pending'),
                      ),
                      DropdownMenuItem(
                        value: 'under_review',
                        child: Text('Under Review'),
                      ),
                      DropdownMenuItem(
                        value: 'approved',
                        child: Text('Approved'),
                      ),
                      DropdownMenuItem(
                        value: 'rejected',
                        child: Text('Rejected'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _filter = value);
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('walkers')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Unable to load walker applications.'),
                    );
                  }

                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: orange),
                    );
                  }

                  final documents = snapshot.data?.docs ?? [];

                  final filtered = documents.where((doc) {
                    final data = doc.data();
                    final status = (data['verificationStatus'] ??
                            data['status'] ??
                            'pending')
                        .toString()
                        .toLowerCase();

                    return _filter == 'all' || status == _filter;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('No applications found.'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final doc = filtered[index];
                      final data = doc.data();

                      final name =
                          (data['name'] ?? data['fullName'] ?? 'Unnamed Walker')
                              .toString();
                      final phone =
                          (data['phoneNumber'] ?? data['phone'] ?? '')
                              .toString();
                      final status =
                          (data['verificationStatus'] ??
                                  data['status'] ??
                                  'pending')
                              .toString()
                              .toLowerCase();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: Color(0xFFFFF0E5),
                                    child: Icon(
                                      Icons.directions_walk,
                                      color: orange,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(phone),
                                      ],
                                    ),
                                  ),
                                  _StatusBadge(status: status),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text('Walker ID: ${doc.id}'),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      showDialog<void>(
                                        context: context,
                                        builder: (dialogContext) =>
                                            AlertDialog(
                                          title: const Text(
                                            'Application Details',
                                          ),
                                          content: SingleChildScrollView(
                                            child: SelectableText(
                                              data.entries
                                                  .map((entry) =>
                                                      '${entry.key}: ${entry.value}')
                                                  .join('\n\n'),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(
                                                      dialogContext),
                                              child: const Text('Close'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.visibility_outlined),
                                    label: const Text('View Details'),
                                  ),
                                  if (status != 'approved')
                                    FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: orange,
                                      ),
                                      onPressed: () => _updateStatus(
                                        uid: doc.id,
                                        status: 'approved',
                                      ),
                                      icon: const Icon(Icons.check),
                                      label: const Text('Approve'),
                                    ),
                                  if (status != 'rejected')
                                    OutlinedButton.icon(
                                      onPressed: () => _reject(doc.id),
                                      icon: const Icon(Icons.close),
                                      label: const Text('Reject'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();

    final Color color = normalized == 'approved'
        ? Colors.green
        : normalized == 'rejected'
            ? Colors.red
            : normalized == 'under_review'
                ? Colors.blue
                : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        normalized.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

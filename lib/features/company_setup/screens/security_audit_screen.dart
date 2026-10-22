import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

const Color _auditOrange = Color(0xFFFF7900);
const Color _auditInk = Color(0xFF252525);

/// Read-only audit timeline. Privileged mutations are deliberately not exposed
/// here; all future approval actions must be backed by trusted audit writes.
class SecurityAuditScreen extends StatelessWidget {
  const SecurityAuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFFAF5),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Security & Audit',
                  style: TextStyle(
                    color: _auditInk,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Read the recorded administrative events. This view does not grant permissions or approve changes.',
                  style: TextStyle(color: Colors.black54, height: 1.5),
                ),
                const SizedBox(height: 20),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('audit_logs')
                      .orderBy('createdAt', descending: true)
                      .limit(50)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _stateCard(
                        icon: Icons.lock_outline_rounded,
                        title: 'Audit records unavailable',
                        message:
                            'The current account may not have audit-read permission, or the query requires backend/index configuration. No permission bypass is attempted.',
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return _stateCard(
                        icon: Icons.history_rounded,
                        title: 'No audit events yet',
                        message:
                            'No events were returned. Empty results do not prove that all admin workflows are audited.',
                      );
                    }
                    return Column(
                      children: docs.map((doc) {
                        final data = doc.data();
                        final action =
                            (data['action'] ?? 'Administrative event').toString();
                        final targetType =
                            (data['targetType'] ?? 'record').toString();
                        final targetId =
                            (data['targetId'] ?? 'Not recorded').toString();
                        final actor =
                            (data['actorUid'] ?? 'Actor not recorded').toString();
                        final createdAt = data['createdAt'];
                        final timestamp = createdAt is Timestamp
                            ? createdAt.toDate().toLocal().toString()
                            : 'Timestamp unavailable';
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: const Color(0xFFFFE2C8),
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: _auditOrange.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.history_rounded,
                                  color: _auditOrange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      action,
                                      style: const TextStyle(
                                        color: _auditInk,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Target: $targetType · $targetId',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Actor reference: $actor',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      timestamp,
                                      style: const TextStyle(
                                        color: Colors.black45,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _stateCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFFFE2C8)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _auditOrange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(message, style: const TextStyle(height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

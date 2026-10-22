import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

const Color _staffOrange = Color(0xFFFF7900);
const Color _staffInk = Color(0xFF252525);

/// Read-only view of currently provisioned admin accounts.
///
/// Creating identities and granting privileges must be performed by a trusted
/// backend workflow. Firestore rules currently deny client-side admin creation.
class StaffAdminAccessScreen extends StatelessWidget {
  const StaffAdminAccessScreen({super.key});

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
                  'Staff & Admin Access',
                  style: TextStyle(
                    color: _staffInk,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Review provisioned admin accounts and prepare verified staff onboarding.',
                  style: TextStyle(color: Colors.black54, height: 1.5),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF2E6),
                    border: Border.all(color: const Color(0xFFFFD6B0)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_outline_rounded, color: _staffOrange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Secure onboarding is not enabled yet',
                              style: TextStyle(
                                color: _staffInk,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Staff ID generation, identity-document verification, appointment approval and role grants must be handled by a trusted backend workflow. This screen intentionally does not create accounts or write staff records from the client.',
                              style: TextStyle(
                                color: _staffInk,
                                height: 1.5,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Provisioned admin accounts',
                  style: TextStyle(
                    color: _staffInk,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('admin_users')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _messageCard(
                        icon: Icons.lock_outline_rounded,
                        title: 'Access restricted',
                        message:
                            'Admin account records could not be loaded. Confirm that the signed-in user has the required server-enforced permission.',
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
                      return _messageCard(
                        icon: Icons.people_outline_rounded,
                        title: 'No admin accounts found',
                        message:
                            'No records were returned for the current account.',
                      );
                    }
                    return Column(
                      children: docs.map((doc) {
                        final data = doc.data();
                        final name = (data['displayName'] ??
                                data['name'] ??
                                'Admin account')
                            .toString();
                        final email = (data['email'] ?? 'Email not recorded')
                            .toString();
                        final role = (data['role'] ?? 'Unassigned').toString();
                        final active = data['isActive'] == true;
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
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _staffOrange.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.admin_panel_settings_rounded,
                                  color: _staffOrange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        color: _staffInk,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      email,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Account reference: ${doc.id}',
                                      style: const TextStyle(
                                        color: Colors.black45,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _statusChip(role),
                                  const SizedBox(height: 6),
                                  _statusChip(active ? 'Active' : 'Inactive'),
                                ],
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

  static Widget _messageCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFFFE2C8)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _staffOrange),
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

  static Widget _statusChip(String label) {
    final active = label.toLowerCase() == 'active' ||
        label.toLowerCase() == 'super_admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE7F5E9) : const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? const Color(0xFF216E39) : _staffInk,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

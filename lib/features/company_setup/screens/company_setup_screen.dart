import 'package:flutter/material.dart';

import '../../screens/dashboard/admin_shell.dart';

/// First-stage Company Setup workspace.
///
/// This screen is intentionally a setup blueprint only. It does not claim to
/// persist company settings until Firestore schema, authorization, and audit
/// logging are implemented and tested.
class CompanySetupScreen extends StatelessWidget {
  const CompanySetupScreen({super.key});

  static const List<_SetupSection> _sections = [
    _SetupSection(
      title: 'Company Profile',
      subtitle: 'Legal name, brand name, address, contacts and operating details.',
      icon: Icons.business_rounded,
      requirements: [
        'Legal entity type and registered name',
        'Brand name: DOJO WALK',
        'Registered and operating address',
        'Official email and phone',
        'Authorized representative',
      ],
    ),
    _SetupSection(
      title: 'Legal Documents',
      subtitle: 'Registration, tax, licenses and signed company records.',
      icon: Icons.gavel_rounded,
      requirements: [
        'Registration and PAN details, where applicable',
        'Applicable GST and other tax registrations',
        'Licenses and permits applicable to the business',
        'Bank account verification record',
        'Document expiry and renewal dates, where applicable',
      ],
    ),
    _SetupSection(
      title: 'Departments & Designations',
      subtitle: 'Keep the startup structure small and expandable.',
      icon: Icons.account_tree_rounded,
      requirements: [
        'Owner / Founder',
        'Operations responsibility',
        'Accounts support',
        'Customer support responsibility',
        'Walker / Partner',
        'Future manager roles only when needed',
      ],
    ),
    _SetupSection(
      title: 'Roles & Permissions',
      subtitle: 'Define who can view, create, approve or change records.',
      icon: Icons.admin_panel_settings_rounded,
      requirements: [
        'Owner / super admin access',
        'Operations access',
        'Accounts access',
        'Customer support access',
        'Walker access limited to assigned work',
        'Enforce permissions in Firebase rules/backend, not only in UI',
      ],
    ),
    _SetupSection(
      title: 'Approval Authority',
      subtitle: 'Set clear approval limits for refunds, payouts and expenses.',
      icon: Icons.fact_check_rounded,
      requirements: [
        'Refund approval rules',
        'Walker payout approval rules',
        'Expense approval limits',
        'Service-area activation approval',
        'Escalation path for exceptions',
      ],
    ),
    _SetupSection(
      title: 'Company Policies & SOPs',
      subtitle: 'Store the approved rules used to run daily operations.',
      icon: Icons.menu_book_rounded,
      requirements: [
        'Customer terms and privacy policy',
        'Cancellation and refund policy',
        'Walker agreement and code of conduct',
        'Dog-walking safety and emergency procedure',
        'Complaint handling and escalation',
      ],
    ),
    _SetupSection(
      title: 'Document Register',
      subtitle: 'Track document owner, version, approval and review date.',
      icon: Icons.folder_copy_rounded,
      requirements: [
        'Document title and category',
        'Responsible owner',
        'Version and approval status',
        'Effective date and next review date',
        'Restricted access for sensitive records',
      ],
    ),
    _SetupSection(
      title: 'Audit & Change Log',
      subtitle: 'Maintain traceable records of important administrative changes.',
      icon: Icons.history_rounded,
      requirements: [
        'Who made the change',
        'What changed and when',
        'Approval reference where required',
        'Before/after values for sensitive settings',
        'Retention and access policy',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF7900), Color(0xFFFF9D45)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.business_center_rounded,
                        color: Colors.white, size: 34),
                    SizedBox(height: 14),
                    Text(
                      'Company Setup',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Set up the foundations of DOJO WALK in one place. Start lean today and add managers and departments as the business grows.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2E6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFD6B0)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: adminOrange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Foundation preview: these sections show what must be configured. Saving, file uploads, role enforcement and audit logging are not connected in this first UI step. Do not treat a section as completed until its backend and security checks are implemented.',
                        style: TextStyle(
                          color: adminText,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Setup sections',
                style: TextStyle(
                  color: adminText,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Start with company identity and access control. Then add policies, approvals and records.',
                style: TextStyle(color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 1000
                      ? 3
                      : constraints.maxWidth >= 650
                          ? 2
                          : 1;
                  final cardWidth =
                      (constraints.maxWidth - (columns - 1) * 16) / columns;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: _sections
                        .map(
                          (section) => SizedBox(
                            width: cardWidth,
                            child: _SetupSectionCard(
                              section: section,
                              onTap: () => _showRequirements(context, section),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRequirements(BuildContext context, _SetupSection section) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(section.icon, color: adminOrange),
            const SizedBox(width: 10),
            Expanded(child: Text(section.title)),
          ],
        ),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(section.subtitle),
                const SizedBox(height: 16),
                const Text(
                  'Required setup checklist',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...section.requirements.map(
                  (requirement) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.radio_button_unchecked_rounded,
                            size: 18, color: adminOrange),
                        const SizedBox(width: 9),
                        Expanded(child: Text(requirement)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Status: Not configured. This checklist is not saved to the database yet.',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SetupSectionCard extends StatelessWidget {
  const _SetupSectionCard({
    required this.section,
    required this.onTap,
  });

  final _SetupSection section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFFE2C8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: adminOrange.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(section.icon, color: adminOrange, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                section.title,
                style: const TextStyle(
                  color: adminText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                section.subtitle,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.radio_button_unchecked_rounded,
                      size: 16, color: adminOrange),
                  SizedBox(width: 7),
                  Text(
                    'Not configured',
                    style: TextStyle(
                      color: adminText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.arrow_forward_rounded,
                      size: 18, color: adminOrange),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetupSection {
  const _SetupSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.requirements,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> requirements;
}

import 'package:flutter/material.dart';

const Color _securityOrange = Color(0xFFFF7900);
const Color _securityBackground = Color(0xFFFFFAF5);
const Color _securityText = Color(0xFF292524);
const Color _securityMuted = Color(0xFF78716C);
const Color _securityBorder = Color(0xFFE7E5E4);
const Color _securityGreen = Color(0xFF15803D);
const Color _securityRed = Color(0xFFB91C1C);

/// Displays account security information for a walker.
///
/// This dialog is read-only. It does not change account permissions,
/// verification status, or Firebase Authentication credentials.
Future<void> showWalkerSecurityDialog({
  required BuildContext context,
  required String walkerId,
  required Map<String, dynamic> walkerData,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return WalkerSecurityDialog(
        walkerId: walkerId,
        walkerData: walkerData,
      );
    },
  );
}

class WalkerSecurityDialog extends StatelessWidget {
  const WalkerSecurityDialog({
    super.key,
    required this.walkerId,
    required this.walkerData,
  });

  final String walkerId;
  final Map<String, dynamic> walkerData;

  String _value(
    String key, {
    String fallback = 'Not available',
  }) {
    final value = walkerData[key];

    if (value == null) return fallback;

    final result = value.toString().trim();

    return result.isEmpty ? fallback : result;
  }

  String _yesNo(String key) {
    return walkerData[key] == true ? 'Yes' : 'No';
  }

  Color _statusColor() {
    final status = _value('status').toLowerCase();

    if (status == 'approved' || status == 'active') {
      return _securityGreen;
    }

    if (status == 'rejected' ||
        status == 'suspended' ||
        status == 'inactive' ||
        status == 'left') {
      return _securityRed;
    }

    return _securityOrange;
  }

  Widget _statusBadge() {
    final color = _statusColor();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: color.withValues(alpha: 0.22),
        ),
      ),
      child: Text(
        _value('status'),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _row({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _securityOrange.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: _securityOrange,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _securityMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                SelectableText(
                  value,
                  style: TextStyle(
                    color: valueColor ?? _securityText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _notice() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _securityBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _securityBorder),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: _securityOrange,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This panel displays account information only. '
              'It does not change login access or account permissions.',
              style: TextStyle(
                color: _securityMuted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _securityOrange.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.security_outlined,
                      color: _securityOrange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Security',
                          style: TextStyle(
                            color: _securityText,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Walker account information',
                          style: TextStyle(
                            color: _securityMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: _securityBorder),
              const SizedBox(height: 8),

              _row(
                icon: Icons.fingerprint,
                title: 'Walker UID',
                value: walkerId,
              ),

              _row(
                icon: Icons.account_circle_outlined,
                title: 'Account Status',
                value: _value('status'),
              ),

              _row(
                icon: Icons.verified_user_outlined,
                title: 'Verification Status',
                value: _value('verificationStatus'),
              ),

              _row(
                icon: Icons.verified_outlined,
                title: 'Approved',
                value: _yesNo('isApproved'),
                valueColor: walkerData['isApproved'] == true
                    ? _securityGreen
                    : _securityRed,
              ),

              _row(
                icon: Icons.toggle_on_outlined,
                title: 'Account Active',
                value: _yesNo('isActive'),
                valueColor: walkerData['isActive'] == true
                    ? _securityGreen
                    : _securityRed,
              ),

              _row(
                icon: Icons.assignment_outlined,
                title: 'Application Submitted',
                value: _yesNo('applicationSubmitted'),
              ),

              _row(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Last Decision By',
                value: _value('decisionBy'),
              ),

              _row(
                icon: Icons.history_outlined,
                title: 'Last Decision Reason',
                value: _value('decisionReason'),
              ),

              const SizedBox(height: 8),

              const Text(
                'Current status',
                style: TextStyle(
                  color: _securityMuted,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 8),

              _statusBadge(),

              const SizedBox(height: 18),

              _notice(),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _securityOrange,
                    side: const BorderSide(
                      color: _securityOrange,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

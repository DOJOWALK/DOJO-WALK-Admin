import 'package:flutter/material.dart';

import '../services/walker_admin_service.dart';
import '../utils/walker_admin_helpers.dart';

const Color _activityOrange = Color(0xFFFF7900);
const Color _activityBackground = Color(0xFFFFFAF5);
const Color _activityText = Color(0xFF292524);
const Color _activityMuted = Color(0xFF78716C);
const Color _activityBorder = Color(0xFFE7E5E4);

/// Opens the activity history for a walker.
///
/// The dialog uses WalkerAdminService so Firestore access
/// remains outside the UI.
Future<void> showWalkerActivityHistoryDialog({
  required BuildContext context,
  required String walkerId,
  required WalkerAdminService service,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return WalkerActivityHistoryDialog(
        walkerId: walkerId,
        service: service,
      );
    },
  );
}

class WalkerActivityHistoryDialog extends StatelessWidget {
  const WalkerActivityHistoryDialog({
    super.key,
    required this.walkerId,
    required this.service,
  });

  final String walkerId;
  final WalkerAdminService service;

  String _text(
    dynamic value, {
    String fallback = 'Not available',
  }) {
    if (value == null) return fallback;

    final result = value.toString().trim();

    return result.isEmpty ? fallback : result;
  }

  String _date(dynamic value) {
    final date = WalkerAdminHelpers.toDateTime(value);

    if (date == null) return 'Date not available';

    return WalkerAdminHelpers.formatDateTime(value);
  }

  String _displayAction(dynamic value) {
    final action = _text(value, fallback: 'Activity');

    return action
        .replaceAll('_', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
              '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  Color _actionColor(dynamic value) {
    final action = _text(value).toLowerCase();

    if (action.contains('approved') ||
        action.contains('reactivated')) {
      return const Color(0xFF15803D);
    }

    if (action.contains('rejected') ||
        action.contains('suspended')) {
      return const Color(0xFFB91C1C);
    }

    if (action.contains('correction')) {
      return const Color(0xFFB45309);
    }

    return const Color(0xFF1D4ED8);
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.20),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _detail(String label, dynamic value) {
    final text = _text(value);

    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(
                color: _activityMuted,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              text,
              style: const TextStyle(
                color: _activityText,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _record(Map<String, dynamic> record) {
    final action = record['action'];
    final color = _actionColor(action);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _activityBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.history_outlined,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayAction(action),
                      style: const TextStyle(
                        color: _activityText,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _date(record['createdAt']),
                      style: const TextStyle(
                        color: _activityMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              _tag(
                _text(record['actorRole'], fallback: 'Admin'),
                color,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: _activityBorder),
          _detail('Actor UID', record['actorUid']),
          _detail('Previous status', record['beforeStatus']),
          _detail('New status', record['afterStatus']),
          _detail(
            'Previous verification',
            record['beforeVerificationStatus'],
          ),
          _detail(
            'New verification',
            record['afterVerificationStatus'],
          ),
          _detail('Reason', record['reason']),
          _detail('Audit ID', record['id']),
        ],
      ),
    );
  }

  Widget _body() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: service.watchWalkerAuditLogs(
        walkerId,
        limit: 50,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _message(
            icon: Icons.error_outline,
            title: 'Could not load activity history',
            subtitle:
                'Check your connection and Firestore permissions.',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(
                color: _activityOrange,
              ),
            ),
          );
        }

        final records = snapshot.data ?? [];

        if (records.isEmpty) {
          return _message(
            icon: Icons.history,
            title: 'No activity recorded',
            subtitle:
                'Administrative actions will appear here when audit records exist.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            return _record(records[index]);
          },
        );
      },
    );
  }

  Widget _message({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: _activityMuted,
              size: 38,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _activityText,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _activityMuted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _activityBackground,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SizedBox(
        width: 720,
        height: 620,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _activityOrange.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.history,
                      color: _activityOrange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Activity History',
                          style: TextStyle(
                            color: _activityText,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Administrative actions and audit records',
                          style: TextStyle(
                            color: _activityMuted,
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
            ),
            const Divider(height: 1, color: _activityBorder),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }
}

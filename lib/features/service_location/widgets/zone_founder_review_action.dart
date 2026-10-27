import 'package:flutter/material.dart';

import '../models/zone_role_permissions.dart';
import '../models/service_location_zone.dart';

/// Shows the decision action only to an active Founder for pending decisions.
/// Firebase callable authorization remains the security boundary.
class ZoneFounderReviewAction extends StatelessWidget {
  const ZoneFounderReviewAction({
    super.key,
    required this.permissions,
    required this.zone,
    required this.busy,
    required this.onPressed,
  });

  final ZoneRolePermissions permissions;
  final ServiceLocationZone zone;
  final bool busy;
  final VoidCallback onPressed;

  bool get _hasPendingDecision =>
      zone.workflowStatus == ZoneWorkflowStatus.submitted ||
      zone.workflowStatus == ZoneWorkflowStatus.deactivationSubmitted ||
      zone.workflowStatus == ZoneWorkflowStatus.reactivationSubmitted;

  @override
  Widget build(BuildContext context) {
    if (!permissions.canReviewFounderDecision || !_hasPendingDecision) {
      return const SizedBox.shrink();
    }
    return FilledButton.tonal(
      onPressed: busy ? null : onPressed,
      child: const Text('Founder Review'),
    );
  }
}
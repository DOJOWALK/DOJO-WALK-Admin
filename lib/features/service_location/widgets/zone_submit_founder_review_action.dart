import 'package:flutter/material.dart';

import '../models/service_location_zone.dart';
import '../models/zone_role_permissions.dart';

/// Presentation gate for submitting a verified Zone draft to Founder review.
class ZoneSubmitFounderReviewAction extends StatelessWidget {
  const ZoneSubmitFounderReviewAction({
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

  @override
  Widget build(BuildContext context) {
    final eligibleStatus = zone.workflowStatus == ZoneWorkflowStatus.draft ||
        zone.workflowStatus == ZoneWorkflowStatus.changesRequired;
    if (!permissions.canSubmitForFounderReview ||
        zone.isServiceActive ||
        zone.verifiedBoundaryId == null ||
        zone.verifiedBoundaryId!.trim().isEmpty ||
        !eligibleStatus) {
      return const SizedBox.shrink();
    }
    return FilledButton.tonal(
      onPressed: busy ? null : onPressed,
      child: const Text('Submit for Founder Review'),
    );
  }
}
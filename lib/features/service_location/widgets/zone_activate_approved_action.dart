import 'package:flutter/material.dart';

import '../models/service_location_zone.dart';
import '../models/zone_role_permissions.dart';

/// Presentation gate only. The activation callable must re-check approval and boundary hash.
class ZoneActivateApprovedAction extends StatelessWidget {
  const ZoneActivateApprovedAction({
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
    if (!permissions.canActivateZone || !zone.mayRequestActivation) {
      return const SizedBox.shrink();
    }
    return FilledButton(
      onPressed: busy ? null : onPressed,
      child: const Text('Activate Approved Zone'),
    );
  }
}
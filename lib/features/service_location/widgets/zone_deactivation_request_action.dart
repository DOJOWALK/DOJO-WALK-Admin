import 'package:flutter/material.dart';

import '../models/service_location_zone.dart';
import '../models/zone_role_permissions.dart';

/// Presentation gate for requesting deactivation; callable authorization remains authoritative.
class ZoneDeactivationRequestAction extends StatelessWidget {
  const ZoneDeactivationRequestAction({
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
    if (!permissions.isActive ||
        permissions.role != ZoneAdminRole.centralAdmin ||
        !zone.isServiceActive) {
      return const SizedBox.shrink();
    }
    return OutlinedButton(
      onPressed: busy ? null : onPressed,
      child: const Text('Request Deactivation'),
    );
  }
}
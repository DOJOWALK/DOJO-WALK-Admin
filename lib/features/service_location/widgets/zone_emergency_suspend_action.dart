import 'package:flutter/material.dart';

import '../models/service_location_zone.dart';
import '../models/zone_role_permissions.dart';

/// Presentation gate for emergency suspension; Firebase callable authorization remains authoritative.
class ZoneEmergencySuspendAction extends StatelessWidget {
  const ZoneEmergencySuspendAction({
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
    if (!permissions.canEmergencySuspend || !zone.isServiceActive) {
      return const SizedBox.shrink();
    }
    return OutlinedButton.icon(
      onPressed: busy ? null : onPressed,
      icon: const Icon(Icons.warning_amber_rounded, color: Colors.red),
      label: const Text('Emergency Suspend'),
    );
  }
}
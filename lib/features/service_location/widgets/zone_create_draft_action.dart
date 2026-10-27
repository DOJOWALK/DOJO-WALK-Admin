import 'package:flutter/material.dart';

import '../models/zone_role_permissions.dart';

/// The header action is extracted so its role visibility can be widget-tested.
/// Backend authorization remains authoritative for every Zone mutation.
class ZoneCreateDraftAction extends StatelessWidget {
  const ZoneCreateDraftAction({
    super.key,
    required this.permissions,
    required this.busy,
    required this.onPressed,
  });

  final ZoneRolePermissions permissions;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: FilledButton.icon(
        onPressed: busy || !permissions.canCreateZone ? null : onPressed,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Create Zone Draft'),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFF7900),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

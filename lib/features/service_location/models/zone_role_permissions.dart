/// Presentation-level permissions for the Zone Management UI.
///
/// These gates hide/disable controls only. Firebase callable authorization is
/// still the security boundary and must independently enforce every action.
enum ZoneAdminRole { founder, centralAdmin, technicalSuperAdmin, other }

class ZoneRolePermissions {
  const ZoneRolePermissions({required this.role, required this.isActive});

  final ZoneAdminRole role;
  final bool isActive;

  factory ZoneRolePermissions.fromFirestore({
    required String? role,
    required bool isActive,
  }) {
    final parsed = switch (role) {
      'founder' => ZoneAdminRole.founder,
      'central_admin' => ZoneAdminRole.centralAdmin,
      'super_admin' || 'technical_super_admin' => ZoneAdminRole.technicalSuperAdmin,
      _ => ZoneAdminRole.other,
    };
    return ZoneRolePermissions(role: parsed, isActive: isActive);
  }

  bool get canCreateZone => isActive && role == ZoneAdminRole.centralAdmin;
  bool get canManageBoundary => isActive && role == ZoneAdminRole.centralAdmin;
  bool get canSubmitForFounderReview => isActive && role == ZoneAdminRole.centralAdmin;
  bool get canReviewFounderDecision => isActive && role == ZoneAdminRole.founder;
  bool get canActivateZone => isActive && role == ZoneAdminRole.centralAdmin;
  bool get canEmergencySuspend => isActive && role == ZoneAdminRole.centralAdmin;
}

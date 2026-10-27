import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/models/zone_role_permissions.dart';

void main() {
  group('ZoneRolePermissions', () {
    test('active Central Admin can prepare Zone workflow but cannot Founder-review', () {
      final permissions = ZoneRolePermissions.fromFirestore(
        role: 'central_admin',
        isActive: true,
      );
      expect(permissions.canCreateZone, isTrue);
      expect(permissions.canManageBoundary, isTrue);
      expect(permissions.canSubmitForFounderReview, isTrue);
      expect(permissions.canActivateZone, isTrue);
      expect(permissions.canEmergencySuspend, isTrue);
      expect(permissions.canReviewFounderDecision, isFalse);
    });

    test('active Founder can review but cannot create or activate Zones', () {
      final permissions = ZoneRolePermissions.fromFirestore(
        role: 'founder',
        isActive: true,
      );
      expect(permissions.canReviewFounderDecision, isTrue);
      expect(permissions.canCreateZone, isFalse);
      expect(permissions.canManageBoundary, isFalse);
      expect(permissions.canSubmitForFounderReview, isFalse);
      expect(permissions.canActivateZone, isFalse);
      expect(permissions.canEmergencySuspend, isFalse);
    });

    test('technical Super Admin never receives Founder approval authority', () {
      for (final role in ['super_admin', 'technical_super_admin']) {
        final permissions = ZoneRolePermissions.fromFirestore(
          role: role,
          isActive: true,
        );
        expect(permissions.canReviewFounderDecision, isFalse, reason: role);
        expect(permissions.canCreateZone, isFalse, reason: role);
        expect(permissions.canActivateZone, isFalse, reason: role);
      }
    });

    test('inactive users receive no Zone UI permissions', () {
      for (final role in ['founder', 'central_admin', 'super_admin']) {
        final permissions = ZoneRolePermissions.fromFirestore(
          role: role,
          isActive: false,
        );
        expect(permissions.canCreateZone, isFalse, reason: role);
        expect(permissions.canManageBoundary, isFalse, reason: role);
        expect(permissions.canSubmitForFounderReview, isFalse, reason: role);
        expect(permissions.canReviewFounderDecision, isFalse, reason: role);
        expect(permissions.canActivateZone, isFalse, reason: role);
        expect(permissions.canEmergencySuspend, isFalse, reason: role);
      }
    });

    test('unknown roles fail closed', () {
      final permissions = ZoneRolePermissions.fromFirestore(
        role: 'unexpected_role',
        isActive: true,
      );
      expect(permissions.canCreateZone, isFalse);
      expect(permissions.canReviewFounderDecision, isFalse);
      expect(permissions.canActivateZone, isFalse);
    });
  });
}

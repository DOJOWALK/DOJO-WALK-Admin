# DOJO WALK Location Master — Step 47 Report

Date: 2026-10-17  
Repository: `dojoplatform2026/dojo-admin`  
Branch: `restore/india-location-reference-data`

## Outcome: Authorization policy gap documented

Reviewed:
- `lib/screens/auth/auth_gate.dart`
- `lib/services/auth_service.dart`
- Step 45 central Firestore Rules audit and Step 46 test status.

Both client-side entry points accept an admin record if `isActive == true`; neither checks the role. The prior central-rules audit found that privileged Service Location rules require an active `super_admin`. This mismatch can allow a non-super-admin into the shell and then have operations denied by Firestore.

## Important product constraint

The intended product direction allows future non-super-admin admins to have role-scoped screens. Therefore, blindly requiring `super_admin` for every Admin UI login is not a safe fix. First define the role/permission matrix, then implement matching UI visibility and Firestore Rules and test them together.

## Next work

1. Define permissions by role and collection/action.
2. Extend Firestore Rules Emulator tests for allowed and denied role/action combinations.
3. Update AuthGate and AuthService only after the approved role policy is clear.
4. Verify CI before marking the new tests PASS.

## Safety / validation

Central Firebase repo file retrieval was unavailable during this step; no central rules code or Admin auth code was changed. This is a documented audit finding, not a code fix. No production rules deployment, writes, imports, or activations were performed. Keep PR #6 open.

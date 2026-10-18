# Step 201 — Admin Authorization and Walker Eligibility Field Audit

**Status:** Read-only source audit completed  
**Repository branch:** `step-119-boundary-geometry`  
**Purpose:** Record actual field names found in the inspected source before assignment implementation.

## 1. Admin authorization — observed source

### Admin UI gate

File: `lib/screens/auth/auth_gate.dart`

The current gate:
- reads `admin_users/{FirebaseAuth UID}`;
- denies access when the document is missing;
- checks only `isActive == true`;
- does not check `role` before returning `AdminShell`.

This means the UI gate alone does not enforce the role required by the central rules.

### Walker-management administrative action

File: `lib/features/walkers/services/walker_admin_service.dart`

Inside the transaction, the service checks:
- `admin_users/{uid}` exists;
- `isActive == true`;
- `role == 'super_admin'`.

This is stronger than the general AuthGate. It is still client-side code and must not be treated as a replacement for server/rules authorization.

### Firebase Rules

File: `firestore.rules` in repository `DOJO-WALK-Firebase`, inspected on branch `step-138-partner-submission-negative-tests`.

The `isAdmin()` helper checks:
- authenticated request;
- `admin_users/{request.auth.uid}` exists;
- `isActive == true`;
- `role == 'super_admin'`.

**Important boundary:** This is the rule source on the named branch, not proof that this exact revision is currently deployed to production.

## 2. Walker eligibility — observed source fields

Files:
- `lib/features/walkers/utils/walker_admin_helpers.dart`
- `lib/features/walkers/models/walker_admin_model.dart`
- `lib/features/walkers/services/walker_admin_service.dart`
- Firebase `firestore.rules` on the branch listed above.

The Admin eligibility helper requires all of:
- `status == 'approved'` (normalized before comparison);
- `verificationStatus == 'verified'` (normalized);
- `isApproved == true`;
- `isActive == true`.

The Firebase rules helper `isApprovedWalker()` checks `isActive == true` and `isApproved == true` for the signed-in walker's own document. The reviewed rules also define status/verification allowlists and consistency constraints for administrative decisions.

The reviewed helper explicitly says account eligibility alone does not check booking conflicts, service location, or live GPS. Assignment must add those checks separately.

### Suspension / inactive handling

The Admin helper treats `status == 'suspended'`, `inactive`, `rejected`, and `left` as unavailable; it also rejects a walker missing verified/approved/active flags. Do not rely on a single boolean alone.

## 3. Assignment implementation implications

Before a trusted assignment endpoint is built:
1. Enforce admin role and active state on the trusted server; use `super_admin` only if this remains the approved assignment role.
2. Re-read walker eligibility inside the same atomic assignment operation using the fields above.
3. Reject suspended/inactive/rejected/left states even if stale booleans conflict.
4. Add service-area membership and schedule/capacity validation; these are not covered by the account eligibility helper.
5. Review and test Firestore Rules so clients cannot assign or reassign bookings directly.
6. Confirm deployed rules/version separately before production changes.

## 4. Known authorization inconsistency

The Admin `AuthGate` checks only `isActive`, while the WalkerAdminService transaction and reviewed Firebase rules require `isActive` plus `role == 'super_admin'`. This can let an active non-super-admin enter the shell while privileged operations are denied later. Record as a follow-up; this audit did not change the UI, rules, or data.

## 5. Scope and evidence limits

This was a source-file inspection only. It does not read live production documents, verify the currently deployed rules revision, or prove that every app/backend uses exactly these fields. Partner and external backend paths must be audited before implementation. No code, rules, schema, production data, deployment, or merge was changed.

Related documents:
- [Step 197 — Booking Location Migration Contract](STEP_197_BOOKING_LOCATION_MIGRATION_CONTRACT.md)
- [Step 198 — Walker Assignment Path Audit](STEP_198_WALKER_ASSIGNMENT_PATH_AUDIT.md)
- [Step 199 — Assignment Writer Deep Search](STEP_199_ASSIGNMENT_WRITER_DEEP_SEARCH.md)
- [Step 200 — Booking Assignment Security Contract](STEP_200_BOOKING_ASSIGNMENT_SECURITY_CONTRACT.md)

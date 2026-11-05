# DOJO WALK Admin Google Sign-In & Individual Account Decision

**Decision date:** 2026-11-05  
**Decision time:** 06:37 IST (Asia/Kolkata)  
**Decision owner:** Founder / DOJO WALK  
**Status:** Founder-selected authentication method; implementation remains gated by the active Admin UI integration sequence.

## 1. Confirmed decision

The Admin portal will use:

- **Authentication provider:** Google Sign-In through Firebase Authentication.
- **Account model:** One named, individual Google account per human staff member. Shared Admin credentials are prohibited.
- **Authorization:** A successful Google authentication does not grant Admin access. The authenticated Firebase UID must resolve to an independently provisioned, active Admin membership and pass the applicable role, permission, geographic-scope and record-state checks.
- **Provisioning:** Admin membership is created or changed only through a trusted, privileged provisioning path. No public self-registration, client-side role grant, self-activation or self-promotion.
- **Revocation:** Deactivating/revoking the Admin membership must deny subsequent protected backend operations; the app must leave or refresh the protected shell when authorization is lost.

## 2. Existing source findings (read-only audit, 2026-11-05)

### Admin repository `DOJOWALK/DOJO-WALK-Admin`

- Default branch: `main`.
- Current `main` `lib/screens/auth/admin_login_screen.dart` uses email/password fields.
- Current `main` `lib/services/auth_service.dart` calls `signInWithEmailAndPassword`, then checks `admin_users/{uid}` exists and `isActive == true`.
- Current `main` `lib/screens/auth/auth_gate.dart` checks the membership document and `isActive == true`, but does not check a canonical role or geographic scope.
- The active Admin UI PR is **#51**, branch `ui/notion-brand-foundation-2026-10-28`. Its stated guardrail is to keep the PR Draft and defer new Firebase integration, merge and deployment until the Admin UI and its validation are complete.
- Closed PR #45 was intentionally archived without merge. Its proposed `super_admin`-only entry gate must not be independently revived or cherry-picked. Any needed change must be reviewed against the active branch and canonical role contract.

### Firebase repository `DOJOWALK/DOJO-WALK-Firebase`

- Default branch: `main`.
- Current `firestore.rules` helper `isAdmin()` requires an authenticated user with an existing `admin_users/{uid}` record, `isActive == true`, and `role == 'super_admin'`.
- The `admin_users` Rules permit self-read of an individual's own membership record; list is restricted to `isAdmin()`; client create/delete are denied. Role/active updates are restricted to an active `super_admin` and an allowlist.
- The inspected Functions entrypoint performs server-side active-`super_admin` checks for protected location operations. It does not establish a complete Founder/Central/City/Zone role-and-scope contract.
- Existing role/scope audits identify POL-021 and the canonical cross-team role contract as unresolved/Draft. Legacy `admin` and `support` values must not be silently mapped to new operational roles.

These are repository-source findings only. They do not prove which Google provider settings, OAuth client IDs, Firebase Auth users, production Rules or Functions are currently enabled/deployed.

## 3. Target sign-in and authorization sequence

1. Staff member selects **Continue with Google** in the Admin portal.
2. Google returns an identity credential; Firebase Authentication establishes the Firebase UID.
3. Admin app reads only the signed-in user's own `admin_users/{uid}` membership record.
4. Missing, inactive, malformed, unsupported-role or unreadable membership fails closed: no Admin shell, no privileged data, and sign-out/denial state.
5. For an active, supported membership, the app loads only the features permitted by the approved role/scope contract.
6. Every protected Firestore read/write and callable independently enforces the same trusted authorization rules. Hiding a menu item or passing an app-side check is never sufficient.
7. Each consequential account/role/scope change records actor, target UID, previous/new values, reason, server timestamp and outcome in the approved audit mechanism.

## 4. Individual account lifecycle

- A staff member must use their own Google account; no shared team mailbox or shared password as a staff identity.
- Founder/Super Admin-controlled provisioning must bind the intended Google-authenticated Firebase UID to the correct staff identity only after identity verification.
- Role, city scope, zone scope, permitted actions, approver and effective dates must be explicit; never infer authority from email domain or Google account status.
- Account creation, role change, scope change, suspension and revocation require least privilege, separation of duties and durable audit.
- Staff leaving the company or changing responsibilities must have access revoked/updated without deleting historical audit attribution.
- Do not expose private Google profile data beyond the minimum identity fields needed for the Admin account.

## 5. Role and scope safety boundary

Google Sign-In is the identity mechanism, not the role model. Until the canonical role contract and POL-021 are approved:

- Preserve the existing protected-backend requirement for active `super_admin` where it currently exists.
- Do not grant Founder approval authority merely because an account is `super_admin`.
- Do not equate legacy `admin` with Central Admin, City Manager or Zone Supervisor.
- Do not grant Finance, support, City or Zone access based only on successful sign-in.
- Do not weaken existing Firestore Rules or add client-writable `admin_users` creation to make onboarding easier.

## 6. Implementation and validation gates

### Gate A — active Admin UI branch
- Complete the existing PR #51 UI scope and exact-head CI validation first, consistent with its current guardrails.
- Then implement Google Sign-In in the existing auth feature; do not create a parallel login subsystem.
- Preserve the current theme/branding and provide clear loading, cancellation, provider error, unauthorized, inactive and retry states.
- Add the required Google Sign-In dependency and platform configuration only after auditing current FlutterFire versions, Android package/signing configuration, Web OAuth configuration and repository secret handling.
- Never commit service-account JSON, OAuth client secrets or private keys.

### Gate B — trusted identity provisioning and backend contract
- Define a trusted provisioning operation that can create/link Admin membership for a verified Firebase UID. It must not be callable by an ordinary signed-in staff member to self-grant access.
- Agree canonical role IDs, capabilities and City/Zone scope fields with the controlling Notion policy and Team 01 backend contract.
- Reconcile Firestore Rules, callable authorization, Admin feature gates and audit schema. Do not broaden `isAdmin()` to every authenticated staff role without a reviewed permission matrix.

### Gate C — required Auth + Firestore/Functions Emulator tests
1. Google-authenticated UID with active supported Admin membership can enter the permitted shell.
2. Google-authenticated UID with no `admin_users` record is denied and signed out.
3. Inactive membership is denied.
4. Unsupported/legacy role is denied from privileged actions.
5. Firestore membership read failure is denied (fail closed).
6. Staff A cannot read Staff B's private membership or alter it.
7. Client cannot create, delete, self-activate or self-promote an Admin membership.
8. Revocation blocks the next protected callable/Firestore operation.
9. City Manager and Zone Supervisor cannot cross assigned scope once the approved scope contract exists.
10. Founder-only approvals remain separate from Super Admin technical access.
11. Login cancellation and provider/network failures do not create an Admin session.
12. Audit records for provisioning, role/scope changes and revocation contain server time and actor/target attribution.

### Gate D — release
- Verify exact-head CI on the implementation commit.
- Verify Firebase Auth provider and OAuth settings in the intended Firebase project without exposing secrets.
- Verify deployed Rules/Functions revision parity before release.
- No production Auth user creation, role grants, Rules changes or deployment is authorized by this decision record alone.

## 7. Current status

| Item | Status |
|---|---|
| Founder selection: Google Sign-In | **CONFIRMED** |
| Individual staff accounts | **CONFIRMED** |
| Current Admin source audit | **COMPLETE — source only** |
| Google provider configuration audit | **PENDING** |
| Google Sign-In runtime implementation | **NOT STARTED** |
| Canonical role/scope contract | **BLOCKED — approval/Team 01 contract required** |
| Trusted Admin provisioning workflow | **NOT IMPLEMENTED / NOT VERIFIED** |
| Auth + Firestore/Functions Emulator acceptance | **NOT RUN for Google Admin sign-in** |
| Production configuration/deployment | **NOT CHECKED / NOT AUTHORIZED** |

## 8. Change log

- 2026-11-05 06:37 IST — Founder selected Google Sign-In and individual staff accounts.
- 2026-11-05 06:37 IST — Read-only source audit recorded for Admin `main`, active Admin PR #51 branch context, and Firebase `main`.
- 2026-11-05 06:37 IST — This decision record created on the existing Admin PR #51 branch. Documentation only; no runtime code, Firebase configuration, Rules, Functions, production data, merge or deployment changed.

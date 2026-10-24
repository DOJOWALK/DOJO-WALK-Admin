# DOJO WALK Admin — Auth and Scope Test Gap

Date: 2026-10-24
Branch: `feature/admin-fresh-architecture-2026-10-24`
Inspected HEAD before this document: `41b1ab8ee9220953783f722b8b2c53183fe9f901`

## Evidence reviewed

- `lib/core/auth/admin_auth_repository.dart`: reads `admin_users/{uid}`; permits entry only when `isActive == true` and `role == 'super_admin'`; signs out unauthorized users.
- `lib/core/auth/admin_identity.dart`: the client identity has UID, email, role, active flag and display name. It has no assigned-area scope/capabilities model yet.
- `lib/core/auth/fresh_admin_auth_gate.dart`: shows a loading state, login, retryable access-check error, or the fresh Admin shell.
- Repository tree at inspected HEAD contains 16 Dart test files. None has a filename indicating auth, role, scope, or permission coverage. This is a filename-based finding, not proof that no test indirectly covers these behaviors.
- The fresh shell currently exposes Dashboard, Add Location, Boundary Review and Live Operations. The documented company hierarchy includes Founder/CEO, Central Admin, Area Manager and Walker/Partner; there is not yet an implemented Area Manager scope experience in this fresh shell.

## Current classification

- UI super_admin gate: IMPLEMENTED in source; not yet marked VERIFIED by dedicated auth tests.
- Backend authorization: must remain authoritative; UI gating alone is insufficient.
- Area Manager assigned-area scoping: NOT IMPLEMENTED in the fresh identity/shell reviewed here.
- Founder/CEO-only company-wide approval controls: NOT IMPLEMENTED in the fresh shell reviewed here.
- Walker/Partner field-work flows: belong primarily in the Partner app; Admin monitoring/review should not silently duplicate Partner actions.

## Required tests before role/scope claims

1. Unauthenticated user sees login.
2. Active `super_admin` can enter the Admin shell.
3. Active `admin` is denied by the fresh UI if the approved policy remains super_admin-only.
4. Inactive `super_admin` is denied.
5. Missing `admin_users/{uid}` is denied.
6. Firestore read/network failure shows retryable error and does not grant access.
7. A signed-in user's admin document changing to inactive/unauthorized causes access to be revoked; confirm the stream behavior covers document changes, not just Auth state changes.
8. Server-side callable and Firestore Rules reject unauthorized roles regardless of what the client UI shows.
9. Before adding Area Manager UI, tests prove an Area Manager can only query/view assigned Area IDs and descendants; changing client-side IDs cannot widen access.
10. Founder/CEO-only actions require the approved server-side capability/role and leave an audit record.

## Specific issue to resolve

`watchAdminIdentity()` currently listens to Firebase Auth `authStateChanges()` and then reads the admin document once per auth event. The code reviewed does not subscribe to `admin_users/{uid}` document changes. If an admin is deactivated while their Auth session remains active, the fresh UI may not automatically react until another auth event/reload. Add a document stream or another deliberate revocation mechanism, then cover it with a test.

## CI status at audit time

On inspected HEAD `41b1ab8ee9220953783f722b8b2c53183fe9f901`:
- Geometry tests run `40053151210`: success.
- Web build run `40053151183`: in progress.
- Full validation run `40053151193`: in progress.

Do not claim full validation until both running workflows finish and their final conclusions are inspected.

## Safe next action

Add focused auth repository/gate tests and make the admin-document status/role revocation reactive. Do not implement new role screens or loosen the super_admin gate until the Company Master / Owner Control Center policy is checked and the backend authorization contract is tested.

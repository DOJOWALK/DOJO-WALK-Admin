# DOJO WALK Admin — Auth and Scope Test Gap

Date: 2026-10-24
Branch: `feature/admin-fresh-architecture-2026-10-24`
Reviewed HEAD: `0f0be991a9e0541beaa850fbc973d19c5384d0a3`

## Evidence reviewed

- `lib/core/auth/admin_auth_repository.dart`: watches `admin_users/{uid}` live, requires `isActive == true` and `role == 'super_admin'`, and signs out when the live identity becomes unauthorized.
- `test/core/auth/admin_identity_test.dart`: tests active super_admin allowed; inactive super_admin, active admin, and unknown area_manager role denied. These are identity-policy tests, not a stream-level revocation test.
- `test/core/auth/fresh_admin_auth_gate_test.dart`: widget tests cover retry after an auth-status stream error and the no-identity/login state. They do not simulate a real Firebase document role change.
- `lib/core/auth/fresh_admin_auth_gate.dart`: accepts an optional repository for deterministic widget tests; production defaults to the Firebase-backed repository.
- `lib/core/auth/admin_identity.dart`: client identity contains UID, email, role, active flag and display name; it has no assigned-area scope/capabilities model.
- `lib/features/service_location/data/admin_service_location_repository.dart`: uses trusted callable `saveServiceLocationWithNameIndex`; after callable success, it reads the created document back and verifies the status field is explicitly false before returning success.
- GitHub Actions on reviewed HEAD `0f0be991`:
  - Admin Web Build Check run `40068200291`: SUCCESS.
  - Service Location Geometry Tests run `40068200255`: SUCCESS.
  - Admin Main Full Validation run `40068200208`: SUCCESS (analysis, complete Dart test suite, and Flutter Web build).
- PR #37 remains open and draft; it has not been merged. These workflows did not deploy the app.

## Current classification

- UI super_admin gate: IMPLEMENTED and covered by focused identity policy tests.
- Auth-gate error/retry and no-identity UI states: IMPLEMENTED and covered by widget tests in the passing full-validation run.
- Reactive role/active revocation: IMPLEMENTED in the auth repository; a dedicated stream-level test proving document-change revocation and sign-out is still missing.
- Add Location save/read-back: IMPLEMENTED in source; current Flutter CI passes. An authenticated Admin-client-to-Firebase-Emulator test for the full callable + Firestore Rules read-back path is still required before production readiness.
- Backend authorization: must remain authoritative; UI gating alone is insufficient.
- Area Manager assigned-area scoping: NOT IMPLEMENTED in the fresh identity/shell reviewed here.
- Founder/CEO-only company-wide approval controls: NOT IMPLEMENTED in the fresh shell reviewed here.
- Walker/Partner field-work flows: belong primarily in the Partner app; Admin monitoring/review should not silently duplicate Partner actions.

## Remaining tests before role/scope claims

1. Add a stream-level test proving that changing `admin_users/{uid}` from active super_admin to inactive or another role revokes the identity and signs out.
2. Keep the retry/error UI fail-closed; test UI does not render the Admin shell on an error (currently covered by the retry widget test's initial error state).
3. Run authenticated emulator coverage for the complete fresh Add Location flow: active super_admin save, duplicate-name rejection, inactive/missing admin rejection, and client read-back of the newly created inactive record.
4. Verify server-side callable and Firestore Rules reject unauthorized roles regardless of the client UI.
5. Before adding Area Manager UI, tests must prove an Area Manager can only query/view assigned Area IDs and descendants; client-controlled IDs must not widen access.
6. Founder/CEO-only actions must require approved server-side capabilities and leave an audit record before they are implemented.

## Company alignment

The approved management structure is Founder / CEO → Central Admin → Area Manager → Walker / Partner. Geographic hierarchy is separate: India → State/UT → District → City → Area → Locality. The app must not treat a geographic selection as a substitute for a role's authorized scope.

Do not add new role screens, assume Area Manager access, or loosen the super_admin gate until the Company Master / Owner Control Center policy and server-side authorization contract are verified together.

## Safe next action

Implement a testable auth data-source seam and add a stream-level role/active revocation test. Then add authenticated emulator coverage for the Admin save/read-back path. Keep PR #37 draft and do not merge or deploy until these gates and the company-alignment review are complete.

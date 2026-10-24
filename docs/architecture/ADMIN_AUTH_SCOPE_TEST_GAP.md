# DOJO WALK Admin — Auth and Scope Test Gap

Date: 2026-10-24
Branch: `feature/admin-fresh-architecture-2026-10-24`
Reviewed HEAD: `4eb80e74bd6a8097e2095976ae6d69da57613c04`

## Evidence reviewed

- `lib/core/auth/admin_auth_repository.dart`: watches `admin_users/{uid}` live, requires `isActive == true` and `role == 'super_admin'`, and signs out when the live identity becomes unauthorized.
- `test/core/auth/admin_identity_test.dart`: tests active super_admin allowed; inactive super_admin, active admin, and unknown area_manager role denied. These are identity-policy tests.
- `test/core/auth/admin_identity_revocation_guard_test.dart`: newly added unit tests cover an active identity followed by inactive identity, role change, or missing identity; each expects null emission and one sign-out callback. These test the extracted revocation guard using a controlled stream, not Firebase Auth/Firestore itself.
- `test/core/auth/fresh_admin_auth_gate_test.dart`: widget tests cover retry after an auth-status stream error and the no-identity/login state.
- `lib/core/auth/fresh_admin_auth_gate.dart`: accepts an optional repository for deterministic widget tests.
- `lib/features/service_location/data/admin_service_location_repository.dart`: uses trusted callable `saveServiceLocationWithNameIndex`; after callable success, it reads the created document back and verifies the status field is explicitly false before returning success.
- Prior reviewed code HEAD `0f0be991a9e0541beaa850fbc973d19c5384d0a3` had passing CI:
  - Admin Web Build Check run `40068200291`: SUCCESS.
  - Service Location Geometry Tests run `40068200255`: SUCCESS.
  - Admin Main Full Validation run `40068200208`: SUCCESS.
- Latest prior validation at HEAD `3526810f999af277d5327654fb1d433f2f9d321a` also passed:
  - Admin Main Full Validation run `40068436623`: SUCCESS (analysis, complete Dart test suite, and Flutter Web build).
  - Admin Web Build Check run `40068437402`: SUCCESS.
  - Service Location Geometry Tests run `40068436735`: SUCCESS.
- The new commits `c10b112` and `4eb80e7` were added after those CI runs. Their CI results must be checked separately before claiming the latest HEAD passes.

## Current classification

- UI super_admin gate: IMPLEMENTED and covered by focused identity policy tests.
- Auth-gate error/retry and no-identity UI states: IMPLEMENTED and covered by widget tests in the previously passing full-validation run.
- Revocation guard behavior: IMPLEMENTED with new controlled-stream unit tests. A Firebase Emulator/integration test proving real `admin_users/{uid}` document changes trigger sign-out is STILL MISSING.
- Add Location save/read-back: IMPLEMENTED in source. An authenticated Admin-client-to-Firebase-Emulator test for the full callable + Firestore Rules read-back path is still required before production readiness.
- Backend authorization: must remain authoritative; UI gating alone is insufficient.
- Area Manager assigned-area scoping: NOT IMPLEMENTED in the fresh identity/shell reviewed here.
- Founder/CEO-only company-wide approval controls: NOT IMPLEMENTED in the fresh shell reviewed here.
- Live Operations is not yet connected to verified live walker/booking data.
- Boundary Review displays a polygon-shape preview, not a geographic map. Human source/reference verification and trusted backend checks remain necessary.

## Remaining tests before role/scope claims

1. Add/run a Firebase Emulator integration test proving a real `admin_users/{uid}` document change from active super_admin to inactive/another role revokes access and signs out.
2. Run authenticated emulator coverage for the complete fresh Add Location flow: active super_admin save, duplicate-name rejection, inactive/missing admin rejection, and client read-back of the newly created inactive record.
3. Verify server-side callable and Firestore Rules reject unauthorized roles regardless of client UI.
4. Before adding Area Manager UI, tests must prove an Area Manager can only query/view assigned Area IDs and descendants; client-controlled IDs must not widen access.
5. Founder/CEO-only actions must require approved server-side capabilities and leave an audit record before they are implemented.

## Company alignment

The approved management structure is Founder / CEO → Central Admin → Area Manager → Walker / Partner. Geographic hierarchy is separate: India → State/UT → District → City → Area → Locality. The app must not treat a geographic selection as a substitute for a role's authorized scope.

Do not add new role screens, assume Area Manager access, or loosen the super_admin gate until the Company Master / Owner Control Center policy and server-side authorization contract are verified together.

## Safe next action

Check CI for the new HEAD. If it passes, add authenticated Firebase Emulator coverage for actual document-change revocation and the Add Location save/read-back path. Keep PR #37 draft; do not merge or deploy until these gates and company-alignment review are complete.

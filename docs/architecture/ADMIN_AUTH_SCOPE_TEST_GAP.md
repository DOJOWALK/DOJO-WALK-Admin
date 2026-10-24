# DOJO WALK Admin — Auth and Scope Test Gap

Date: 2026-10-24
Branch: `feature/admin-fresh-architecture-2026-10-24`
Reviewed HEAD: `1dd10d80cb1f4f857928a1b9ef47c44c560abb26`

## Evidence reviewed

- `lib/core/auth/admin_auth_repository.dart`: watches `admin_users/{uid}` with a Firestore document stream, checks `isActive == true` and `role == 'super_admin'`, and signs out when the live identity becomes unauthorized.
- `test/core/auth/admin_identity_test.dart`: tests active super_admin allowed; inactive super_admin, active admin, and unknown area_manager role denied.
- `lib/core/auth/admin_identity.dart`: client identity contains UID, email, role, active flag and display name; it has no assigned-area scope/capabilities model.
- `lib/features/service_location/data/admin_service_location_repository.dart`: uses trusted callable `saveServiceLocationWithNameIndex`; after callable success, it reads the created document back and verifies its status field is explicitly false before returning success.
- GitHub Actions on this HEAD:
  - Admin Web Build Check run `40053343304`: SUCCESS.
  - Service Location Geometry Tests run `40053343270`: SUCCESS.
  - Admin Main Full Validation run `40053343278`: SUCCESS (analysis, complete Dart test suite, and Flutter Web build).
- PR #37 remains open and draft; it has not been merged. No deployment was performed by this review.

## Current classification

- UI super_admin gate: IMPLEMENTED and covered by focused identity policy tests.
- Reactive role/active revocation: IMPLEMENTED in the auth repository; a dedicated stream-level test proving document-change revocation is still missing.
- Add Location save/read-back: IMPLEMENTED in source; current Flutter CI passes. An authenticated Admin-to-Firebase emulator test for the full client callable + Rules read-back path is still required before production readiness.
- Backend authorization: must remain authoritative; UI gating alone is insufficient.
- Area Manager assigned-area scoping: NOT IMPLEMENTED in the fresh identity/shell reviewed here.
- Founder/CEO-only company-wide approval controls: NOT IMPLEMENTED in the fresh shell reviewed here.
- Walker/Partner field-work flows: belong primarily in the Partner app; Admin monitoring/review should not silently duplicate Partner actions.

## Remaining tests before role/scope claims

1. Add a stream-level test proving that changing `admin_users/{uid}` from active super_admin to inactive or another role revokes the identity and signs out.
2. Test Firestore/network errors: show a retryable error and never grant access on failure.
3. Run authenticated emulator coverage for the complete fresh Add Location flow: active super_admin save, duplicate-name rejection, inactive/missing admin rejection, and client read-back of the newly created inactive record.
4. Verify server-side callable and Firestore Rules reject unauthorized roles regardless of the client UI.
5. Before adding Area Manager UI, tests must prove an Area Manager can only query/view assigned Area IDs and descendants; client-controlled IDs must not widen access.
6. Founder/CEO-only actions must require approved server-side capabilities and leave an audit record before they are implemented.

## Company alignment

The approved management structure is Founder / CEO → Central Admin → Area Manager → Walker / Partner. Geographic hierarchy is separate: India → State/UT → District → City → Area → Locality. The app must not treat a geographic selection as a substitute for a role's authorized scope.

Do not add new role screens, assume Area Manager access, or loosen the super_admin gate until the Company Master / Owner Control Center policy and server-side authorization contract are verified together.

## Safe next action

Add the missing auth stream/revocation test, then add authenticated emulator coverage for the Admin save/read-back path. Keep PR #37 draft and do not merge or deploy until these gates and the company-alignment review are complete.

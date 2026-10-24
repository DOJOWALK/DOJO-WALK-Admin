# DOJO WALK Admin — Fresh Architecture Rebuild

Date: 2026-10-24
Branch: `feature/admin-fresh-architecture-2026-10-24`

## Decision

Build a fresh Admin UI and application architecture on this branch. Do not reuse existing screens/widgets or copy the existing UI implementation into the new presentation layer.

## Allowed reuse (inspect before adoption)

- Existing Firebase project configuration and `firebase_options.dart`, after verifying project/platform values.
- Existing Firebase Auth / Firestore / Cloud Functions / Storage integration contracts.
- Backend APIs, callable function names, collection names, model/data contracts and service-location domain logic only after reviewing current source, security rules, function contracts and tests.
- `pubspec.yaml` dependency versions where still compatible; do not blindly upgrade or downgrade packages.
- Existing reference datasets only after checking provenance, completeness and integrity.

## Not allowed

- Do not merge, push to, or edit `main` as part of this rebuild.
- Do not copy existing screen/widget code as the new UI.
- Do not assume a backend function or Firebase rule is production-safe just because it exists.
- Do not delete source files, reference data, workflows, or old branches until dependencies and preservation needs are inventoried.
- Do not claim a feature, security rule, deployment or test is complete without evidence from the relevant checks.

## New target structure

```
lib/
  main.dart
  app/
    app.dart
    router.dart
  core/
    config/
    errors/
    theme/
    utils/
  data/
    contracts/
    repositories/
  features/
    auth/
      data/
      domain/
      presentation/
    dashboard/
      data/
      domain/
      presentation/
    service_location/
      data/
      domain/
      presentation/
      widgets/
    live_operations/
      data/
      domain/
      presentation/
    bookings/
      data/
      domain/
      presentation/
    walkers/
      data/
      domain/
      presentation/
    coupons/
      data/
      domain/
      presentation/
  shared/
    widgets/
    services/
test/
  core/
  features/
  integration/
docs/
  architecture/
  decisions/
  runbooks/
```

## UI direction

- Brand orange: `#FF7900`; warm background: `#FFFAF5`; primary text: `#252525`.
- Light, premium, professional, responsive Flutter Web layout.
- Dashboard contains the live-operations summary and live status; avoid an unnecessary duplicate live screen.
- Service Location is a first-class workflow: India → State/UT → District → City → Area → Locality.
- Area activation must rely on a verified polygon; radius-only coverage is not accepted.
- A “possible walker nearby” signal must be labelled as approximate, permission-aware and based only on available location data; never present an inference as confirmed presence.
- “My Location” must request browser/device permission, handle denial/unavailable states, and must not bypass privacy controls.

## Security and backend requirements

- Keep trusted price, payment confirmation, refunds, assignment transitions and privileged role/scope checks server-authoritative.
- Client UI is not proof of payment. Mark a booking PAID only after verified provider/server confirmation.
- Validate active admin role and scope server-side and in Firestore/Storage rules as applicable.
- Use idempotency and auditable state transitions for imports, payment reconciliation, refunds and assignment.
- Never put service-account credentials, private keys, or secrets in Flutter/client code.
- Reuse backend only after documenting each API/callable endpoint, request/response, auth requirements, errors, region and test evidence.

## Build gates before any merge

1. Inventory old UI, backend/API contracts, Firebase config, rules, functions, reference data and workflows.
2. Create fresh UI/domain/data boundaries; add dependency injection/test seams.
3. Verify `flutter pub get`, `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test`, and Flutter Web build.
4. Add auth/scope negative tests and service-location polygon/import regression tests.
5. Verify Firebase Rules/Functions against emulator or documented safe test environment.
6. Review diff for secrets, accidental data removal, and unintended changes.
7. Open a PR for review. Do not merge or deploy without passing checks and explicit approval.

## Current status

- Fresh branch created from `main` as a safe starting snapshot so existing backend/config can be inspected and selectively reused.
- This does not mean the existing UI has already been removed or the new app is complete.
- `main` remains unchanged by this branch-creation action.
- Next work: inventory current files and backend contracts, then build the new UI in the new feature-first structure and switch the app entry point only when the replacement is ready.


## Progress update — 2026-10-24

- Added a source-based backend/API inventory in `docs/FRESH_ADMIN_BACKEND_API_INVENTORY.md`.
- Added a fresh admin identity model and auth repository. The UI gate requires both `isActive == true` and `role == super_admin`, matching the reviewed Rules/callable policy.
- Added a typed callable adapter for status changes, verified City/Area activation, and boundary review in `asia-south1`.
- Added a fresh email/password login screen and responsive navigation shell, and wired the fresh auth gate/theme into `lib/app/app.dart`.
- The fresh app entry point is active on this feature branch (`main.dart` → `app/app.dart` → `FreshAdminAuthGate`); it does not use the legacy auth gate/shell.
- Fresh Dashboard, Add Location, Boundary Review, and Live Operations screens are implemented. Add Location reads catalog options and calls `saveServiceLocationWithNameIndex`; boundary review reads pending boundaries and calls `reviewServiceLocationBoundary`. Live Operations has a permission-aware “My Location” action, but does not yet read live walker/booking data. “Possible Walker Nearby” remains explicitly “Not checked”.
- Boundary Review displays a polygon-shape preview and coordinates, **not a geographic map**. Human source/reference verification and the trusted backend checks are still required before approving a real boundary.
- Legacy UI files remain in the branch for preservation while dependencies are inventoried. No legacy files were deleted. `main` has not been merged into or changed by this work; this branch has not been merged or deployed.
- **CI status for commit `396d6da19644f809ec9a378a55d316530eb7d649`: PASS** — Admin Main Full Validation (run `40050126724`), Admin Web Build Check (run `40050126576`), and Service Location Geometry Tests (run `40050126514`) all completed successfully, including analyze, complete test suite, and web build where shown by the workflows.
- **Still not production-ready:** emulator/integration testing of auth, Firestore Rules and callable flows; verify deployed Firebase Rules/Functions revisions; test My Location in actual browser/device; connect live operations to trusted live data; add real geographic map-based boundary review; and review all role/scope constraints before merge.

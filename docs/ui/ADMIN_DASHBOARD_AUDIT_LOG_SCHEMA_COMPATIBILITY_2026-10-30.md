# Dashboard Audit Log Schema Compatibility — 2026-10-30

## Scope

Source audit and minimal Admin-side query correction for the Dashboard's planned Firestore Emulator integration. No production configuration, Rules, indexes, or data were changed.

## Pinned source evidence

- Admin repository: `DOJOWALK/DOJO-WALK-Admin`
- Admin branch: `ui/notion-brand-foundation-2026-10-28`
- Corrected Dashboard data source blob: `80caaf6f73db0d73c1b5104eff5d29a91d11140c`
- Firebase repository: `DOJOWALK/DOJO-WALK-Firebase`
- Firebase `firestore.rules` blob: `104467bab5dcc66c01a1f0f70df321ac0b193249`
- Firebase `firestore.indexes.json` blob: `add7c655c19cb240e35624e23c3e9a1041ef15bf`
- Firebase `firebase.json` blob: `ec27a2d7b8880c12cc76ebf7c1ea5ac5e05f6ea9`
- Firebase Rules test file: `test/firestore.rules.test.mjs`, blob `e7bfeb73b09438dd6252f8232d41ea78de57cf0f`

These are blob identifiers observed during this audit, not substitutes for pinning repository commit SHAs in a CI checkout.

## Confirmed mismatch and correction

The previous Admin `FirestoreDashboardDataSource.recentActivity()` queried `audit_logs` ordered by `timestamp`.

The authoritative Firebase Rules require audit records to include `createdAt`, allow `createdAt` in the field whitelist, and require `createdAt == request.time`. The Rules do not whitelist a `timestamp` field. The existing Walker Admin writer also writes `createdAt: FieldValue.serverTimestamp()`, and the Walker audit-history reader orders by `createdAt`.

The Admin Dashboard data source has now been corrected to:

```dart
.collection('audit_logs')
.orderBy('createdAt', descending: true)
.limit(6)
```

The existing `action` and `actorRole` mapping and the `Admin` fallback are unchanged. The canonical Rules were not weakened or edited.

## Remaining test work

1. Add a focused Dashboard data-source test proving records with `createdAt` are ordered/read correctly and legacy `timestamp` is not required.
2. Seed Emulator audit fixtures with `createdAt`, `action`, `actorUid`, `targetType`, and `targetId`; use only allowed `action` values for client-created test audit entries.
3. Test Rules authorization independently from Dashboard query mapping. Do not interpret a successful Admin read as permission to create arbitrary audit events.

The focused test file has not been added; the attempted GitHub file-create operation was blocked and no test result is claimed.

## Emulator configuration

The Firebase repository's `firebase.json` declares Auth (9099), Functions (5001), and Firestore (8080) Emulator ports, and points to the canonical `firestore.rules` and `firestore.indexes.json` files. Its package script runs Node's test runner against `test/*.test.mjs`.

The Admin repository should not duplicate or independently edit canonical Rules/indexes. A CI workflow can check out a pinned Firebase commit and start the Emulator using the Firebase repository's configuration/artifacts, while the Admin Flutter integration test targets only a dedicated demo project ID.

## Index finding

The inspected indexes file contains one composite index for `audit_logs` on `targetType`, `targetId`, and `createdAt`. The Dashboard's unfiltered single-field `orderBy('createdAt')` query does not require that composite index; Firestore's automatic single-field index is sufficient unless index exemptions or additional filters are introduced.

## Status and non-claims

- Source compatibility audit: complete.
- Timestamp mismatch: confirmed and corrected in the Admin Dashboard query.
- Corrected source fetched back from GitHub and verified to use `createdAt`; no legacy `orderBy('timestamp')` remains in this data source.
- Focused data-source test: pending.
- Emulator integration: not implemented.
- Flutter tests / Rules tests / Emulator tests / CI: not run for this change; no PASS is claimed.
- No merge, deployment, production write, Rules edit, or indexes edit.

## Dashboard Emulator integration design audit — 2026-10-30

A second pass inspected the Admin repository's existing emulator integration pattern and the canonical Rules for every Dashboard collection.

### Reusable CI pattern found

The Admin repository already has:
- `.github/workflows/walker-admin-emulator-integration.yml`, which checks out the Firebase Rules repository, starts Auth + Firestore emulators on 9099/8080, and runs a real FlutterFire integration test on an Android emulator.
- `integration_test/walker_admin_service_emulator_test.dart`, which uses a dedicated `demo-dojo-admin-integration` project ID, routes Android emulator traffic through `10.0.2.2`, and seeds fixtures through the Emulator-only owner endpoint.

This is a proven repository pattern to adapt; it is not evidence that a Dashboard integration test exists or has run. The existing workflow currently checks out Firebase Rules at `main`; a future Dashboard workflow should pin the Firebase Rules checkout to an audited commit SHA so the tested Rules/indexes are reproducible.

### Dashboard read authorization findings

The inspected canonical Rules establish:
- `bookings`, `users`, `walkers`, `payments`, and `audit_logs` reads are permitted to `isAdmin()`.
- `isAdmin()` specifically requires an authenticated user with an `admin_users/{uid}` document where `isActive == true` and `role == 'super_admin'`.
- A normal active `admin` or `support` role does not satisfy this helper and must be denied these Dashboard collection reads.
- `audit_logs` client writes are narrowly restricted to approved Walker actions and the exact field whitelist. Integration fixtures should therefore be seeded only through the local Emulator owner endpoint, not by weakening Rules or inventing client-side audit writes.
- `payments` is readable by `isAdmin()`; the Dashboard's paid-total stream filters `status == 'paid'` and sums numeric `amount` values.

### Proposed integration assertions

1. Seed an active `super_admin` fixture and representative booking, user, walker, paid/unpaid payment, and audit documents in the Firestore Emulator only.
2. Verify the real `FirestoreDashboardDataSource` emits expected collection counts, paid-only amount total, recent bookings, and recent activity ordered by `createdAt`.
3. Authenticate a non-admin role (for example active `support`) and verify the corresponding Dashboard reads fail with permission denied; do not mistake a UI fallback/error state for authorized access.
4. Verify no fixture helper can reach a non-emulator host; keep the project ID fixed to a `demo-` identifier and assert emulator endpoints before seeding.
5. Run the test through a separate Dashboard-scoped CI workflow or a carefully extended existing workflow. Do not broaden the Walker workflow triggers until the Dashboard test file and workflow command both exist.

### Current boundary

This pass was read-only. No integration test, workflow, Firebase configuration, Rules, indexes, or application source was changed. The integration test and all execution results remain pending.

## Dashboard Emulator integration implementation — 2026-10-30

### Added files

- `integration_test/dashboard_data_source_emulator_test.dart`
  - Uses the real `FirestoreDashboardDataSource` with Firebase Auth + Firestore Emulator endpoints.
  - Requires a `demo-*` project ID and uses Android's emulator host bridge (`10.0.2.2`) when running on Android.
  - Seeds all fixtures through the Firestore Emulator owner endpoint; it does not use production credentials or a production project.
  - Covers active `super_admin` reads for booking/customer/walker counts, paid-only payment total, recent bookings ordering, and recent audit activity ordering by `createdAt`.
  - Covers an active `support` role being denied a Dashboard collection read by the canonical Rules.
- `.github/workflows/dashboard-emulator-integration.yml`
  - Starts Auth and Firestore Emulators from the Firebase repository.
  - Checks out Firebase Rules/indexes at pinned commit `42923ecabedb60c158cdec91a5397f9925b3e07a`.
  - Runs the integration test on an Android API 34 emulator.
  - Has no deployment step and uses a dedicated `demo-dojo-dashboard-integration` project ID.

### Safety and scope

No production Firebase project is configured in the test. The test aborts if the project ID does not start with `demo-`. Fixture seeding targets the local emulator host/port only. No canonical Rules, indexes, production data, or app runtime configuration were changed.

### Verification status

- Test file fetched back from GitHub and reviewed: yes.
- Workflow fetched back from GitHub and reviewed: yes.
- Firebase Rules checkout pinned to a commit SHA: yes.
- GitHub Actions run result: not returned/available at the time of this audit; do not mark CI as passed.
- Flutter analyzer, unit tests, and Emulator integration test: not executed in this chat.
- Merge and deployment: not performed.

The first CI run must be inspected for compile/runtime issues before this integration is treated as verified. In particular, confirm Android runner generation remains compatible with the current Flutter toolchain and that Emulator REST fixture seeding works against the pinned Firebase CLI/Emulator version.

## Scope correction after controlling Draft PR guardrail — 2026-10-30

A review of Draft PR #51 found an explicit owner-approved guardrail: do not start new Firebase integration until the Admin UI and its validation are complete. The Dashboard Emulator test and workflow were briefly added as implementation drafts, but they crossed that sequencing boundary. Both files have therefore been removed from this branch before any run or deployment:

- Removed `integration_test/dashboard_data_source_emulator_test.dart`.
- Removed `.github/workflows/dashboard-emulator-integration.yml`.
- No workflow was dispatched; no Emulator test ran; no production Firebase was contacted by these changes.
- The earlier design notes below are retained as future planning only, not as active implementation or an instruction to proceed now.

The next permitted work is Admin UI completion and exact-head UI validation under Draft PR #51. Revisit Dashboard Emulator integration only after that gate is satisfied and the sequencing decision is still current.

## UI-phase unit-test correction — 2026-10-30

To stay within Draft PR #51's UI-first gate, the next change was kept inside the existing Dashboard unit-test suite (no new Firebase integration):

- Updated `test/screens/dashboard/dashboard_data_source_test.dart` so its recent-activity fixture uses `createdAt`, matching the corrected production query rather than the obsolete `timestamp` field.
- Added a focused fake-Firestore test asserting recent activity is ordered newest-first by `createdAt`.
- The test file was fetched back from GitHub and the new assertions were confirmed present.
- Exact-head CI status and workflow runs were queried for commit `5d30218376573d9686cb0e9ecce673f521eb5071`; both returned no status/run records at the time of checking. The tests have not been executed locally in this session, so no PASS is claimed.
- This is Dashboard UI-phase test maintenance only. Emulator integration remains deferred under Draft PR #51's guardrail.

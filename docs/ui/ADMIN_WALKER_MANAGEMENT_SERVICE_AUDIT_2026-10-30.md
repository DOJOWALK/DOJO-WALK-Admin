# DOJO WALK Admin — Walker Management Service Deep Audit

- Audit date: 2026-10-30
- Admin repository: `DOJOWALK/DOJO-WALK-Admin`
- Admin branch reviewed: `ui/notion-brand-foundation-2026-10-28`
- Firebase rules repository reviewed: `DOJOWALK/DOJO-WALK-Firebase` default branch snapshot
- Scope: source-level review of walker service, model/helpers and current Firestore rules. No production data, emulator execution, merge, or deployment.

## 1. Service behavior confirmed

- `watchWalkers()` subscribes to the entire `walkers` collection and maps every document into a `WalkerAdminModel`.
- `watchBookings()` subscribes to the entire `bookings` collection; the dashboard derives running walker IDs client-side.
- `watchWalkerBookings(walkerId)` filters only by `walkerId`; it has no status/date filter or limit.
- `watchWalkerAuditLogs(walkerId)` filters by `targetType == walker` and `targetId == walkerId`, applies a clamped limit (1–200), then sorts the returned subset locally by `createdAt`.
- `watchWalker(uid)` and `getWalker(uid)` read one walker document.
- `runAdminAction()` checks the signed-in user's `admin_users/{uid}` record and currently accepts only `role == super_admin` plus `isActive == true`.
- The action and audit record are written in one Firestore transaction. The service validates current status and required reasons before writing.
- Supported transitions are approve, reject, suspend, reactivate and request correction.
- Model maps legacy aliases such as `name/fullName/displayName`, phone fields, area/locality and state/stateName; raw profile and KYC maps are retained for detail views.

## 2. Confirmed risks and required decisions

| Priority | Finding | Impact / required follow-up |
|---|---|---|
| P0 | Walker and booking streams read entire collections. | Read cost and data exposure scale with national growth. Replace with approved paginated/filtered query contracts and server-enforced city/zone scope before broad rollout. |
| P0 | Client service has no city/zone scope parameters. | UI tabs/search are not authorization. Confirm canonical walker zone/city fields and manager/supervisor visibility contract; enforce in trusted backend/rules, not client-only filters. |
| P0 | Client-side transaction checks only `super_admin`. | This does not implement the agreed Founder → Central → City Manager → Zone Supervisor hierarchy. Keep lifecycle controls disabled until POL-004 defines action-level authority and the backend/rules enforce it. |
| P1 | Audit query limits before local sorting and has no `orderBy(createdAt)`. | It can return an arbitrary subset rather than the newest 50 records. Add a deterministic descending timestamp query with an appropriate composite index and stable tie-breaker, after checking index ownership. |
| P1 | Walker booking stream has no status/date constraint or limit. | A walker with long history can cause growing reads; the dashboard's separate all-bookings stream is even broader. Define whether running detection should query only active statuses and use a bounded/maintained assignment index. |
| P1 | Running detection currently recognizes only `in_progress`, `active_walk`, `walking`, `walk_started` in the UI adapter. | Status drift or a canonical status change can misclassify walkers. Reconcile with the booking lifecycle contract and shared canonical status helper before adding aliases. |
| P1 | `runAdminAction` is client-callable and trusts a client-side transition implementation. | Transactions prevent partial writes but do not replace trusted authorization/business validation. Verify the exact deployed Firestore update rules and consider callable/server-side decisions with immutable audit creation. |
| P1 | Service writes `decisionBy`, `decisionAt`, `decisionReason`, and audit actorRole as hard-coded `super_admin`. | This is incompatible with future action-level roles and may overwrite decision metadata; align field names and actor role with POL-004 and audit schema. |
| P2 | `watchWalkerAuditLogs` treats missing/invalid timestamps as oldest only after fetching. | Missing timestamps remain possible and sorting is not deterministic for ties. Validate audit schema and timestamp requirements. |
| P2 | `watchWalkerBookings` has no dedicated service tests in the inspected tree. | Add fake/emulator tests for query constraints, errors, status transitions, transaction atomicity and audit payloads. |
| P2 | Model stores full raw data and KYC map in memory. | Keep sensitive KYC access least-privilege; avoid logging raw model/maps and verify Storage rules independently. |

## 3. Firestore rules cross-check (Firebase repository snapshot)

- The inspected rules define `isAdmin()` as an active `admin_users` document with role exactly `super_admin`.
- `walkers` collection listing is restricted to `isAdmin()`; therefore the Admin full-collection walker stream depends on Super Admin access in the inspected rules.
- The rules contain explicit walker status/verification validation and separate owner update paths. The admin service's lifecycle transaction must be checked against the exact walker `allow update` clauses and current deployed rules before any action is enabled.
- The rules reviewed are a repository snapshot, not proof of what is deployed to Firebase. No production rules state was queried.
- No zone/city manager read-scope implementation was established by this source review.

## 4. Safe implementation direction

1. Keep all lifecycle actions disabled in the UI; do not loosen the `super_admin` check or add manager roles speculatively.
2. Treat this as a cross-repository contract task: Notion POL-004/POL-026 → Admin service → Firebase rules/functions → emulator tests.
3. Agree the canonical fields for `cityId`, `zoneId`, active booking status, and audit actor role before changing queries.
4. Introduce bounded query APIs only after those fields and indexes are confirmed. Avoid silently filtering by display names such as city/area.
5. Add service tests using injected Firestore/Auth or emulator fixtures; include denied-role, inactive-admin, missing-walker, invalid transition, required reason, transaction/audit atomicity and query-bound cases.
6. Run targeted tests, full Flutter tests, analyze, web build and Firebase rules emulator tests on exact resulting commits.

## 5. Validation status

- Admin service/model/helper source review: DONE.
- Firebase rules source cross-check: PARTIAL; repository snapshot only, exact deployed rules and full transition-rule compatibility not verified.
- Service-level tests: NOT FOUND in inspected Admin test tree.
- Flutter Analyze / Flutter Test: NOT RUN.
- Firestore emulator/rules tests: NOT RUN.
- Production Firebase read/rules verification: NOT performed.
- Merge/deployment: NOT performed.

This report records source-level findings only. It does not claim runtime tests, security approval, or production readiness.

## 6. Lifecycle policy test seam added — 2026-10-30

- Extracted deterministic state-transition validation into `lib/features/walkers/services/walker_admin_transition_policy.dart`.
- Moved the shared action enum and safe service exception into `walker_admin_contracts.dart` to avoid a circular import.
- `WalkerAdminService` delegates its existing transition validation to the pure policy; this is a structural refactor intended to preserve the existing transition rules.
- Added `test/features/walkers/walker_admin_transition_policy_test.dart` covering approval, rejection, suspension, reactivation, correction requests and terminal-state guards.
- These are authored tests, not executed test results. No Firestore/Auth transaction, audit write, query shape, rules emulator or role authorization is tested by this pure policy suite.
- Exact-head CI has not yet appeared. Flutter Analyze/Test remain unverified.

## 7. Additional pure-policy coverage — 2026-10-30

- Centralized the "reason required" rule for Reject, Suspend and Request Correction in `WalkerAdminTransitionPolicy.requiresReason`.
- Centralized stable audit event names for all five lifecycle actions in `WalkerAdminTransitionPolicy.auditActionName`.
- Updated `WalkerAdminService` to consume these shared policy methods and removed unused transition method parameters.
- Added tests for exact reason-required action set and audit event mapping.
- This still does **not** test Firestore transaction atomicity, Firebase Auth state, admin role authorization, rules enforcement or audit persistence. Those require emulator-backed service tests and are not claimed complete.
- Exact PR head checked: `465d48df0bab5da602205fb1ba8e5ec4d09af25d`.
- PR #51 remains open and draft; latest queried workflow run list was empty. GitHub reported mergeable=false at the time of the check; conflict/status details need a fresh PR review before merge.


## 8. Firebase rules and emulator setup cross-check — 2026-10-30

- Re-read the exact current `DOJOWALK/DOJO-WALK-Firebase` `main` rules snapshot, rather than relying on the earlier partial note.
- The walker admin update allow-list includes `walkerId`, `status`, `isActive`, `isApproved`, `verificationStatus`, `updatedAt`, `decisionReason`, `decisionBy` and `decisionAt`. The Admin service writes only the applicable lifecycle fields from this list, so the field-name contract is aligned at source level.
- The rules independently require an active `super_admin` admin record and validate the resulting walker status/verification/approval/active combination. They also constrain `decisionBy` to the authenticated UID and validate the optional reason/timestamp.
- The audit log create allow-list includes all fields currently emitted by the service, and its action allow-list contains all five lifecycle event names emitted by `WalkerAdminTransitionPolicy`. This confirms source-level schema compatibility, not runtime success.
- The Firebase repository has an existing Rules Unit Testing harness: `firebase.json` configures Auth and Firestore emulators; `package.json` includes `@firebase/rules-unit-testing` and `firebase-tools`; tests live under `test/*.test.mjs`. The Admin repository itself has no `firestore.rules` or `firebase.json` emulator configuration, and its `pubspec.yaml` currently has no Firebase mock/emulator test dependency.
- The inspected Firebase Rules test file contains no walker lifecycle-specific cases. Therefore the next meaningful validation should add rule tests in the Firebase repository for the five lifecycle transitions, invalid state combinations, inactive/non-super-admin denial, actor UID mismatch, and audit event allow-list. Flutter service transaction tests remain a separate follow-up; the Node rules suite alone cannot prove the Flutter transaction's persisted audit payload.

### Updated validation matrix

| Check | Result |
|---|---|
| Walker update field allow-list vs service writes | SOURCE-LEVEL ALIGNED |
| Walker state validation vs transition policy outputs | SOURCE-LEVEL CONTRACT CHECKED; emulator not run |
| Audit event names vs Firestore audit allow-list | SOURCE-LEVEL ALIGNED |
| Firestore rules emulator harness in Firebase repo | EXISTS; not executed in this audit |
| Walker lifecycle rules tests | NOT FOUND in inspected test file |
| Flutter service transaction tests | NOT IMPLEMENTED / NOT RUN |
| Exact PR-head CI | NOT VERIFIED |

This cross-check does not change production rules, enable UI actions, or approve the current security model. Keep the PR Draft and keep lifecycle actions gated until emulator and service-level tests are added and run.


## 9. Walker lifecycle Firestore Rules test suite added — 2026-10-30

- Added `test/walker_lifecycle.rules.test.mjs` to `DOJOWALK/DOJO-WALK-Firebase` on `main`.
- The suite covers the five allowed lifecycle state outcomes (approve, reject, request correction, suspend, reactivate), inactive/non-super-admin denial, actor UID mismatch, invalid state combinations, unknown walker fields, reason length validation, the five audit event names, audit actor mismatch, and audit immutability.
- Firebase test commits: initial suite `cbc9587c966f1b2fe534e4a7cfeeff6971921ea4`; assertion correction `dcb4e1ce68054b661c4a9ac03747e0af1a980e09`.
- The test file uses the existing `firebase.json` emulator configuration and `npm test` script (`node --test test/*.test.mjs`).
- Exact commit workflow runs and combined statuses were queried for `dcb4e1ce68054b661c4a9ac03747e0af1a980e09`; both returned empty. The test suite has **not been executed** in this environment. Do not mark it PASS.
- This is Rules-level coverage only. It does not execute `WalkerAdminService.runAdminAction`, prove transaction atomicity, or verify Flutter client behavior. Those remain separate service/emulator tests.

### Next validation gates

1. Run `npm install` and `npm test` in `DOJOWALK/DOJO-WALK-Firebase` with the Firestore emulator available; fix any test or rules failures before treating this suite as validated.
2. Add a Firebase CI job that runs the rules suite on changes to `firestore.rules`, `firebase.json`, package manifests and `test/**` (only after inspecting the existing workflow structure to avoid duplicate pipelines).
3. Add Flutter service transaction tests with injected Auth/Firestore emulator instances. These should assert the persisted walker state and audit record after success, and no partial writes after every denied/invalid path.

No production rules were changed and no emulator or production deployment was run.


## 10. Firebase Rules CI workflow added — 2026-10-30

- Added `.github/workflows/firestore-rules-tests.yml` to `DOJOWALK/DOJO-WALK-Firebase` on `main`.
- Workflow triggers on pushes to `main` and pull requests when Firestore rules, Firebase config, package manifest/lockfile, tests, or this workflow change; it also supports manual `workflow_dispatch`.
- CI provisions Node.js 22 and Temurin Java 21, installs npm dependencies, and runs `npm test` inside `firebase-tools emulators:exec --only firestore` using the dedicated demo project ID.
- Workflow file commit: `fa4ce0f182daac071ca0c8604e15f37f7376fa5d`; fetched the committed file back and verified its contents.
- The available commit-run lookup only reports pull-request-triggered runs; it returned no PR-triggered run for this commit. It cannot establish whether the push-triggered run completed. Therefore workflow execution and test result remain **UNVERIFIED**, not PASS.
- No lockfile exists in the repository snapshot; workflow currently uses `npm install`. Consider committing a lockfile in a separate controlled change for reproducible dependency resolution.
- No production rules or data changed. No deployment, merge, or Admin PR state change occurred.

### Revised next validation gates

1. Inspect the actual GitHub Actions run for commit `fa4ce0f182daac071ca0c8604e15f37f7376fa5d` in the repository Actions UI; capture job logs and resolve failures before marking Rules tests PASS.
2. Add/commit a package lockfile after confirming the project's intended dependency versions, then change CI to `npm ci`.
3. Add Flutter service transaction tests with injected Auth/Firestore emulator instances. Assert persisted walker state and audit record after success, and no partial writes after denied/invalid paths.


- Follow-up workflow review found and corrected the CLI invocation: the job now uses `npx firebase emulators:exec` (the executable exposed by the `firebase-tools` package), not `npx firebase-tools`. Correction commit on Firebase `main`: `2f5eb81ac2409c0177ffd373e275054b34ce613d`. The corrected workflow has been fetched back and inspected; runtime execution is still unverified.


## 11. Walker audit history ordering fix — 2026-10-30

- Updated `WalkerAdminService.watchWalkerAuditLogs` to apply server-side `orderBy('createdAt', descending: true)` before the bounded limit. This removes the prior correctness defect where an arbitrary limited subset was locally sorted and could omit newer records.
- Admin service commit: `6981fcd4bbed0102ddbbaf706e4bba9660b1ce72`.
- Added Firestore composite index `audit_logs(targetType ASC, targetId ASC, createdAt DESC)` in `firestore.indexes.json` and registered it in `firebase.json`.
- Firebase index/config commits: `5f6d1c8b4e3360b0d23ce11ed4fc857fc9680aff`, `928dd8cc45e3a394e94b7492b4dfaee2fca51833`.
- Updated Rules CI path filters to include `firestore.indexes.json` for push and pull request events; workflow path-filter commits: `d9eb9a00e63adecbbdaad6ad73dd70e5c5122525`, `9a0960438141e63bbf06195e116c98403fce405b`.
- Source files were fetched back for review. No Flutter test, emulator index build, live index deployment, or CI execution was performed. The index is defined in source but is **not deployed** to the Firebase project.
- Before enabling this query in a deployed environment, deploy the index through the approved Firebase release process and wait for index build completion. Do not assume it is available merely because it exists in Git.


## 12. Walker decision reason contract alignment — 2026-10-30

- Cross-checked the Admin decision-reason input against the current Firebase repository rules: decisionReason is optional on the walker record and, when supplied, must be a string no longer than 1,000 characters. Reject, Suspend and Request Correction require a non-empty reason in the Admin service.
- Added WalkerAdminTransitionPolicy.normalizeReason() to trim input, enforce the required-reason rule, and reject values longer than 1,000 characters before a Firestore transaction starts.
- Updated WalkerAdminService.runAdminAction() to use this shared validation.
- Added pure-policy tests for whitespace trimming, optional reasons on Approve, required reasons on the three guarded actions, and the 1,000 / 1,001 character boundary.
- Commits on the Admin feature branch: policy 3350f2fc4972a36e96efaf2a04bf9cfab9fed84e; service 1b7901493770f9ec1ceb00109c1daf49bf76ad1f; tests ec023543bfc654e4eddd779086148f63051fad60.
- The changed files were fetched back and the expected validation code/test markers were confirmed. Flutter tests and analysis were not run, so this is source-reviewed, runtime-unverified.
- This does not replace the still-missing Firestore/Auth transaction tests. The transaction remains untested for persisted audit payload, authorization denial, and no-partial-write behavior. No Firebase rules, production data, merge, or deployment changed.


## 13. Non-deploying Flutter validation CI — 2026-10-30

- Added `.github/workflows/flutter-validation.yml` on the Admin feature branch. It runs on relevant pull requests, pushes to `ui/**`, and manual dispatch.
- The job provisions stable Flutter, resolves dependencies, runs `flutter analyze --no-pub`, runs `flutter test --no-pub`, and builds Flutter Web in release mode.
- This workflow is validation-only: it has read-only repository permissions and contains no Firebase Hosting deployment step or production secrets.
- Commit: `3546d11e11ca8095ad61f3a5bd854b6ba7f34fcc`. The committed workflow was fetched back and its expected commands/triggers were verified.
- The workflow run has not yet been observed; therefore analyzer, test and build results remain **PENDING / UNVERIFIED**. This does not establish that service transaction tests pass. No merge or deployment occurred.


## 14. Flutter validation CI failure triage — 2026-10-30

- Inspected GitHub Actions run `41000460752` for workflow commit `3546d11e11ca8095ad61f3a5bd854b6ba7f34fcc`.
- Result: **FAILED** during Static analysis; Flutter tests and Web build were skipped. Dependency installation succeeded.
- The analyzer reported 62 issues. The first source-level issue was that `walker_details_screen.dart` referenced `WalkerAdminAction` and `WalkerAdminServiceException` without importing the shared contracts file. Added the missing import in commit `ca8bb1a302b3b94fbf2719c8cf40a2becfe8bb83`.
- Remaining analyzer errors are predominantly outdated widget-test viewport APIs: `TestFlutterView.setPhysicalSize` / `setDevicePixelRatio` are not available in the pinned stable Flutter SDK, and dashboard tests also await reset methods that return void. Affected files include `walker_details_screen_test.dart`, `walker_details_sections_test.dart` and `dashboard_screen_test.dart`.
- The workflow therefore correctly exposed pre-existing test-suite/API drift. The import correction is committed but has not yet been re-run; it must not be described as a passing fix.
- Next action: migrate the affected tests to the current `tester.view.physicalSize` / `tester.view.devicePixelRatio` setter API and synchronous reset calls, then rerun the full validation workflow. Recheck remaining analyzer diagnostics after this migration; do not suppress the test suite or narrow CI merely to obtain a green result.
- No merge, Firebase deployment, production data change or production rules change occurred.


## 15. Flutter test viewport API migration — 2026-10-30

- Replaced obsolete `TestFlutterView.setPhysicalSize()` and `setDevicePixelRatio()` calls in the Walker Details and Dashboard widget tests with the current `physicalSize` and `devicePixelRatio` setters.
- Removed `await` from synchronous `resetPhysicalSize()` and `resetDevicePixelRatio()` calls in Dashboard tests; retained teardown registration for Walker Details tests.
- Commits: `2697a77b358eda03d41116812c52190464de1f18` (Walker Details screen tests), `e43dccc6617032a9c4a1acee470c830ef161d204` (Walker Details sections tests), `8e711cb5459c02a330b2c983a1bcf9f15d36d01c` (Dashboard tests).
- A new Admin Web Build Check run `41000965841` was observed for this update and was still in progress at the time of this note. The separate Flutter Validation run `41000965808` was cancelled as the subsequent push-triggered workflow took over; no test/analyze/build result is claimed yet.
- The previous analyzer log showed the missing contracts import and old viewport API calls as the reported errors; the contracts import was added in commit `ca8bb1a302b3b94fbf2719c8cf40a2becfe8bb83`. The new workflow run must confirm whether any further analyzer/test issues remain.
- No merge, deploy, production rules or data changes occurred.

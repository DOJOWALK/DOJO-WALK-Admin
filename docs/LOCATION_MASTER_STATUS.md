# DOJO WALK Location Master — Project Status

Last updated: 2026-10-16

## Current status

- [x] Previous structural audit recorded in the ChatGPT Library.
- [x] Boundary dialog metadata omission fixed in commit `c572371cfd74a9888a66b2e51e7af1e20c627b62`.
- [x] Project file structure documented in `docs/PROJECT_FILE_STRUCTURE.md`.
- [x] Generated Dart reference files located, record counts verified, and SHA-256 integrity manifest committed at `docs/LOCATION_REFERENCE_CHECKSUMS.md`.
- [x] Expected repository paths checked; all three generated reference files are still absent.
- [ ] Restore the exact three generated India reference Dart files into this repository; checksum manifest is ready.
- [ ] Verify all imports and model/API compatibility after restoring the files.
- [ ] Run `flutter pub get` and `flutter build web --release`; record the actual CI/build result.
- [ ] Reconcile reference counts and records against a current official LGD snapshot.
- [ ] Complete UP/NCR targeted review.
- [ ] Verify location boundaries and activation rules in the admin UI.
- [ ] Do not import reference data into production Firebase until the above checks pass.

## Reference data currently in the Library

Folder: `/DOJO WALK Location Master/02_GENERATED_DART/`

| File | Previous audited count | File size | Top-level declaration |
|---|---:|---:|---|
| `india_states.dart` | 36 State/UT records | 6,871 bytes | `IndiaState`, `indiaStates` |
| `india_districts.dart` | 785 district records | 215,355 bytes | `IndiaDistrict`, `indiaDistricts` |
| `india_sub_districts.dart` | 7,151 sub-district records | 1,830,733 bytes | `IndiaSubDistrict`, `indiaSubDistricts` |

These are the previously audited local counts. They are **not** a claim that the records have been reconciled against the latest official LGD export. The source snapshot currently available for sub-districts is dated 2024-10-07, and a fresh official-source reconciliation remains pending.

## Restore and compatibility check

Integrity manifest: [`docs/LOCATION_REFERENCE_CHECKSUMS.md`](LOCATION_REFERENCE_CHECKSUMS.md). It records measured counts, byte sizes, and SHA-256 hashes for the exact Library files. This makes it possible to verify byte-for-byte restoration.

The following expected paths were checked on the default branch and were not found:

- `lib/data/reference/india_locations/india_states.dart`
- `lib/data/reference/india_locations/india_districts.dart`
- `lib/data/reference/india_locations/india_sub_districts.dart`

The generated files were materialized from the Library for inspection. Their top-level names are `IndiaState/indiaStates`, `IndiaDistrict/indiaDistricts`, and `IndiaSubDistrict/indiaSubDistricts`. Repository code search did not return usages of those identifiers, so imports and integration still need an explicit check after restoration. No reference file has been committed back to the repository yet.

Do not recreate the 7,151 records by hand or replace them with sample/partial data. Preserve the exact Library files and official codes when restoring.

## Boundary dialog fix

The dialog supplies `verifiedBy: null` and `verifiedAt: null` when creating a pending boundary. This fixes the missing required constructor arguments in that call site; it does not prove that the entire application builds successfully.

Commit: `c572371cfd74a9888a66b2e51e7af1e20c627b62`

## Next planned step

Restore the exact three generated Dart files from the Library to `lib/data/reference/india_locations/`, confirm no conflicting names/imports, then run formatting, analysis/tests, and the web build. No production Firebase import or boundary activation is authorized by this status note.

## Boundary precision progress — 2026-10-17

### Step 118 (reported by project operator)
- Reported result: City/Area containment synthetic tests passed.
- Reported CI: Geometry & Callable Tests and Firestore Security Rules passed.
- Evidence limitation: the Step 118 run links and commit SHA were not available during this status update, so these results are recorded as operator-reported, not independently verified here.

### Step 119 — Geographic gap / boundary precision
- Status: **PENDING — NOT VERIFIED**.
- Reviewed the current Admin boundary model and boundary service source.
- The model validates coordinate ranges and requires at least three distinct points, but this alone does not prove polygon containment, gap tolerance, polygon topology, or edge-case behavior.
- No Step 119 test run or CI result was retrieved during this update.
- No boundary code was changed as part of this status-only update.
- Required next checks: locate the existing geometry/containment implementation and tests; add focused synthetic cases for tiny gaps, shared edges, just-outside points, duplicate vertices, and invalid coordinates; run the targeted tests and applicable CI; record run URL and commit SHA.

### Step 120 — planned
- Do not start or mark Step 120 PASS until Step 119 has reproducible test evidence.
- After Step 119 passes, test polygon minimum area/degenerate shapes and boundary-edge precision without changing production location data.

### Release safeguards
- Official LGD source reconciliation, authoritative boundary confirmation, Admin web build verification, and production activation remain pending.
- No production Firebase import or service-location activation is authorized by these synthetic tests.

### Step 119 investigation update — 2026-10-17
- Status remains: **BLOCKED / PENDING — no geometry test run verified**.
- Inspected `service_location_service.dart`: activation checks that the City/Area has a verified boundary record, but the reviewed activation path does not compare Area polygon coordinates against the parent City polygon.
- Inspected `service_location_boundary_service.dart` and `service_location_boundary.dart`: validation checks metadata, coordinate ranges and distinct-point count; these checks do not establish polygon containment or detect small geographic gaps.
- Repository code search did not locate an existing polygon-containment implementation or dedicated containment test file. This is a search finding, not proof that no such code exists anywhere in connected repositories.
- **Risk identified:** a boundary marked verified can pass the visible Admin activation gate without a demonstrated parent-polygon containment check. Do not use verification status alone as proof of geographic containment.
- No production code was changed and no tests/build were run in this investigation.
- Next action before Step 120: implement/review a shared geometry validator with synthetic unit tests (fully inside, shared edge, tiny outside gap, duplicate/degenerate vertices, invalid coordinates), wire it into the appropriate trusted validation path, then run tests and Admin web build. If validation is needed against direct/hostile client writes, enforce it in a trusted backend; Firestore Rules cannot reliably implement arbitrary polygon geometry.

### Step 119 — geometry helper draft on review branch (2026-10-17)
- Review branch: `step-119-boundary-geometry`.
- Added `lib/features/service_location/services/service_location_geometry.dart` with coordinate/ring validation, point-in-or-on-polygon checks, child-edge midpoint checks, and proper segment-crossing rejection.
- Added `test/features/service_location/services/service_location_geometry_test.dart` for fully-inside, shared-edge, tiny-outside-gap, duplicate/degenerate vertices, and invalid-coordinate cases.
- Commit with helper: `9e4b1e8a95443c11f0024e4f0310cec8dd57202b`.
- Commit with tests: `5e6cf8767584fa15148048ca7eb8771e87d2dd6b`.
- **Status: DRAFT / NOT RUN / NOT INTEGRATED.** Tests and Flutter Web build have not been run in this environment. The helper is not yet called by the activation service and is not sufficient to claim complete GIS topology validation; additional concave-polygon/edge-case review is required before production use.
- Do not merge or deploy until tests pass, geometry edge cases are reviewed, and the trusted activation path is wired to compare Area boundaries against the verified parent City boundary.

### Step 119 — focused CI added (2026-10-17)
- Added `.github/workflows/service-location-geometry-tests.yml` on the review branch.
- Workflow runs Flutter dependency setup, formatting check, and the focused geometry unit-test file on matching pushes/PRs.
- Workflow file commit: `83be0ea755ca4dd9e0b5347e2c0fc32bc18263cf`.
- CI outcome: **NOT VERIFIED YET**. The presence of a workflow file is not evidence that the run started or passed. No passing run URL has been confirmed.
- Geometry helper remains unintegrated into City/Area activation. Do not merge/deploy or mark Step 119 PASS until the workflow succeeds and parent/child boundary validation is integrated and reviewed.
- Draft review PR opened against `main`: #7 — https://github.com/dojoplatform2026/DOJO-WALK-Admin/pull/7. It is **open, draft, and not merged**.
- After opening the PR, the workflow-run lookup still returned no run; CI remains **pending/unverified**, not PASS.
### Step 119 — polygon ring self-intersection guard (2026-10-17)
- Updated the draft geometry helper to reject self-intersecting polygon rings, including non-adjacent edge crossings/touches.
- Added two focused tests: self-intersecting child ring and self-intersecting parent ring.
- Commits: helper `26e7dbb6d40b031ca1bec808deb71180ccbec199`; tests `9f9a3e1c3b8c2339ed6b6712289a229216daf204`.
- Verification status: source/test files still need CI execution; no passing run has been confirmed. This is a focused guard, not complete GIS validation. Activation integration remains pending.
- CI run detected after the latest source/test commits: run #8, currently `in_progress`; Flutter setup is running, formatting and unit tests have not reported results yet. Run: https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39036067381
### CI check result and correction (2026-10-17)
- Inspected GitHub Actions run #9: dependency installation passed, but the formatting step failed because Dart reported both geometry source and test files would be reformatted. Unit tests were skipped as a result.
- Corrected the workflow to run `dart format` before the tests instead of failing immediately on existing formatting differences. This formats files only in the CI runner; it does not automatically commit formatted output back to this branch.
- Latest workflow-file commit: `2973af7833022b75d269ffa3888d9f5c31c76cac`.
- A new successful run has not yet been observed. Tests remain **NOT VERIFIED** until the new run completes.

### Step 119 — latest CI failure and test correction (2026-10-17)
- Inspected GitHub Actions runs #11 and #12. Formatting and `git diff --check` passed; focused geometry tests reported 6 passed and 1 failed.
- Failure cause: the test tried to construct `GeoPoint(91, 2)`, but Firestore's `GeoPoint` constructor itself asserts on out-of-range coordinates before the geometry validator can run. This was a test setup error, not evidence that the validator returned the wrong result.
- Corrected the test to assert that Firestore `GeoPoint` rejects out-of-range latitude/longitude at construction.
- Test fix commit: `fa57c9f9c193b9da243f687c8f7ba374d3457f71`.
- Next: wait for/inspect the new PR CI run. Step 119 remains **PENDING** until the run passes, and the geometry helper is still not integrated into City/Area activation.

### Step 119 — CI pass and City/Area activation integration draft (2026-10-17)
- Focused geometry CI run #14 completed successfully: formatting, whitespace check, and geometry unit tests all passed. Run: https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39037054280
- Integrated a fail-closed Area activation check in `service_location_service.dart`: it loads the saved verified City boundary and verified Area boundary and calls `ServiceLocationGeometry.isPolygonContained`; activation is rejected if containment fails.
- Integration commit: `9a739f411dc432dae4c20859f7b1e7e94aa3c648`.
- Updated focused CI workflow to format and analyze the activation service and to trigger when that service changes. Workflow commits: `c98e3350444f35d790639ea4187bbfdea6203fd9`, `d118d4ec17bdae004dc7fe6801d7089949f2979a`, `10f7a6c471aeade54861c60eb36c4588e3b4f8bc`.
- **Integration verification: PENDING.** The successful run #14 tested the geometry helper only; it predates the activation-service integration. Await a new CI run with Flutter analysis and geometry tests before claiming the integrated change passes.
- Scope limitation: this is Admin service-layer validation only. It does not protect against direct Firestore writes that bypass this service. Do not merge/deploy or activate production locations until trusted backend enforcement/security review and a full Admin web build are addressed.

### Step 119 — integration analyzer caught and fix applied (2026-10-17)
- New CI run #21 failed at `flutter analyze`: the Area activation integration referenced `city['verifiedBoundaryId']` without loading the parent City document in that method. Formatting and whitespace checks passed; geometry tests were skipped because analysis failed.
- Fixed by loading the parent City through `_requireDocument(_cities, cityId, 'City')` before reading its verified boundary ID.
- Fix commit: `dfca25aee7144648dc88fdce6636a6c9e96fbb73`.
- Step 119 remains **PENDING** until a new run passes analyzer and unit tests. Production activation remains unauthorized.

### Step 119 — second CI finding and cleanup (2026-10-17)
- CI run #24 passed formatting and whitespace checks, but `flutter analyze` exited non-zero because the service had an unused private wrapper, `_requireExistingForUpdate`. Geometry tests were skipped after analyzer failure.
- Removed the unused wrapper (it only delegated to `_requireDocument` and had no callers).
- Fix commit: `49718dbf8eb496fdefae380c8bb56ba81c86cc30`.
- Step remains **PENDING** until CI analyzer and geometry tests pass.


### Step 119 — integrated geometry CI passed (2026-10-17)
- GitHub Actions run #27 completed with conclusion **SUCCESS**: formatting, patch whitespace check, `flutter analyze` for the activation service, and focused geometry unit tests all passed.
- Run: https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39037478245
- This verifies the current draft branch's targeted checks. It does **not** establish full Flutter Web release-build success, complete GIS/topology correctness, or protection against direct Firestore writes that bypass the Admin service.
- Step 119 targeted CI: **PASS**. Overall production readiness: **NOT APPROVED / PENDING**.
- Next review: confirm whether geometry enforcement must also be placed in a trusted backend callable/server path, inspect direct write paths and security rules, and run a full Admin web release build before considering merge. Do not import data or activate production locations.


### Next validation — Admin Web release build check (2026-10-17)
- Inspected `.github/workflows/build_web.yml`: it builds and deploys to Firebase Hosting's `live` channel on `main`; it is not suitable for safely testing this draft branch.
- Added `.github/workflows/admin-web-build-check.yml` to run `flutter pub get` and `flutter build web --release` for relevant pull-request/branch changes, with **no deployment step**.
- Workflow commit: `f7fb22ffeef713d701261a2ac8ac459050b572ce`.
- Build result: **PENDING** until the newly triggered GitHub Actions run completes. The focused geometry CI pass remains valid, but does not replace a full web release build.
- Release safeguard unchanged: do not merge the draft PR or activate/import production service locations.


### Step 120 — boundary verification hardening draft (2026-10-17)
- Follow-up review found the boundary-review service used only basic polygon checks when marking a boundary verified. That could permit a self-intersecting polygon to receive `verified` status even though activation later rejects it.
- Added `ServiceLocationGeometry.isValidPolygon` and wired `ServiceLocationBoundaryService` validation to reject self-intersecting/non-simple polygon rings during boundary save/request/verification validation.
- Added unit tests for a valid simple polygon and a self-intersecting polygon; expanded the focused workflow to analyze the boundary service as well as the activation service.
- Commits: `62182d08c1189b67781f9e5eefbc2d031269c533`, `0f6c51d9f2954dc41c66fa81445d352cb462ebf1`, `ef8f9ad4699540dadac0c2ec9acf0025a9794697`, `68e4284a122b560c37253f40a7ec4153e7af317e`, `61f92dbe74754963db630a09267b16a0a148b755`.
- New CI verification: **PENDING** until the workflows triggered by these commits complete.
- Security limitation remains: this is client/Admin service-layer validation. No Firestore Rules file is present in this Admin repository, and no trusted backend write path has been confirmed in this review. Do not treat direct-write bypass protection as complete. Production activation/import and PR merge remain unauthorized.


### Step 120 — targeted tests and no-deploy Web build passed (2026-10-17)
- Geometry workflow run #41 passed: formatting, `git diff --check`, analyzer for both location services, and all 9 geometry tests passed.
- Run: https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39037970612
- Admin Web release build run #12 passed using `flutter build web --release`; no deploy step was present.
- Run: https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39037970687
- Security audit note: `ServiceLocationBoundaryService` checks that a user is signed in, but its client code alone does not establish that the user has reviewer/admin privileges. Firestore Rules must enforce role-based authorization and protect verified records against direct writes; rules were not verified in this Admin repository. Treat backend/rules authorization as **PENDING**, not passed.
- Step 120 targeted validation: **PASS**. Merge/production readiness: **PENDING** until trusted Firestore Rules/backend enforcement and broader release review are verified.


### Step 121 — Firestore Rules cross-repository review (2026-10-17)
- Located the active-looking rules source in `dojoplatform2026/DOJO-WALK-Firebase/firestore.rules` (Firebase config points to `firestore.rules`). This is a source review only; deployed Firebase rules were not queried or verified.
- The rules define `isAdmin()` as an active `admin_users/{uid}` document with role `super_admin`; service-location collections and boundary create/update operations are gated by `isAdmin()`. Verified boundary records cannot be deleted, and verification changes are restricted to pending records with field invariants.
- Gap found: rules validate that boundary `points` is a list with 3–10,000 entries and source metadata, but do not validate coordinate ranges, distinct vertices, self-intersection, or City/Area polygon containment. Thus authorized direct Firestore writes can bypass the new Dart polygon checks and still submit geometrically invalid points for review/verification if other rule conditions pass. Activation rules validate verified-boundary linkage and active parent City but not polygon containment.
- Recommendation: add a trusted server-side boundary validation/verification path (or other enforceable policy) and test rule behavior in the Firebase Emulator before production. Do not assume a Cloud Function/backend currently exists; none was confirmed in this audit.
- Step 121: **AUDIT FINDING RECORDED**. Production safety remains **PENDING**; no deployed rules changed, no production data imported/activated, PR remains unmerged.


### Step 122 — Firebase Rules CI/deployment path audited (2026-10-17)
- Reviewed `dojoplatform2026/DOJO-WALK-Firebase/.github/workflows/test-firestore-rules.yml`: pull requests run Firestore Emulator tests when rules/config/package/test files change; tests use `npx firebase emulators:exec --only firestore --project demo-dojo-rules-tests "npm test"`.
- Reviewed `.github/workflows/deploy-firestore-rules.yml`: deployment runs on pushes to `main` when `firestore.rules`, `firebase.json`, `.firebaserc`, or the deploy workflow changes, and also supports manual dispatch. It deploys rules to project `dojo-platform-b68a3` using the `FIREBASE_SERVICE_ACCOUNT` secret. No deployment was triggered by this audit.
- Existing `test/firestore.rules.test.mjs` covers role authorization, matching verified-boundary references, active parent city, and verified boundary immutability. It does not currently test coordinate ranges, polygon self-intersection, or City/Area containment; those are the missing regression cases.
- Important limitation: Firestore Rules cannot perform a general-purpose polygon topology validation reliably. Do not try to encode a full geometry engine in Rules. A trusted backend verification design and emulator tests are needed before production.
- Step 122: CI/deploy pathway and test gaps documented. No Firebase Rules or production resources changed. PR #7 remains unmerged.


### Step 123 — trusted boundary verification architecture (2026-10-17)
- Created a design-only specification in the Firebase repository on branch `step-123-boundary-verification-design`: `docs/TRUSTED_BOUNDARY_VERIFICATION_DESIGN.md`.
- Proposed trust model: a server-side callable function validates pending geometry and active `super_admin` authorization, rechecks state transactionally, and is the only client-facing route that can mark a boundary verified.
- Added explicit test cases for authorization, malformed/self-intersecting polygons, Area containment (including tiny outside gaps and concave parent polygons), concurrent changes, and Firestore Rules denial of direct verification writes.
- Important sequencing constraint: the Admin UI currently needs a coordinated migration to call the trusted function before Firestore Rules direct-verification writes are blocked. Do not tighten the rule alone because that could break the current review flow.
- This step is **DESIGN ONLY**. No Cloud Function was implemented, no executable tests were run for the design, no rules or production resources changed, and no deployment occurred.
- Review branch commit: `661c150cb3133d4ec9550f96b3fcaa4d0d92852c`.
- Next: implement the function and tests on the Firebase feature branch, then coordinate the Admin client change and emulator rules tests. Keep all changes unmerged and undeployed until reviewed and explicitly approved.

### Step 124 — existing trusted-backend PR discovery (2026-10-17)
- Before continuing the new backend work, searched the Firebase repository's open Draft PRs and found existing PR #1: `https://github.com/dojoplatform2026/DOJO-WALK-Firebase/pull/1`.
- PR #1 already contains a shared TypeScript Functions workspace, `activateServiceLocation` callable, Turf-based polygon/Area-in-City checks, transaction rechecks, Firestore Rules hierarchy/activation changes, and geometry plus Emulator tests. Its latest recorded CI runs on commit `050277fcd2f6a8334aafd0fc66d2959164dd5b5e` were reported successful in runs `39034939438` (geometry/callable tests) and `39034939448` (Rules tests).
- Scope distinction: the existing callable is for **activation** and does not by itself prove that boundary review/verification writes are forced through a trusted endpoint. The rules in that draft still need explicit review for direct client verification writes.
- A separate JavaScript scaffold was briefly created on branch `step-124-callable-boundary-verification`; after discovering the existing shared TypeScript implementation, its duplicate Draft PR #3 was closed to avoid conflicting `firebase.json` and `functions/` changes. No deployment or production change occurred.
- Step 124 status: **PAUSED FOR INTEGRATION REVIEW — do not merge the duplicate scaffold**. Next action is to inspect the existing PR #1's callable, rules, and Admin integration end-to-end, then extend that shared implementation only if a real verification-path gap remains.
- Existing trusted-backend PR #1 remains open, draft, unmerged, and undeployed. Production activation/import remains unauthorized.

### Step 124 — trusted review callable wired into Admin draft (2026-10-17)
- Extended the existing Firebase backend Draft PR #1 instead of merging a duplicate Functions workspace.
- Added `reviewServiceLocationBoundary` in `functions/src/index.ts`: requires active `super_admin`, reviews only pending City/Area boundaries, validates polygon geometry, checks full Area-within-active-City containment, rechecks state in a Firestore transaction, and writes server-generated reviewer/time metadata plus a review audit record.
- Added `functions/test/review_service_location_boundary.integration.test.cjs` for unauthenticated/non-admin denial, successful City/Area review, and rejection of an Area extending outside the City.
- Changed Firebase Rules in the draft branch so client updates can edit eligible drafts only; direct `verified`/`rejected` transitions are no longer allowed. Added an Emulator regression test for both forbidden transitions. Trusted Admin SDK callable writes bypass client Rules as intended.
- Updated Admin `ServiceLocationBoundaryService.markVerified` and `rejectBoundary` to call `reviewServiceLocationBoundary` in `asia-south1`; added `cloud_functions: ^6.0.3` to `pubspec.yaml`.
- Firebase backend PR: [Draft PR #1](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/pull/1). Admin draft PR remains [#7](https://github.com/dojoplatform2026/DOJO-WALK-Admin/pull/7).
- Verification: Admin geometry workflow passed on the updated branch (run [39039285590](https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39039285590)); Admin no-deploy Web release build passed (run [39039289020](https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39039289020)). Firebase callable/geometry and Rules Emulator workflows for latest backend changes are still running as of this status entry; final result must be checked before calling Step 124 PASS.
- Earlier Firebase callable test run exposed a fixture error (the test attempted to verify a boundary already seeded as verified); the fixture was corrected by separating the pending review boundary from the verified parent City boundary. Do not count the failed run as a pass.
- Duplicate JavaScript scaffold PR #3 was closed as superseded. No PR was merged and no production deployment, real location activation, or import occurred.

### Step 124 — trusted boundary review callable CI verified (2026-10-17)
- Firebase callable/geometry integration workflow: **PASS**, run [39039578817](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39039578817), head commit `f05bdcd227b1460cf8ca380757c5f30c4d8a78ed`. The job completed successfully, including build and Firestore Emulator integration tests.
- Firebase Firestore Rules Emulator workflow: **PASS**, run [39039578809](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39039578809), same head commit. Direct client attempts to verify/reject pending boundaries are covered by the updated regression tests.
- Admin geometry workflow: **PASS**, run [39039466173](https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39039466173).
- Admin no-deploy Web release build: **PASS**, run [39039466071](https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39039466071). No deployment step was run.
- Step 124 targeted CI: **PASS** for the checked draft commits. This does not mean the PRs are merged or the callable/rules are deployed; both PRs remain draft/unmerged and production activation/import remains unauthorized.
- Next: review the final combined diffs and compatibility/deployment ordering across Admin and Firebase before requesting approval to merge. Deploy only after explicit user approval and a separate deployment plan.


### Step 125 — combined PR review and deployment-order audit (2026-10-17)
- Rechecked both draft PRs and latest CI conclusions. Firebase PR #1 remains open/draft/unmerged at `f05bdcd227b1460cf8ca380757c5f30c4d8a78ed`; Admin PR #7 remains open/draft/unmerged at `aecc92fd29b679a3b4dda48666cb266d90fcc8e5`.
- Confirmed the Firebase callable/geometry Emulator workflow passed: [39039578817](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39039578817). Firestore Rules Emulator workflow passed: [39039578809](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39039578809).
- Confirmed Admin geometry workflow passed: [39039466173](https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39039466173). Admin no-deploy Web release build passed: [39039466071](https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39039466071).
- Updated both PR descriptions to reflect actual test results and the cross-repository dependency.
- **Deployment blocker found:** `.github/workflows/deploy-firestore-rules.yml` runs `firebase deploy --only firestore:rules` only. It does not deploy the new Cloud Functions. Deploying Rules that block direct client verification before `reviewServiceLocationBoundary` is deployed and callable could break the Admin review flow.
- Required rollout order: review/approve code; deploy Functions and verify callable health first; deploy the Rules change only after callable availability is confirmed; then release the Admin client. Prepare a rollback plan and verify deployed versions before activating any real locations.
- Step 125 status: **REVIEW FINDING RECORDED — rollout not ready**. No PR merged, no workflow dispatched, no Functions/Rules deployed, and no production locations activated/imported.


### Step 126 — manual deployment guardrails drafted (2026-10-17)
- Defined the intended release sequence: review both PRs together; deploy only `reviewServiceLocationBoundary`; verify the callable in `asia-south1` with non-production requests; deploy Firestore Rules only after callable health is confirmed; then release the Admin client.
- Rollback guardrail: if the callable deploy/health check fails, do not deploy the Rules change. If Rules are already deployed and callable health fails, use a separately reviewed Rules rollback rather than bypassing security with client writes.
- Production GitHub Environment approval must be configured in repository settings; merely referencing an environment does not enforce reviewer approval.
- **Automation status:** attempted to add a manual-only function deployment workflow and a separate Firebase runbook, but the repository write action was blocked by the tool safety check. No workflow/runbook file was created by that attempt. Therefore deployment automation is **NOT IMPLEMENTED**; the safe sequence is documented here only.
- No workflow was dispatched, no PR merged, no function/rules deployed, and no real location activated or imported.
- Next: implement and review a narrowly scoped manual workflow in GitHub, then test its YAML and build/test gates without dispatching it or deploying production resources.


### Step 127 — guarded manual Function deployment workflow (2026-10-17)
- Added/updated `.github/workflows/deploy-trusted-boundary-function.yml` on Firebase feature branch `feature/trusted-location-activation`.
- Workflow is manual-only (`workflow_dispatch`), requires the exact confirmation `DEPLOY_REVIEW_FUNCTION` and target project `dojo-platform-b68a3`, and is gated to run only when dispatched from `main`. It references the `production` GitHub Environment, serializes deployments, runs the Functions build/tests under the Firestore Emulator, and deploys only `functions:reviewServiceLocationBoundary`; it contains no Rules deployment or location activation/import step.
- Workflow update commit: `29d7ebfaee6d811bbc32be78a0510620073b2dfe`. File: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/blob/feature/trusted-location-activation/.github/workflows/deploy-trusted-boundary-function.yml
- This is a source-level review only. The workflow was **not dispatched** and no YAML lint or GitHub Actions execution was performed. It still needs CI validation. Verify the Functions lockfile/dependency install and emulator command in CI before approving any production use.
- Deployment guardrail remains: configure required reviewers on GitHub Environment `production`; confirm the callable is healthy in `asia-south1` before deploying Rules. The workflow's existence does not mean the callable is deployed.
- No PR merged, no workflow dispatched, no Functions/Rules deployed, and no production locations activated/imported.
- Step 127 status: **WORKFLOW DRAFTED / EXECUTION NOT VERIFIED**. Next: validate workflow YAML and its test command without dispatching the production deployment workflow; keep PRs draft and unmerged.


### Step 128 — workflow validation gate added (2026-10-17)
- Updated Firebase `.github/workflows/test-firestore-rules.yml` to trigger for any workflow-file changes in pull requests and added a dedicated `reviewdog/action-actionlint@v1` job to lint GitHub Actions workflow definitions.
- The existing Firestore Emulator Rules test job remains present; no deployment command was added to this test workflow.
- Commit: `8893a1d72b2447314916c606f0815ac7f06e7ca4`.
- Combined with Step 127's manual-only Function deployment workflow, this should cause workflow lint and Rules Emulator tests to run on the PR when the relevant changes are proposed. Actual run status has **not yet been checked**, so YAML validation and Emulator regression status remain **PENDING**.
- The deploy workflow itself was not dispatched. No Function or Rules deployed, no PR merged, and no production location activated/imported.
- Follow-up: inspect the CI run and correct any workflow lint/test failures. Also verify GitHub Environment `production` has required reviewers configured before any future deployment approval.


### Step 128 — CI finding and actionlint fix (2026-10-17)
- Workflow validation run [39040494568](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39040494568) exposed a configuration issue: `reviewdog/action-actionlint@v1` no longer accepts `fail_on_error`; it also reported existing Node 20 deprecation warnings from older `@v4` actions.
- Changed the actionlint input to the current `fail_level: error` in Firebase commit `b93f3f4848c0c467c07741298054739cf5a83a6c`. This should allow non-fatal deprecation warnings while still failing on actual actionlint errors; **the fix has not yet been validated by a new CI run**.
- In the same run, Firestore Rules Emulator tests completed successfully, and the trusted-location geometry/callable integration workflow [39040494595](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39040494595) completed successfully. These results do not validate the updated actionlint input.
- Current status: Rules Emulator **PASS for run 39040494568**; callable/geometry **PASS for run 39040494595**; workflow lint **FIX COMMITTED / RE-RUN NOT VERIFIED**.
- No production deployment workflow was dispatched. No PR merged, no Functions/Rules deployed, and no production location activated/imported.

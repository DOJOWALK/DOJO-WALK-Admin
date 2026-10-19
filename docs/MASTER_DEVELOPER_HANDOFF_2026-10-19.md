# DOJO WALK — Master Developer Handoff
**Snapshot date:** 2026-10-19 (UTC)  
**Purpose:** One source of truth for continuing work across chats/developers without duplicated tasks.  
**Priority set by product owner:** Finish Admin/service-location work first; merge only after audit and approval. Partner and Customer app work comes after Admin is completed and merged.

## 1. Non-negotiable operating rules
1. Do not merge any PR or deploy Firebase/production without explicit owner approval.
2. Do not import/migrate production location data until the complete data audit, schema/API review, boundary validation, and rollback plan are signed off.
3. Do not start Partner or Customer implementation while Admin remains the priority.
4. Do not delete branches just to make the branch list shorter. Some branches contain unique commits; first compare, review overlapping files, selectively integrate, run tests, then archive only after the owner approves.
5. Each repository has its own Git branches. There cannot be one literal Git branch shared across five repositories. Use one canonical active working branch per repository, and a cross-repository master report to coordinate them.
6. Never report a test as passed unless its GitHub Actions run shows success. Record the exact SHA/run.

## 2. Canonical workstream for this phase
- **Admin canonical active branch:** `step-119-boundary-geometry`
- **Admin draft PR:** #7, base `main`; keep open and unmerged pending final audit/owner approval.
- **Firebase location backend branch:** `fix/location-index-import-rules`
- **Firebase draft PR:** #6, currently targets `feature/trusted-location-activation`, not `main`. This is an integration dependency that must be reviewed before merge.
- Do not create additional active Admin branches. The other Admin branches below are inputs to review, not independent new workstreams.
- The Firebase branch is a separate repository and cannot be folded into an Admin branch; coordinate contracts and release order.

## 3. Latest verified CI snapshot
### Admin — `step-119-boundary-geometry`
- Geometry tests: run **39245999614**, SHA `8efc042`, **success** (updated 2026-10-19 11:38:29Z).
- Admin web build/no-deploy check: run **39245999526**, SHA `8efc042`, **success** (updated 2026-10-19 11:39:54Z).
- **Important deployment finding:** main-branch workflows named “DOJO WALK Admin Web Deploy” runs **39248443727** (SHA `210db2e`) and **39248408700** (SHA `70f5218`) both completed successfully around 12:00Z, and their `build-and-deploy` jobs explicitly show **Build Flutter Web = success** and **Deploy to Firebase Hosting = success**. Therefore Firebase Hosting deployment steps did run on main. The exact public hosting URL/revision and intended approval status have not been independently checked here. Repository admin must verify deployment history and whether these were expected/authorized. Do not claim “no deployment occurred.”
### Firebase — `fix/location-index-import-rules`
- Rules run **39236531337**, SHA `e2f72b7`, **success** (2026-10-19 10:19:26Z).
- Geometry/callable run **39236530995**, SHA `e2f72b7`, **success** (2026-10-19 10:19:32Z).
- An earlier geometry/callable run **39236455380**, SHA `48b8197`, failed, but later SHA `e2f72b7` checks succeeded. Do not treat the old failure as current branch failure; retain it in history.
- Earlier work in the same branch added read-only district-aware index-pair preflight/classification and tests. The helper is deliberately NOT wired into the production save callable; production data has not been scanned/migrated by this workstream.
### Other apps
- Customer, Partner, and Website CI/runtime/OTP/Firestore compatibility were not verified as part of this Admin-focused audit. Do not assume their open PRs are production-ready.

## 4. Admin repository — all branches seen
Repository: `dojoplatform2026/DOJO-WALK-Admin`; default branch `main` at `210db2e4`.
| Branch | Head (short SHA) | State / action |
|---|---|---|
| `main` | `210db2e4` | Baseline; do not change without approval. |
| `step-119-boundary-geometry` | `8efc042d` | **Canonical active branch** for Admin; PR #7. Latest checked geometry/build both pass. |
| `restore/india-location-reference-data` | `1644667c` | PR #6 open. 394 commits ahead / 14 behind main per compare; 105 files changed. Do not merge wholesale; inspect unique LGD/reference data and overlap with Step 119. |
| `audit/zone-service-area-mapping-2026-10-16` | `83d7bad6` | No open PR returned for this branch. 72 ahead / 20 behind main; 54 files changed. Audit/reference branch; review only for unique useful work. |
| `feature/admin-3d-service-location-ui` | `79ba16c4` | PR #9 open/draft; 3 ahead / 2 behind main; overlaps service-location screen and dashboard. Integrate selectively after review, not a blind merge. |
| `feature/admin-operations-3d-cards` | `5311e636` | PR #10 open/draft; 6 ahead / 2 behind main; overlaps service-location screen/dashboard plus bookings/live/walker widgets. Integrate selectively after review. |

### Admin PR inventory
- **#7** Draft Step 119 service-location boundary geometry validation — head `step-119-boundary-geometry`, base `main`; keep unmerged until full audit.
- **#6** Restore India location reference data — head `restore/india-location-reference-data`, base `main`; official LGD verification and data/boundary audit remain gates.
- **#9** Premium 3D Service Locations UI — head `feature/admin-3d-service-location-ui`, base `main`; draft.
- **#10** Admin Bookings/Live Operations/Walker cards — head `feature/admin-operations-3d-cards`, base `main`; draft.

### Admin product/technical status
- Service-location hierarchy is intended to be Country → State → District → Service City → Service Area → optional Locality.
- Customer booking should use Area and customer-entered address; locality need not be mandatory.
- Areas require verified contiguous map boundaries, not radius approximations, before activation.
- Service Location Setup is the priority. Need finish state/district/city/area import/filter path, source-data provenance, duplicate/parent validation, map-boundary containment, activation/deactivation guards, and compatibility with the Firebase callable contract.
- Existing older Zones model and partner `zones` reads are a known cross-app migration risk. Do not remove old model until compatibility/migration plan is approved.
- LGD/reference files and official-source validation must be audited; tests alone do not prove official source correctness or geographic boundary correctness.

## 5. Firebase repository — all branches seen
Repository: `dojoplatform2026/DOJO-WALK-Firebase`; default `main` at `e31e625f`.
| Branch | Head | PR / action |
|---|---|---|
| `main` | `e31e625f` | Baseline; no production change without approval. |
| `feature/trusted-location-activation` | `80b9df56` | PR #1 open/draft; backend activation work. |
| `fix/location-index-import-rules` | `e2f72b72` | PR #6 open/draft, base is `feature/trusted-location-activation`; latest Rules and Geometry/Callable CI succeeded. Current Firebase active branch. |
| `step-123-boundary-verification-design` | `661c150c` | PR #2 open/draft; review for design decisions not already superseded. |
| `step-124-callable-boundary-verification` | `715889fe` | PR #3 closed; do not reopen/merge without reason. |
| `step-131-partner-onboarding-emulator-tests` | `e91d7370` | PR #4 open/draft; Partner scope, defer until Admin phase done unless required as a blocker. |
| `step-138-partner-submission-negative-tests` | `8d09fca9` | PR #5 open/draft, base `step-131-partner-onboarding-emulator-tests`; Partner scope, defer. |

### Firebase contract/safety facts
- `fix/location-index-import-rules` is 261 commits ahead of `feature/trusted-location-activation` (compare status: ahead, behind 0) and 413 ahead / 3 behind `main`. This is substantial divergence; do not merge the branch directly into main without a deliberate integration review.
- PR #6 targets the trusted-location branch, not main. Review that base and the complete PR stack before merging.
- District-aware preflight is currently read-only and not connected to the production save callable. It classifies legacy/district-aware index pairs; it must not be represented as a completed live migration.
- No production scan or production data migration was verified for this branch in this audit. This is distinct from the Admin Hosting deployments noted above; no Firebase backend/rules deployment is claimed here.
- Verify Firestore Rules behavior against existing Admin direct verify/reject writes before any deployment.
- Keep rollback plan and dry-run/reporting stage ahead of any write migration.

## 6. Customer repository — all branches seen
Repository: `dojoplatform2026/dojo-walk-customer`; default `main` at `c99fcad1`. **Explicitly deferred until Admin is complete and merged.** No Customer branches were merged by this handoff.
Branches:
- `main` (`c99fcad1`)
- `audit/stable-android-signing-otp-2026-10-16` (`d0fdcda5`), PR #1
- `feature/customer-premium-3d-ui` (`5fe9202a`), PR #2
- `feature/customer-dog-booking-cards-3d-ui` (`98983f2d`), PR #3
- `feature/customer-home-3d-service-cards` (`033c921e`), PR #4
- `feature/customer-booking-type-cards-3d-ui` (`06082c02`), PR #5
- `feature/customer-schedule-setup-3d-ui` (`e0371b4d`), PR #6
- `feature/customer-dog-selection-3d-ui` (`b415117a`), PR #7
- `feature/customer-pickup-address-3d-ui` (`29acc401`), PR #8
- `feature/customer-booking-confirmation-3d-ui` (`2cc4daf9`), PR #9
- `feature/customer-my-bookings-3d-ui` (`8274f70c`), PR #10
- `feature/customer-profile-3d-ui` (`89ca496d`), PR #11
- `feature/customer-help-support-3d-ui` (`66637090`), PR #12
- `feature/customer-settings-3d-ui` (`e61f5108`), PR #13
- `feature/customer-saved-addresses-3d-ui` (`9f318347`), PR #14
- `feature/customer-dog-form-3d-ui` (`9bec91ad`), PR #15
- `feature/customer-coupons-3d-ui` (`c0d86137`), PR #16
- `feature/customer-account-details-3d-ui` (`6a4bc359`), PR #17
- `feature/customer-privacy-terms-3d-ui` (`f64747fe`), PR #18
- `feature/customer-change-mobile-3d-ui` (`24a4dcb2`), PR #19
- `feature/customer-auth-3d-ui` (`01db58fd`), PR #20
- `feature/customer-name-setup-3d-ui` (`a4c2ba13`), PR #21
- `feature/customer-splash-3d-ui` (`1e647aab`), PR #22
- `feature/customer-home-primary-button-3d-ui` (`2cc70d57`), PR #23
- `feature/customer-home-brand-header-3d-ui` (`78165f51`), PR #24
- `feature/customer-advertising-offers-3d-ui` (`126976f5`), PR #25
- `feature/customer-home-smart-market-ui` (`40ef18d2`), PR #26
- `feature/customer-live-status-only-ui` (`79e9b2ea`), PR #27
- `feature/customer-live-walk-status-screen` (`759e4bab`), PR #28

Customer PRs #4–#28 include a dependency chain where each feature branch bases on another feature branch. **Do not merge all PRs into main independently.** First reconstruct dependency order, compare each branch with its stated base, run Flutter tests/build on the integrated candidate, and preserve auth/OTP/reCAPTCHA/Firestore behaviors. Confirmed app requirements from product owner: login required at start, India +91 phone auth, profile in `users/{uid}`, booking hierarchy/screens and orange/cream branding. Actual full runtime/API compatibility remains unverified here.

## 7. Partner repository — all branches seen
Repository: `dojoplatform2026/dojo-partner`; default `main` at `cf7760bd`. **Explicitly deferred until Admin is complete and merged.**
- `main` (`cf7760bd`)
- `audit/stable-android-signing-otp-2026-10-16` (`4ae87ff8`), PR #1
- `ci/partner-pr-validation` (`43754938`), PR #2
- `feature/partner-premium-3d-ui` (`9e6fb2d3`), PR #3
- `feature/partner-walk-cards-3d-ui` (`1b569b75`), PR #4
All four PRs are open/draft and target main. Do not start feature integration until Admin is done. Known contract risk: current Partner code historically reads legacy `zones`; location service migration must preserve or explicitly migrate its work-zone contract. Product owner chose document-photo onboarding rather than OTP verification for Partner; verify implementation later rather than assuming it is complete.

## 8. Website repository — all branches seen
Repository: `dojoplatform2026/DOJO-WALK-Website-`; default `main` at `e4b11ca7`.
- `main` (`e4b11ca7`)
- `feature/full-company-flow` (`22141e09`), PR #1 closed
- `feature/website-home-screen-market-polish` (`08dd6ae2`), PR #2 open/draft
- `feature/website-customer-login-structure` (`4f7f6c36`), PR #3 open/draft, base is PR #2 branch
- `feature/website-customer-profile-firestore` (`c348e66a`), PR #4 open/draft, base is PR #3 branch
- `feature/website-customer-auth-profile-integration` (`6682af62`), PR #5 open/draft, base is PR #4 branch
- `docs/firebase-readiness-audit-main` (`c7121ee4`), PR #6 closed
PR #5 is 17 commits ahead of PR #4 branch with no behind commits, but that is not proof the integration is safe. Prior audit said PR #3 and #4 had different ahead/behind counts; re-compare live before integrating. Preserve OTP restart, phone-lock, reCAPTCHA cleanup, Profile/Firestore and security behavior. No PR merge, deploy, Firebase Rules deploy, or runtime OTP test is claimed by this report.

## 9. Consolidation strategy (do not skip)
**Do not attempt a blind mass merge.** The branch inventory contains stacked feature PRs, large divergent audit branches, overlapping Admin files, and separate repository contracts. A safe consolidation is a controlled integration sequence:
1. Freeze new feature branches for the Admin phase; all new Admin work goes on `step-119-boundary-geometry`.
2. Audit PR #7's changed files and latest CI; review the 3 commits behind main before deciding how to sync.
3. Compare PR #6/branch `restore/india-location-reference-data` against Step 119; take only verified data/source changes and required implementation commits. Resolve overlapping `LOCATION_MASTER_STATUS.md`, location screens/services, workflows, and tests deliberately.
4. Review Admin UI PR #9 and #10, which overlap each other and the active Service Location screen/dashboard. Selectively port approved UI commits; rerun geometry + web build checks.
5. Review the older audit branch only for unique required functionality/docs; do not bring 72 commits wholesale without file-level classification.
6. Once Admin candidate is coherent, compare its Firebase callable/rules expectations with Firebase PR #6. Resolve the base chain and direct Admin verification/rejection writes. Keep district-aware index preflight read-only until integrated migration tests and owner approval.
7. Complete LGD source audit, import validation, polygon geometry/containment tests, active-child guards, API/schema compatibility and rollback plan.
8. Produce final Admin release checklist and explicit approval request. Only then may owner authorize PR merge/deploy.
9. After Admin merge is verified, handle Partner and Customer separately, in that order or as owner directs. Their branches are not merged by this report.

## 10. Current blockers / not done
- Admin branches are not consolidated; no PR has been merged by this report.
- The reference data has not completed official LGD source verification and map-boundary review.
- Production location scan and migration have not been run/verified.
- Firebase PR #6 is stacked on `feature/trusted-location-activation`; integration target must be deliberately resolved.
- Admin main workflow shows successful “Deploy” runs; actual hosting revision and whether production was changed must be checked before the team states deployment status.
- GitHub branch protection / required-review / production approval settings were previously not verified (403); an authorized repository admin must check them.
- Customer/Partner/Website runtime, OTP, Firestore and release checks are outside this phase and remain unverified.
- No branches were deleted, no production data was mutated, and no merge was performed during this report creation. However, two Admin main-branch Firebase Hosting deployment jobs did run successfully (run IDs above); investigate/confirm the deployment authorization and live revision.

## 11. Handoff protocol for every future chat/developer
Before coding:
1. Read this file first.
2. Check the branch head and latest commits live; this report is a dated snapshot, not a live dashboard.
3. Check PR base/head and latest CI runs.
4. Search the repository for an existing implementation/report/test before adding a duplicate.
5. Work only on the canonical branch for the active phase unless owner explicitly authorizes another.
6. After each meaningful update, add/update a dated report with changed files, commit SHA, tests/run IDs, result, remaining risks, and next exact step.
7. Never state “complete” just because CI passed; distinguish unit/integration CI from real Firebase, official-data, map-boundary, deployment, and end-to-end verification.

## 12. Immediate next task
Continue Admin-only:
- Inspect PR #7 and its three commits behind main.
- Inspect deployment workflow runs #39248443727 and #39248408700 to establish their actual effect/target.
- Review the exact diffs of Admin PR #6, #9, and #10 against `step-119-boundary-geometry`; prepare a file-level integration plan with conflicts before changing code.
- Do not merge or deploy.

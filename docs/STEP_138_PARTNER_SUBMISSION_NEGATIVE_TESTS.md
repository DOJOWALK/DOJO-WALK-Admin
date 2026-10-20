# Step 138 — Partner Submission Negative Emulator Tests

Date: 2026-10-18  
Status: **Draft PR opened; Firebase Emulator CI is in progress.**

## Changes

Firebase repository: `dojoplatform2026/DOJO-WALK-Firebase`  
Branch: `step-138-partner-submission-negative-tests`  
Commit: `ae535891560a240d34387ed607f0e84453ed5eed`  
Draft PR #5: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/pull/5  
Base: `step-131-partner-onboarding-emulator-tests`

Updated `test/firestore.rules.test.mjs` with three negative/edge tests:
1. Reject target status `approved` in the Partner submission transition.
2. Reject unauthorized extra field `isAdmin: true` in submission.
3. Allow first valid submission, then reject a second submission attempt.

These tests use the existing emulator test harness and do not change `firestore.rules` or application code.

## CI evidence at latest check

Run: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39069361083

- Checkout and Node setup: success.
- Dependency installation: in progress.
- Firestore Emulator tests: pending.
- Workflow YAML validation: in progress.

**No final PASS/FAIL is claimed yet.** Re-check the run before deciding whether these tests pass. If the duplicate/extra-field tests reveal Rules behavior gaps, update Rules only after carefully reviewing the contract and add appropriate coverage.

## Safety and release

- [x] Test-only change on a review branch.
- [x] Draft PR opened.
- [ ] Emulator suite final result verified.
- [ ] Review test assertions and CI result.
- [ ] Production Rules state/release separately reviewed.

No production Rules were changed, no merge/deployment occurred, and no production data was touched.


## Follow-up check and fix

The first CI run failed 1 of 55 tests (54 passed). The failure was meaningful: a second submission update succeeded because the ordinary owner-update rule still allowed edits when `applicationSubmitted` was already true. The invalid-status and unauthorized-extra-field tests both passed.

A targeted fix was committed on the same Firebase review branch:
- Rules commit: `998ae64552d795ced708832f06f5925048bdc3c9`
- Added a guard so ordinary owner draft updates require `resource.data.applicationSubmitted == false`. The dedicated first-submission transition remains separately guarded.
- No production deployment or merge occurred.
- CI for the fix must be rechecked; do not mark this resolved until the rerun confirms the emulator suite passes.


## Final CI verification — PASS

Rechecked on 2026-10-18:
- Firestore Rules Emulator workflow run `39069565571`: **success**. The `Run Firestore Emulator tests` step completed successfully after the ordinary owner-update rule was guarded against post-submission edits.
- Trusted Location Geometry and Callable workflow run `39069565556`: **success**; build, geometry and callable integration tests passed.
- Workflow YAML validation: **success**.

The Step 138 test/fix is now CI-verified on the Firebase review branch. This does not mean production Rules are deployed or verified. Draft PR #5 remains unmerged; no production deployment or data changes occurred.

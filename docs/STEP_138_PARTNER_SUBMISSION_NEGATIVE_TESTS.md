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

# Step 139 — Partner Post-Submission Profile/KYC Audit

Date: 2026-10-18

## Scope
Reviewed the Partner walker Rules on Firebase branch `step-138-partner-submission-negative-tests` and the submission emulator tests. This is a review-branch audit only; production Rules were not inspected or changed.

## Findings
- The ordinary owner-update rule now requires `resource.data.applicationSubmitted == false`.
- The explicit submission transition allows the initial `in_progress` → `under_review` submission while requiring the submitted flag to change false → true, keeping the walker inactive/unapproved and verification pending, and restricting changed keys to the submission transition fields.
- The duplicate submission test passed in the prior CI run (55/55 tests); after adding the KYC/profile negative test, the latest Rules Emulator run passed 56/56 tests.
- The existing tests did not explicitly try to modify KYC documents or fullName after submission. Added a focused test that first submits an application and then asserts both a `documents` edit and a `fullName` edit are denied.

## Latest change
- Test commit: `e88f5bdc5433d724470a2e4fa3adc458b2f28a4b`
- Draft PR #5: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/pull/5
- Rules Emulator CI run #148: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39069915280 — PASS (56 tests, 56 passed, 0 failed).
- Trusted Location Geometry/Callable run #137: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39069915211 — PASS.

## Decision / limits
Current review-branch policy is: once submitted for review, a Partner cannot edit profile or KYC fields through the ordinary owner update route. Any correction workflow should be designed as an explicit reviewed transition (for example, an admin-returned-to-correction state) rather than silently reopening arbitrary owner edits.

## Release status
No merge, production Rules deployment, or production data change. CI verification for the new KYC/profile test is complete and passing on the review branch.


## Follow-up Step 140 — Client payload cross-check
Reviewed the Partner app's `lib/features/onboarding/screens/review_submit_screen.dart` submission payload at the inspected commit. It changes exactly the five fields permitted by the explicit Rules transition: `status`, `applicationSubmitted`, `submittedAt`, `updatedAt`, and `onboardingStep`. The UI also re-reads the walker document and validates current status and required KYC/address/work-zone data before submitting.

Added a further Rules emulator test covering attempts to change nested `kyc` and `currentAddress` after submission:
- Test commit: `2676e313476254279d041bf7db0a3ea9844b429f`
- Rules Emulator CI run #150: queued at report update time: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39070246822
- Geometry/Callable run #139: in progress at report update time: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39070246869

The original Step 139 tests have passed (56/56); this follow-up's final CI is still pending.

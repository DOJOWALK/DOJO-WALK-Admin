# Step 139 — Partner Post-Submission Profile/KYC Audit

Date: 2026-10-18

## Scope
Reviewed the Partner walker Rules on Firebase branch `step-138-partner-submission-negative-tests` and the submission emulator tests. This is a review-branch audit only; production Rules were not inspected or changed.

## Findings
- The ordinary owner-update rule now requires `resource.data.applicationSubmitted == false`.
- The explicit submission transition allows the initial `in_progress` → `under_review` submission while requiring the submitted flag to change false → true, keeping the walker inactive/unapproved and verification pending, and restricting changed keys to the submission transition fields.
- The duplicate submission test passed in the previous CI run (55/55 tests).
- The existing tests did not explicitly try to modify KYC documents or fullName after submission. Added a focused test that first submits an application and then asserts both a `documents` edit and a `fullName` edit are denied.

## Latest change
- Test commit: `e88f5bdc5433d724470a2e4fa3adc458b2f28a4b`
- Draft PR #5: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/pull/5
- Rules Emulator CI run #148: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39069915280 — in progress at report creation.
- Trusted Location Geometry/Callable run #137: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39069915211 — in progress at report creation.

## Decision / limits
Current review-branch policy is: once submitted for review, a Partner cannot edit profile or KYC fields through the ordinary owner update route. Any correction workflow should be designed as an explicit reviewed transition (for example, an admin-returned-to-correction state) rather than silently reopening arbitrary owner edits.

## Release status
No merge, production Rules deployment, or production data change. Final CI verification for the newly added KYC/profile test remains pending.

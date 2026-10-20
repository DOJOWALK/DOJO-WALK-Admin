# Step 140 — Final CI Verification and Storage Rules Gap

Date: 2026-10-18

## Final CI verification
Firebase branch: `step-138-partner-submission-negative-tests`
Latest commit: `2676e313476254279d041bf7db0a3ea9844b429f`

- Firestore Rules Emulator run #150: PASS — 57 tests, 57 passed, 0 failed.
  https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39070246822
- Trusted Location Geometry and Callable run #139: PASS.
  https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39070246869
- Workflow YAML validation: PASS.
- The new nested KYC/address test passed: the owner cannot change `kyc` or `currentAddress` after submitting.
- The prior profile/KYC test passed: the owner cannot change `documents` or `fullName` after submission.

## Partner submission payload cross-check
Reviewed Partner `lib/features/onboarding/screens/review_submit_screen.dart` at inspected commit `cf7760bd393c3c0bbac8bfb7ed5689a203815f7d`. Submission changes only the five fields allowed by the dedicated Firestore transition: `status`, `applicationSubmitted`, `submittedAt`, `updatedAt`, `onboardingStep`. The screen re-reads and validates the profile, status, verification flags, KYC paths, address and work-zone before submitting.

## Next critical finding: Firebase Storage Rules are not configured in this repo
Inspected Firebase repo `firebase.json` on the review branch. It configures Functions and Firestore only:
```json
{
  "functions": {"source": "functions", "runtime": "nodejs22"},
  "firestore": {"rules": "firestore.rules"}
}
```
There is no `storage.rules` file in the repository root and no `storage.rules` entry in `firebase.json` on this branch.

Partner client code uploads identity documents to `walker_kyc/{uid}/...` and selfies to `walker_selfies/{uid}/...`, then stores their private Storage paths in the Firestore walker document. Until the intended deployed Storage Rules are located and audited, we cannot claim uploads are correctly owner-scoped, restricted to the pre-submission phase, size/type validated, or privately readable by the intended reviewers.

## Next action (Step 141)
Locate the actual deployed Storage Rules / Firebase project configuration first. If no controlled rules exist, draft owner-scoped KYC upload/read rules plus Storage Emulator tests on a review branch. Do not deploy rules or expose existing KYC files as part of this audit.

## Release status
PR #5 remains draft/open/unmerged. No merge, deployment, or production data changes. Production Firestore and Storage rules have not been verified.

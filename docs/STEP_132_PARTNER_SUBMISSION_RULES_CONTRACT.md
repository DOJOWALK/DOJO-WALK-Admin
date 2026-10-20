# Step 132 — Partner Submission UI vs Firestore Rules Contract

Date: 2026-10-18  
Status: **Source contract comparison complete; matching submission payload confirmed.**

## Files and revisions inspected

Partner repository `dojoplatform2026/dojo-partner`, branch `main`:
- `lib/features/onboarding/screens/review_submit_screen.dart`, blob `17aaedef0c04ee7956bb6260a05cc7f1d7f3380d`
- `lib/features/onboarding/screens/personal_details_screen.dart`, blob `ae8a929e9ec724e9536acd2c8ffcc9b7c06c0f82`
- `lib/features/onboarding/screens/work_location_screen.dart`, blob `9c5d5e12a3fd29785d2001fb20937a7bbb374df5`

Firebase repository `dojoplatform2026/DOJO-WALK-Firebase`, review branch `step-131-partner-onboarding-emulator-tests`:
- `firestore.rules`, blob `2aa222f1bf3219fdc1d2ccab0fe5a682eaa4ab69`
- `test/firestore.rules.test.mjs`, blob `658615b4ced2e8cdf7f8a7c4af678f9f5efb5864`

## Submission payload comparison

Partner `ReviewSubmitScreen._submitApplication()` re-reads the walker document, checks ownership, prevents duplicate submission, requires `status == in_progress`, confirms `isActive == false`, `isApproved == false`, and `verificationStatus == pending`, and validates address, zones and required KYC storage paths before updating only:

- `status: under_review`
- `applicationSubmitted: true`
- `submittedAt: serverTimestamp()`
- `updatedAt: serverTimestamp()`
- `onboardingStep: submitted`

The dedicated Firebase Rules transition allows this exact set of changed keys and checks the required state and server timestamps. The review-branch Emulator test uses the same transition fields. **Source-level field and state-transition contract matches.**

## Separate create/draft flow observations

- Initial Personal Details save creates the full draft, including work-location fields. The review-branch Rules create allowlist includes those fields.
- Work Location can update legacy zone fields; the review-branch ordinary owner-update allowlist includes those fields.
- Ordinary updates must preserve `applicationSubmitted`; only the dedicated transition can set it to true.
- The source comparison does not prove runtime app behavior on a device, deployed Rules revision, or production configuration.

## Validation evidence

The relevant GitHub Actions runs for Firebase review head `e91d7370c28a1eaea77f3906af19b98e294e1e3f` completed successfully:
- Firestore Rules Emulator Tests: run `39067829446` — success.
- Trusted Location Geometry and Callable Tests: run `39067829625` — success.

The CI validates the checked-in review branch; it does not prove production deployment.

## Next

- [ ] Run Partner Flutter analyze/tests/build against the exact inspected source head, if the repository CI workflow can be inspected and results tied to that commit.
- [ ] Review Firebase draft PR #4 and Partner app source together.
- [ ] Confirm deployed Rules revision through authorized release process.
- [ ] Do not merge/deploy until the cross-repository release gate is approved.

No Partner source was modified in this step. No production Rules, Firestore data, import, activation, deployment or merge occurred.

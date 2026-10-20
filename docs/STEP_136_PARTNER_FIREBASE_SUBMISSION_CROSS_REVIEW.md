# Step 136 — Partner Submission / Firebase Rules Cross-Review

Date: 2026-10-18  
Status: **Cross-review complete; one test-coverage gap identified.**

## Exact sources inspected

Partner repository, branch `main`:
- `lib/features/onboarding/screens/review_submit_screen.dart`, blob `17aaedef0c04ee7956bb6260a05cc7f1d7f3380d`

Firebase repository, branch `step-131-partner-onboarding-emulator-tests`:
- `firestore.rules`, blob `2aa222f1bf3219fdc1d2ccab0fe5a682eaa4ab69`
- `test/firestore.rules.test.mjs`, blob `658615b4ced2e8cdf7f8a7c4af678f9f5efb5864`

## Contract comparison

Partner submission updates exactly these five fields:
- `status: under_review`
- `applicationSubmitted: true`
- `submittedAt: serverTimestamp()`
- `updatedAt: serverTimestamp()`
- `onboardingStep: submitted`

The dedicated Firestore Rules transition permits only those keys to change and requires the application to be not-yet-submitted, move to `under_review`, remain inactive/unapproved with `verificationStatus: pending`, and set submittedAt/updatedAt to request time.

The emulator test suite has six targeted Partner onboarding tests, including owner-only creation, draft location edits, protection of status/approval fields, blocking ordinary submission, and allowing the explicit review transition. Firebase review-branch CI was previously observed passing in run `39067829446`; geometry/callable run `39067829625` also passed. These results apply to the reviewed branch, not deployed production rules.

## Test coverage gap

The Partner UI sets `onboardingStep: submitted`, and Rules permit this key in the transition, but the successful transition emulator test does not include `onboardingStep`. It therefore does not directly prove that the complete five-field payload emitted by the UI succeeds together. The Rules also do not require the resulting onboardingStep value to equal `submitted`.

Recommended follow-up: extend the emulator test to send the exact five-field UI payload and assert the resulting onboardingStep value; optionally require `request.resource.data.onboardingStep == 'submitted'` in the dedicated transition. Re-run the Firebase Rules Emulator CI before treating the full payload as proven.

## Release gates

- [x] Compare current Partner submit payload with review-branch Rules transition.
- [x] Verify emulator tests include a dedicated submission transition case.
- [ ] Add exact-payload assertion for `onboardingStep`.
- [ ] Re-run Firebase Rules Emulator CI after any Rules/test change.
- [ ] Confirm production Rules deployment separately.
- [ ] Keep Firebase PR #4 and Partner PR #2 unmerged pending review and release approval.

No code, Rules, merge, deployment, or production data was changed in this cross-review.

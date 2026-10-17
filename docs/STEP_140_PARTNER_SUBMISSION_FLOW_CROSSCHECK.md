# Step 140 — Partner Submission Flow Cross-Check

Date: 2026-10-18

## Scope
Compared the Partner app onboarding screens on branch `ci/partner-pr-validation` with the Firebase review-branch Rules and emulator tests. No production systems or data were changed.

## App flow findings
- `work_location_screen.dart` checks the existing walker document and blocks the onboarding route if `applicationSubmitted == true`; for existing drafts it requires `status == in_progress` before updating location fields.
- `personal_details_screen.dart` checks submission state and requires an existing draft to remain `in_progress`; its merge write updates permitted profile/location fields and does not reset the submitted flag on existing documents. Firestore Rules remain the authoritative guard against races after the client-side read.
- `review_submit_screen.dart` re-reads the latest walker document before submission, validates the owner UID, application status, inactive/unapproved/pending verification state, required KYC storage paths, address, and zone selection. It then changes only `status`, `applicationSubmitted`, `submittedAt`, `updatedAt`, and `onboardingStep` for submission.
- KYC images are represented under `kyc.selfie.storagePath` and `kyc.documents.{aadhaar_front,aadhaar_back,pan_card}.storagePath` in the app. The post-submission Rules test was refined to attempt editing this real nested `kyc` shape, as well as profile fields.

## Test update
- Commit: `23ecbec506a9f52f05071d0e054c4a62d035ec9e`
- Firebase PR #5 remains draft: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/pull/5
- Rules Emulator run #149: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39070207493 — in progress at report creation.
- Geometry/Callable run #138: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39070207505 — in progress at report creation.
- Step 139 prior test run passed 56/56, but the latest nested-KYC refinement still requires its own final CI result.

## Outcome / limits
No definite client-side route to edit a submitted application was found in the inspected onboarding screens. Client-side checks are not security boundaries; Firestore Rules block ordinary owner edits once submitted. A deliberate correction workflow after admin review is still not implemented/approved.

## Release status
No merge or deployment. Production Rules and deployed app versions have not been verified.

# Step 137 — Partner Onboarding Payload / Firebase Rules Cross-Check

Date: 2026-10-18  
Status: **Static cross-check completed; core field contract aligns, with test-coverage gaps recorded.**

## Repositories and revisions inspected

Partner `main`:
- `lib/features/onboarding/screens/personal_details_screen.dart`, blob `ae8a929e9ec724e9536acd2c8ffcc9b7c06c0f82`
- `lib/features/onboarding/screens/work_location_screen.dart`, blob `9c5d5e12a3fd29785d2001fb20937a7bbb374df5`
- `lib/features/onboarding/screens/review_submit_screen.dart`, blob `17aaedef0c04ee7956bb6260a05cc7f1d7f3380d`

Firebase review branch `step-131-partner-onboarding-emulator-tests`:
- `firestore.rules`, blob `2aa222f1bf3219fdc1d2ccab0fe5a682eaa4ab69`
- `test/firestore.rules.test.mjs`, blob `658615b4ced2e8cdf7f8a7c4af678f9f5efb5864`

## Contract comparison

### New draft creation

Partner creates `walkers/{uid}` with `userId`, `fullName`, `phone`, `dateOfBirth`, `updatedAt`; optional `email`/`gender`; and on new profile adds `status=in_progress`, `isActive=false`, `isApproved=false`, `verificationStatus=pending`, `applicationSubmitted=false`, `createdAt`, plus location fields `city`, `state`, `area`, `zoneName`, `zoneNames`, `zones`, `travelMode`.

The reviewed Firebase Rules create allowlist contains these fields and enforces owner UID, required profile/status fields, server timestamps, and inactive/unapproved/pending initial state. **No field-name mismatch was found in this create payload.**

### Work-location draft update

Partner updates `city`, `state`, `area`, `zoneName`, `zoneNames`, `zones`, `travelMode`, and `updatedAt` on an existing `in_progress` draft. The reviewed Rules ordinary-update allowlist includes these fields and protects `status`, `isActive`, `isApproved`, `verificationStatus`, and `applicationSubmitted` from owner changes. The emulator tests include a passing case for the listed location fields and rejection cases for owner status/approval escalation.

### Final submission transition

Partner re-reads the document and checks owner UID, `status=in_progress`, `applicationSubmitted != true`, `isActive=false`, `isApproved=false`, and `verificationStatus=pending`. It checks KYC storage paths and required residential-address fields in the UI, then writes only:
- `status=under_review`
- `applicationSubmitted=true`
- `submittedAt=serverTimestamp()`
- `updatedAt=serverTimestamp()`
- `onboardingStep=submitted`

The dedicated Rules transition allows exactly these changed keys and requires both timestamps to equal `request.time`. **The UI update payload matches the reviewed Rules transition.**

## Gaps / cautions

1. Existing emulator tests verify the transition with a minimal draft. They do not prove a complete real UI-created profile (including KYC/address maps) passes through every rule and UI step end to end.
2. The UI's KYC/address checks are client-side validation; Rules transition validates changed keys and state transition, not the truth/completeness of every existing KYC/address field. Trusted server-side review must remain responsible for approval.
3. Partner reads legacy `zones`; this cross-check does not resolve the separate migration gap to `service_cities`/`service_areas`.
4. These findings apply to the Firebase review branch, not deployed production Rules. PR #4 remains unmerged/un-deployed per current project tracking.
5. Static source review is not an emulator rerun. Previously recorded Step 131 Firebase CI runs passed on the review branch, but no new tests were run in this step.

## Decision

- [x] Draft create field names align with reviewed Rules.
- [x] Work-location update fields align with reviewed Rules.
- [x] Final submission update keys/timestamps align with dedicated transition.
- [x] Identify test-coverage and production-state limitations.
- [ ] Add emulator coverage for extra-key rejection and invalid transition states.
- [ ] Keep production deployment/approval blocked until review PR, production Rules status, and location schema migration are resolved.

No source files or Rules were modified in this step. No merge, deployment, activation, or production data operation occurred.

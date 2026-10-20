# Step 208 — Partner Onboarding Source-of-Truth Compatibility Audit

Date: 2026-10-18

## Repositories and reviewed revisions

- Partner app: `dojoplatform2026/dojo-partner`, branch `main`
  - `lib/features/onboarding/screens/personal_details_screen.dart`
  - SHA: `ae8a929e9ec724e9536acd2c8ffcc9b7c06c0f82`
  - `lib/features/onboarding/screens/review_submit_screen.dart`
  - SHA: `17aaedef0c04ee7956bb6260a05cc7f1d7f3380d`
  - bundled `firestore.rules`
  - SHA: `7b02a8bfb4fe80ab04d72f59966e2e09c848ffd0`
- Firebase review branch: `dojoplatform2026/DOJO-WALK-Firebase`, branch `step-138-partner-submission-negative-tests`
  - `firestore.rules`
  - SHA: `99b8a862b54dfb3a387d59219aa1554480cd4328`
  - `test/firestore.rules.test.mjs`
  - SHA: `fba5ed8ebcc74e04474dcca1d7ea6da25c93d460`

## Findings

1. Partner's initial profile write uses `walkers/{uid}` with `status: in_progress`, inactive/unapproved flags, `verificationStatus: pending`, `applicationSubmitted: false`, timestamps, and work-location fields (`city`, `state`, `area`, `zoneName`, `zoneNames`, `zones`, `travelMode`). The Firebase review-branch create rule explicitly permits this draft shape and checks ownership, flags, and server timestamps.
2. The Partner app submits by changing only `status: under_review`, `applicationSubmitted: true`, `submittedAt`, `updatedAt`, and `onboardingStep: submitted`. The Firebase review-branch rules provide a separate one-time submission transition and protect approval flags.
3. The Firebase review-branch test file contains positive and negative coverage for initial draft creation, wrong-owner creation, permitted draft location updates, protected status/approval fields, guarded submission, invalid submission status, extra fields, repeat submission, and post-submission profile/KYC/address edits.
4. The Partner repo's bundled `firestore.rules` is materially stale relative to the app flow: its initial-create rule requires `status == under_review` and its create allowlist does not include the app's draft location/submission fields. Its ordinary update allowlist also does not provide the same explicit submission-transition contract. Therefore, the Partner-bundled rules should not be assumed compatible with the current app onboarding flow.
5. This source comparison does not identify which rules are deployed to the live Firebase project. No production state was inspected or changed.

## Verification evidence

On Firebase review-branch commit `8d09fca9713799e4695cf7b446d575f1de2d9bb6`:
- [Dedicated Firestore Rules Emulator workflow, run #151](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39133139292): PASS.
- [Combined root Rules + Functions workflow, run #140](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39133139279): PASS.

## Next action

Keep the Firebase review branch as the tested candidate for review. Before aligning the Partner repo's bundled rules, inspect its other consumers and release/deployment process, then make a separately reviewed change. Do not deploy or merge automatically.

## Safety

Audit/documentation only. No rules files changed in this step; no merge, production deployment, or production data changes.

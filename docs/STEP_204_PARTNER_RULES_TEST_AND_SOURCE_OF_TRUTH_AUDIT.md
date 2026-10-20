# Step 204 — Partner Registration Rules Test and Source-of-Truth Audit

**Status:** Static audit completed; emulator tests not executed in this step  
**No production changes:** No Rules deployment, app code change, merge, or production data change.

## Repositories and exact sources reviewed

- Partner app rules: `dojoplatform2026/dojo-partner/firestore.rules`, main, blob SHA `7b02a8bfb4fe80ab04d72f59966e2e09c848ffd0`.
- Partner initial create payload: `lib/features/onboarding/screens/personal_details_screen.dart`, main, blob SHA `ae8a929e9ec724e9536acd2c8ffcc9b7c06c0f82`.
- Partner final submit payload: `lib/features/onboarding/screens/review_submit_screen.dart`, main, blob SHA `17aaedef0c04ee7956bb6260a05cc7f1d7f3380d`.
- Firebase rules branch: `dojoplatform2026/DOJO-WALK-Firebase`, branch `step-138-partner-submission-negative-tests`, `firestore.rules` blob SHA `99b8a862b54dfb3a387d59219aa1554480cd4328`.
- Firebase Rules Emulator tests: `test/firestore.rules.test.mjs`, blob SHA `fba5ed8ebcc74e04474dcca1d7ea6da25c93d460`.
- Firebase test scripts: `package.json`, blob SHA `29ef05ba7aa3fd8ee9dd5b29b639f213fb87d966`.

## Finding 1 — Firebase repo already has the intended registration contract and targeted tests

The Firebase rules branch permits the Partner's initial `in_progress` draft, includes the location/onboarding fields used by the client, and has a separate explicit owner submission transition:
- existing `applicationSubmitted == false`
- target `status == 'under_review'`
- target `applicationSubmitted == true`
- `isActive == false`, `isApproved == false`, `verificationStatus == 'pending'`
- only the submission fields may change
- server timestamps are checked against `request.time`.

The Rules Emulator test file includes tests for:
- valid initial draft creation;
- owner UID mismatch rejection;
- draft location updates;
- valid submission transition;
- invalid target status rejection;
- extra submission field rejection;
- duplicate submission rejection;
- post-submission profile/KYC/address edit rejection.

The package script is `npm test` (Node test runner against `test/*.test.mjs`).

## Finding 2 — Partner repo's bundled rules file is stale/incompatible

The Partner repo's `firestore.rules` create allowlist excludes fields its own create payload sends and requires `status == 'under_review'` while the app creates `in_progress`. Its owner-update allowlist also does not contain the fields used by final submission and it lacks the separate explicit submission transition found in the Firebase repo branch.

This confirms a **source mismatch between the two repository snapshots**. It does not establish which rules file is deployed to the live Firebase project. Do not assume the Partner repo's bundled rules are deployed, and do not deploy either file from this finding alone.

## Verification status

- Source comparison: **completed**.
- Existing test coverage reviewed: **yes**.
- Rules Emulator tests executed during this step: **no**.
- Live deployed rules revision verified: **no**.
- App integration reproduction: **no**.

## Recommended next safe action

1. Run the existing Firebase Rules Emulator test suite on branch `step-138-partner-submission-negative-tests` and record the actual result.
2. Identify the authoritative deployment pipeline and deployed rules revision.
3. Keep one canonical Rules source. If the Partner repo intentionally bundles a Rules file, update it only after confirming the canonical source and comparing the complete files; avoid copying an entire Rules file without reviewing unrelated collection permissions.
4. Do not weaken approval controls. A partner must never self-set `isApproved`, `isActive`, or `verificationStatus`.

Related: [Step 203 — Partner Registration Rules Compatibility Check](STEP_203_PARTNER_REGISTRATION_RULES_COMPATIBILITY_CHECK.md)

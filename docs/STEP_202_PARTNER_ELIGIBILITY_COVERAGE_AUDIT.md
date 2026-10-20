# Step 202 — Partner Walker Eligibility and Coverage Compatibility Audit

**Status:** Read-only source audit  
**Repository reviewed:** `dojoplatform2026/dojo-partner`, `main`  
**Admin documentation branch:** `step-119-boundary-geometry`  
**Scope:** Compare partner profile fields and coverage with the assignment contract. No code, rules, data, deployment, or merge changes.

## 1. Walker eligibility fields match Admin helper names

Partner's reviewed `firestore.rules` and onboarding source use:
- `status`
- `verificationStatus`
- `isApproved`
- `isActive`

The onboarding flow initializes a new profile with `status: 'in_progress'`, `isActive: false`, `isApproved: false`, `verificationStatus: 'pending'`. Admin's helper only considers a walker eligible for availability when status normalizes to `approved`, verification is `verified`, `isApproved == true`, and `isActive == true`. These field names align, but a newly registered partner is intentionally not eligible.

## 2. Current coverage model is legacy/free-text plus zone IDs

File: `lib/features/onboarding/screens/work_location_screen.dart` (SHA `9c5d5e12a3fd29785d2001fb20937a7bbb374df5`).

The onboarding screen:
- queries active documents from `zones`;
- derives `city`, `state`, and `area` from zone documents;
- requires a configured `zoneName`, `name`, or `title`;
- saves `city`, `state`, `area`, `zoneName`, `zoneNames`, `zones` (document IDs), and `travelMode`.

It does not currently save canonical `serviceCityIds` or `serviceAreaIds`. These fields remain proposed only and cannot be assumed to exist. Do not silently convert a legacy zone ID into a Service Area ID.

## 3. Partner rules prevent owner changes to approval flags

File: `firestore.rules` (SHA `7b02a8bfb4fe80ab04d72f59966e2e09c848ffd0`).

The owner update allowlist includes profile/location fields such as `city`, `area`, and `zones`, but excludes `status`, `isActive`, `isApproved`, and `verificationStatus`. Administrative changes require the rules' active `super_admin` check. The reviewed rules permit other signed-in users to read walker profiles only when both `isActive` and `isApproved` are true; the helper does not also require `verificationStatus == 'verified'` or `status == 'approved'`, so assignment must use the stricter eligibility validation.

## 4. Potential registration create-rule mismatch — investigate before changing

The reviewed `personal_details_screen.dart` creates a new walker document with fields including `applicationSubmitted`, `city`, `state`, `area`, `zoneName`, `zoneNames`, `zones`, and `travelMode`, plus profile and eligibility fields.

The reviewed `firestore.rules` initial-create allowlist appears to permit only:
`userId`, `fullName`, `phone`, `dateOfBirth`, `email`, `gender`, `updatedAt`, `createdAt`, `status`, `isActive`, `isApproved`, and `verificationStatus`.

If these exact sources are used together, extra create fields may cause Firestore to reject initial registration. This is a source-level compatibility finding, not a confirmed live reproduction. Before changing rules, check the intended schema, related tests, and actual deployment branch; do not loosen the allowlist blindly.

There is also a status discrepancy to verify: the partner onboarding creates `status: 'in_progress'`, while the reviewed rules' initial-create condition requires `status == 'under_review'`. This may independently reject creation if both revisions are active together.

## 5. Assignment implementation requirements

- Re-read the walker's profile in trusted server-side assignment code and require `status == 'approved'`, `verificationStatus == 'verified'`, `isApproved == true`, and `isActive == true`.
- Explicitly reject `suspended`, `inactive`, `rejected`, and `left` statuses even if booleans conflict.
- Validate schedule/capacity and canonical service-area membership separately; current helper and partner profile fields do not establish either.
- Keep `zones` compatibility until a separately approved migration is designed.
- Confirm registration/rules mismatch before treating partner onboarding as production-safe.

## 6. Evidence and limitations

Files reviewed:
- Partner `lib/features/onboarding/screens/work_location_screen.dart`, SHA `9c5d5e12a3fd29785d2001fb20937a7bbb374df5`.
- Partner `lib/features/onboarding/screens/personal_details_screen.dart`, SHA `ae8a929e9ec724e9536acd2c8ffcc9b7c06c0f82`.
- Partner `firestore.rules`, SHA `7b02a8bfb4fe80ab04d72f59966e2e09c848ffd0`.
- Admin `walker_admin_helpers.dart` and `walker_admin_model.dart` as reviewed in Step 201.

This audit does not prove which rules revision is deployed, read live documents, or inspect every backend path. No code, rules, schema, production data, deployment, or merge was changed.

Related: [Step 200 assignment security contract](STEP_200_BOOKING_ASSIGNMENT_SECURITY_CONTRACT.md), [Step 201 Admin and walker eligibility field audit](STEP_201_ADMIN_AND_WALKER_ELIGIBILITY_FIELD_AUDIT.md).

# Step 129 — Partner Onboarding / Firestore Rules Field Compatibility

Date: 2026-10-18  
Scope: source-level audit of Partner onboarding writes against the checked-in Partner `firestore.rules`.  
Status: **Confirmed source mismatch; Emulator reproduction and deployed Rules verification still pending. No code or data changed.**

## Exact source snapshots

- `lib/features/onboarding/screens/work_location_screen.dart` — blob `9c5d5e12a3fd29785d2001fb20937a7bbb374df5`
- `lib/features/onboarding/screens/personal_details_screen.dart` — blob `ae8a929e9ec724e9536acd2c8ffcc9b7c06c0f82`
- `firestore.rules` — blob `7b02a8bfb4fe80ab04d72f59966e2e09c848ffd0`

These are source snapshots from the repository's `main` ref. They do not establish which Rules are deployed to Firebase.

## Finding A — Initial walker profile creation has a field allowlist mismatch

When `PersonalDetailsScreen` creates a new `walkers/{uid}` document, it supplies fields including:
`applicationSubmitted`, `city`, `state`, `area`, `zoneName`, `zoneNames`, `zones`, and `travelMode`, in addition to the personal/status/timestamp fields.

The checked-in `allow create` rule's `keys().hasOnly([...])` list allows only:
`userId`, `fullName`, `phone`, `dateOfBirth`, `email`, `gender`, `updatedAt`, `createdAt`, `status`, `isActive`, `isApproved`, `verificationStatus`.

Therefore, the client create payload contains fields not allowed by the source rule. Under these rules, initial creation should be denied. This is a deterministic source-level mismatch, but live/deployed behavior must be verified separately.

## Finding B — Existing draft location updates have an allowlist mismatch

For an existing `in_progress` draft, Work Location updates:
`city`, `state`, `area`, `zoneName`, `zoneNames`, `zones`, `travelMode`, and `updatedAt`.

The ordinary owner-update rule permits affected keys such as `city`, `area`, `zones`, and `updatedAt`, but does not include `state`, `zoneName`, `zoneNames`, or `travelMode`. Since the write changes disallowed fields, this update is also expected to be denied under the checked-in source rule.

Personal Details' existing-draft update can likewise add `state`, `zoneName`, `zoneNames`, and `travelMode`, so the same incompatibility applies to that path.

## Proposed verification and repair plan (not executed)

1. Confirm the target Firebase project and deployed Rules revision through the authorized deployment/release process; do not infer it from a local file or branch.
2. Run a Firebase Emulator test against the checked-in Rules for:
   - valid new walker profile creation with the exact current client payload;
   - ordinary personal-detail update with allowed fields only;
   - existing `in_progress` draft location update with exact Work Location payload;
   - rejection of a user attempting to set `isApproved`, `isActive`, or privileged status fields;
   - admin approval/status update behavior.
3. Choose a least-privilege contract: either change the client payload to fit the approved Rules contract, or update Rules to allow only the exact required onboarding fields with type/transition validation. Do not simply broaden the allowlist without tests.
4. Include `applicationSubmitted` and all required onboarding fields in the approved create/update contract only if the workflow genuinely requires them; define types and safe defaults.
5. Run Rules unit tests and Partner app tests. Review shared Firebase Rules/Functions PR impact before any release.
6. Deploy only after explicit approval and coordinated release checks.

## Field matrix

| Client operation | Fields relevant to mismatch | Source-rule result expected |
|---|---|---|
| Create walker profile | `applicationSubmitted`, `city`, `state`, `area`, `zoneName`, `zoneNames`, `zones`, `travelMode` | Denied because create allowlist excludes these fields |
| Update existing draft from Work Location | `state`, `zoneName`, `zoneNames`, `travelMode` | Denied because ordinary update affected-key allowlist excludes these fields |
| Update existing draft from Personal Details | May include the same excluded location fields | Denied when those excluded fields change |

## Step 129 checklist

- [x] Fetch exact Partner screen and Rules source snapshots.
- [x] Compare initial create payload with create allowlist.
- [x] Compare draft update payload with ordinary owner-update allowlist.
- [x] Record least-privilege test/repair plan.
- [ ] Run Firebase Emulator tests.
- [ ] Verify deployed Rules version.
- [ ] Implement reviewed fix and regression tests.
- [ ] Pass Partner/Firebase CI and release review.

**Safety:** No application code, Firestore records, Rules, production configuration, imports, activation, deployments, or merges were changed.

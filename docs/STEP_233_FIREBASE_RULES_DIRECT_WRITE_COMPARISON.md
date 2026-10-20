# Step 233 — Firebase Rules vs Admin Direct-Write Audit

Date: 2026-10-18  
Admin repository: `dojoplatform2026/DOJO-WALK-Admin`  
Admin branch: `step-119-boundary-geometry`  
Firebase repository: `dojoplatform2026/DOJO-WALK-Firebase`  
Firebase branch reviewed: `fix/location-index-import-rules`

## Scope

Compared the Admin service-location direct-write paths from Step 232 with Firebase Firestore Rules and `test/firestore.rules.test.mjs`. This was a read-only audit: no Rules, application data, deployment, or PR state was changed.

## Evidence reviewed

- Firebase `firestore.rules`, blob `b30db9a1857090db12c0c79fd30954f8a5071e87`
- Firebase `test/firestore.rules.test.mjs`, blob `fea72c4d8e12796ca237d943d2ef11f7a147620e`
- Firebase `firebase.json`, blob `93f1eeb1ba84810b6af633df98ec5b3ed15810c9`
- Admin `service_location_boundary_service.dart`, blob `b3291cf5df8663365bffbc479ab298680fdf2e1f`
- Admin `service_location_service.dart`, blob `76a309ddb10d376c6218a921a63c4d811200fa99`

## Findings

### 1. Boundary draft writes: schema and transition largely align

- Admin `saveDraft` creates drafts with location ID/type, points, source metadata, pending status, null verification metadata, and server timestamps.
- Rules' `validBoundaryCreate` requires the corresponding fields, validates the boundary/source/points, and only permits initial `pending` status.
- Existing draft updates are limited to `pending` or `rejected` records; Rules preserve location identity and creation time and require reset-to-pending with null verification metadata.
- Admin `requestVerification` performs that reset, matching `validBoundaryDraftUpdate`.
- Rules keep verification/rejection transitions out of ordinary client updates; those transitions use the trusted callable. Verified boundaries cannot be edited or deleted by clients.

**Test coverage gap:** current rules tests cover attempts to directly verify/reject a pending boundary and editing/deleting a verified boundary. The inspected tests do not clearly exercise the full successful lifecycle of client draft create → edit pending draft → resubmit rejected draft → delete unverified draft. Add focused emulator cases before treating every draft operation as proven.

### 2. Import metadata writes: aligned and create-only

- Admin `saveImport` checks the signed-in actor, uses a server timestamp, and refuses to overwrite an existing import record.
- Rules require an active `super_admin`, a bounded field schema, `importedBy == request.auth.uid`, and `importedAt == request.time`; update/delete are denied.
- Emulator tests already cover valid create, unauthorized roles, actor spoofing, invalid strings, and update denial.
- This record is metadata only; it does not itself authorize bulk location creation. The Admin import UI remains preview-only per Step 232.

### 3. Important policy mismatch: name-index Rules still permit direct client writes

- Admin's named-location save path uses the trusted `saveServiceLocationWithNameIndex` callable, which is the intended atomic location + normalized-name-index write path.
- However, Rules for `service_location_name_indexes` currently allow an active `super_admin` to create, update, and delete index documents directly when the index shape passes validation.
- That leaves a bypass around the trusted callable's atomic relationship: an authorized client could manually add/remove/alter otherwise-valid index records and potentially desynchronize the uniqueness index from the actual location documents.
- The current emulator test explicitly expects a direct index create by a super-admin to succeed, so that test encodes the permissive policy rather than detecting this bypass.

**Recommendation:** in a separate reviewed Firebase change, make client writes to `service_location_name_indexes` deny by default (read access can remain role-scoped) and change emulator tests to assert direct create/update/delete are denied for every client role, including active `super_admin`. Trusted Admin SDK callable writes bypass Firestore client Rules. Confirm callable tests still pass. Do not deploy until CI and review pass.

## Step result

- Boundary draft policy: **mostly aligned; lifecycle test coverage incomplete**.
- Import metadata: **aligned; emulator coverage present**.
- Name-index integrity: **security hardening gap identified** — direct client writes remain permitted.
- Rules changes/deployment: **not performed**.
- Production location records: **not changed**.

## Next step

Step 234 should prepare the narrow Firebase Rules + emulator-test patch for name-index client-write denial, then run the Firebase Rules Emulator Tests and trusted callable tests. Keep it on the existing Firebase feature branch / PR; do not merge or deploy without explicit approval.

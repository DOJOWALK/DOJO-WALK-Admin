# Step 252 — Admin Import Status Contract Audit

Date: 2026-10-19

## Scope
Read-only source audit of the Admin candidate branch `step-186-main-integration-review`. No application code, Firebase data, Rules, Functions, or deployment settings were changed in this step.

## Files inspected
- `lib/features/service_location/services/service_location_service.dart`
- `lib/features/service_location/models/service_location_models.dart`
- Prior gate: `docs/STEP_250_ADMIN_FIREBASE_STATUS_CONTRACT_GATE.md`

## Findings

### 1. Import record status values are not constrained
The `ServiceLocationImport` model stores `status` and `verificationStatus` as plain strings. The service method `saveImport()` only trims/requires non-empty strings before writing them to `service_location_imports`; it does not enforce a canonical allowlist or normalize case.

This means the UI/model/service do not themselves define an authoritative enum contract. Do not infer allowed values from labels shown in the UI without inspecting every producer and the Firebase Rules.

### 2. Import metadata is not the same as importing location records
`saveImport()` writes an audit/metadata document containing `source`, `fileName`, `status`, `importedBy`, `importedAt`, and `verificationStatus`. It does not write the CSV's Country/State/District/City/Area rows into the corresponding service-location collections. The existing CSV workflow remains preview/validation only; recording an import metadata row must not be presented as a committed transactional import.

### 3. Admin identity check is only one layer
The client checks that a Firebase user is signed in and that `importedBy` matches the current UID. This client check does not replace Firestore Rules authorization. The actual production Rules and deployed backend revision still require independent verification.

### 4. Release decision
- Keep Admin PR #11 and companion Firebase work Draft.
- Do not add arbitrary status enums based only on guesses. First enumerate all UI/service call sites that create import records, compare them to Firestore Rules and Firebase migration/callable contracts, then define canonical values and accepted legacy behavior.
- Add positive and negative tests for each accepted/rejected value at the relevant service/model and Firestore Emulator boundary.
- A real CSV import requires a separately reviewed transactional/import plan, idempotency and duplicate handling, parent ordering, rollback/recovery strategy, preview-to-commit confirmation, and Emulator/integration tests.

## Evidence links
- Admin candidate service source: https://github.com/dojoplatform2026/DOJO-WALK-Admin/blob/step-186-main-integration-review/lib/features/service_location/services/service_location_service.dart
- Admin candidate model source: https://github.com/dojoplatform2026/DOJO-WALK-Admin/blob/step-186-main-integration-review/lib/features/service_location/models/service_location_models.dart
- Admin/Firebase contract gate: https://github.com/dojoplatform2026/DOJO-WALK-Admin/blob/step-186-main-integration-review/docs/STEP_250_ADMIN_FIREBASE_STATUS_CONTRACT_GATE.md

## Status
Audit step complete. This is documentation of source findings, not a claim that import status contracts, end-to-end CSV import, production deployment, or location activation are complete.

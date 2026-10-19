# Step 253 — Admin PR #11 Final Import-Path and Scope Gate

Date: 2026-10-19
Repository: `dojoplatform2026/DOJO-WALK-Admin`
PR: #11 — `step-186-main-integration-review`
Audited head: `1a9c8a36b456fef75a9cb2af7e31c7147b812e7f`

## Verified current state

- PR #11 is Open, Draft, and not merged.
- The PR reports 227 changed file paths. This is an integration candidate, not a small isolated feature patch; final file-scope reconciliation remains a release gate.
- At the audited head, GitHub Actions reported both `Admin Web Build Check (No Deploy)` and `Service Location Geometry Tests` completed successfully.
- This confirms those CI workflows passed on the audited head. It does not establish production deployment state or cross-repository compatibility by itself.

## Import-path trace

Files inspected:
- `lib/features/service_location/screens/service_location_screen.dart`
- `lib/features/service_location/services/service_location_service.dart`
- `lib/features/service_location/models/service_location_models.dart`
- `lib/features/service_location/services/location_csv_preview_parser.dart`
- `docs/STEP_121_CSV_IMPORT_READINESS_GATE.md`
- `docs/STEP_218_LOCATION_INDEX_IMPORT_RULES_PATCH.md`
- `docs/STEP_229_DIRECT_WRITE_IMPORT_PATH_AUDIT.md`

Findings:
1. The current Service Locations screen imports and uses CSV preview/validation tools, but the inspected screen has no call to `saveImport()` and does not construct a `ServiceLocationImport` record.
2. `ServiceLocationService.saveImport()` is a metadata-only write to `service_location_imports`. It requires a signed-in user and matching `importedBy`, refuses to overwrite an existing ID, and writes source, filename, status, actor, timestamp and verification status. It does not create Country/State/District/City/Area records from CSV rows.
3. `ServiceLocationImport.status` and `verificationStatus` remain plain strings. The inspected Admin source does not provide an authoritative allowlist. Do not invent values or convert boundary verification states into import lifecycle states.
4. The CSV parser is read-only and its `isSyntacticallyValid` result means syntax/row validation only; it is not authorization to commit data or activate service coverage.
5. The previously documented Firebase Rules proposal accepts bounded non-empty import strings, not strict enumerations. The exact Firebase PR head, current rules tests and deployed Rules version must be rechecked before release.

## Why no import code was added in this step

Implementing a real database-writing importer before the Admin/Firebase status contract, approved parent mapping, trusted write path, idempotency policy and failure-recovery behavior are agreed could create partial or incorrectly-parented production data. Adding guessed status constants would similarly create an unverified cross-repository contract.

This is an intentional safety hold, not a claim that bulk import is implemented.

## Required closure criteria for PR #11

- [ ] Reconcile all 227 changed paths against intended Admin integration and document any unrelated or superseded files.
- [ ] Define import lifecycle and verification fields with accepted values, ownership, transitions and legacy behavior across Admin, Firebase Rules and trusted Functions.
- [ ] Add positive and negative tests for the agreed status contract, including Firestore Emulator coverage.
- [ ] Approve and implement the CSV parent mapping Country → State → District → Service City → Service Area, preserving legacy city compatibility.
- [ ] Design and test a trusted, staged, idempotent import/commit flow with duplicate detection, row-level errors, safe retries, partial-failure recovery, and inactive-by-default locations.
- [ ] Verify Customer and Partner schema compatibility before activating imported coverage.
- [ ] Verify the required-reviewer configuration for the production GitHub Environment and independently verify the deployed backend/Rules revision.
- [ ] Rerun all required CI on the exact final PR head, then obtain human review before any merge or release.

## Decision

**PR #11 remains Draft and is not merge-ready.** Geometry tests and Admin build CI passed, but the import implementation and cross-repository/release gates above remain unresolved. No merge, production deployment, CSV import, location activation or production migration was performed.

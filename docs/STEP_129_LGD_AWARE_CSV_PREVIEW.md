# Step 129 — LGD-Aware CSV Preview Validation

Date: 2026-10-19
Branch: `step-119-boundary-geometry`
Status: **Implemented and CI-verified; preview remains read-only**

## Code changes
- Added `lib/features/service_location/services/location_csv_lgd_validator.dart`.
- Added `test/features/service_location/services/location_csv_lgd_validator_test.dart`.
- Updated `lib/features/service_location/screens/service_location_screen.dart` to include bundled LGD State/District matching in the existing CSV preview's parent-mapping report.

## Behavior
- Normalizes whitespace and case for matching.
- Matches a State against the bundled India State/UT reference.
- Matches the District only within the matched State's LGD code, avoiding cross-state name collisions.
- Returns the matched State and District LGD codes for traceability.
- Reports unknown/ambiguous States and unknown/ambiguous Districts without guessing.
- Continues to check the existing operational Service State → Service City → Service Area mapping separately.
- Clearly reports that LGD reference matching is not a live Firestore District level and does not approve imports.

## Safety constraints retained
- No Firestore writes added.
- No automatic create/update/activation of any location.
- No production import or data migration.
- Customer and Partner repositories unchanged.
- No Firebase deployment or PR merge.

## CI evidence for final code commit
Commit: `173d92a472bfc0382ee8d8c283309e68035ed8e8`
- Service Location Geometry Tests — run 427 — **PASS**.
- Admin Web Build Check (No Deploy) — run 455 — **PASS**.
- Admin Web workflow completed: full-project Flutter analysis, complete Flutter test suite, and Flutter Web release build all passed.
- Geometry workflow completed: formatting, patch whitespace check, activation integration analysis, and geometry unit tests all passed.

## Remaining blocker before a writable State → District → City → Area hierarchy
The existing trusted backend contract and Firestore Rules do not yet support a separate `service_districts` entity or a District parent ID on operational Service Cities. This step deliberately adds only read-only LGD validation. The next implementation must coordinate the Admin UI with the trusted callable schema and Rules, rather than sending unsupported fields or silently treating a District as a Service City.

## Next
Agree and implement the trusted District data contract in the Firebase repository, then update Admin models/service/UI as a coherent tested vertical slice. Keep legacy City/District documents readable, and keep all changes unmerged and undeployed until reviewed.

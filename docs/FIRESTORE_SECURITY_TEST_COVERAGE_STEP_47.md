# DOJO WALK — Firestore Security Test Coverage (Step 47 follow-up)

Date: 2026-10-17  
Tracking repository: `dojoplatform2026/dojo-admin`  
Tracking branch: `restore/india-location-reference-data`  
Rules repository: `dojoplatform2026/DOJO-WALK-Firebase` (main)

## Current outcome

**Additional tests committed; execution result is pending.** The correct repository name is `DOJO-WALK-Firebase` (uppercase). Its current rules, Node test harness, and workflow were retrieved and inspected.

## Test changes committed

File: `test/firestore.rules.test.mjs`

- Added Area activation denial when the verified boundary is missing.
- Added Area activation success when a verified boundary matches the Area ID.
- Added Area activation denial when the referenced verified boundary belongs to another Area.
- Added name-index authorization tests: active `super_admin` allowed; active `admin`, active `support`, and inactive `super_admin` denied.
- Added import-audit tests for authorized creation, denial of active support role, denial of actor spoofing, and denial of audit-record updates.
- Added an active `admin` fixture and tests confirming an active non-super-admin is not authorized for service-location writes.

Commits on `DOJO-WALK-Firebase/main`:
- `69c345f7475bf594ba6f531a07b49006e531a1b1` — Area, index, and import tests.
- `b0a2266c0dd97f3200c96ac82e77c5e8babae97a` — active non-super-admin authorization coverage.

Test file: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/blob/main/test/firestore.rules.test.mjs

## Important rules gap identified

The current `validAreaActivation()` checks that the Area references a verified boundary whose `locationId` and `locationType` match the Area. It does **not** itself validate that the parent City is active/verified or perform polygon containment. Existing service-layer containment checks are not equivalent to enforcement in Firestore Rules. Treat parent activation/containment as a separate security/backend requirement; do not claim it is covered by these rules tests.

The rules' current admin roles are `super_admin`, `admin`, and `support`. Proposed product roles such as `location_admin`, `operations_admin`, and `support_admin` are not assumed to be implemented. Any role expansion requires an approved permission matrix and matching rules/UI work.

## CI status

- The repository workflow `.github/workflows/test-firestore-rules.yml` runs the tests through Firebase Emulator on pushes to `main`, pull requests, or manual dispatch.
- The GitHub connector did not provide a workflow-run result in this pass. Therefore **these new tests are committed but not yet confirmed PASS**. Capture the exact Actions run URL and confirm its conclusion before marking them passed.
- Step 46 remains user-confirmed PASS from the earlier conversation; its exact Actions run URL is still missing.

## Safety / scope

- No production Firebase deployment was performed.
- No service locations were imported or activated.
- This change adds tests only; it does not alter production rules or broaden admin permissions.

## Next step

Verify the Actions run triggered by commit `b0a2266c0dd97f3200c96ac82e77c5e8babae97a`. If it fails, fix the test fixture or rules only after reviewing the failure logs. Then plan a separate security change for parent City state and polygon containment, with explicit emulator tests.

# DOJO WALK — Firestore Security Test Coverage (Step 47 follow-up)

Date: 2026-10-17  
Tracking repository: `dojoplatform2026/dojo-admin`  
Tracking branch: `restore/india-location-reference-data`  
Rules repository: `dojoplatform2026/DOJO-WALK-Firebase` (main)

## Current outcome

**Additional tests and a rules hardening change are committed; execution result is pending.** The correct repository name is `DOJO-WALK-Firebase` (uppercase). Its current rules, Node test harness, and workflow were retrieved and inspected.

## Test changes committed

File: `test/firestore.rules.test.mjs`

- Added Area activation denial when the verified boundary is missing.
- Hardened `validAreaActivation()` so an Area can only be activated if its parent City exists, is active, and itself passes verified-boundary validation.
- Added a regression test denying Area activation when the parent City is inactive.
- Added Area activation success when a verified boundary matches the Area ID.
- Added Area activation denial when the referenced verified boundary belongs to another Area.
- Added name-index authorization tests: active `super_admin` allowed; active `admin`, active `support`, and inactive `super_admin` denied.
- Added import-audit tests for authorized creation, denial of active support role, denial of actor spoofing, and denial of audit-record updates.
- Added an active `admin` fixture and tests confirming an active non-super-admin is not authorized for service-location writes.

Commits on `DOJO-WALK-Firebase/main`:
- `69c345f7475bf594ba6f531a07b49006e531a1b1` — Area, index, and import tests.
- `b0a2266c0dd97f3200c96ac82e77c5e8babae97a` — active non-super-admin authorization coverage.
- `ede074758e8bbe971bf923df3478fd9b55254e42` — repaired test fixtures and added a scoped active `admin` role fixture.
- `b478b373ac340bf10023bfa404b7937eb2d0a4d2` — require an active, boundary-verified parent City before Area activation.
- `d447c37bd63b955ab8cec2c0d3ad331ac41ca4ae` — test denial when parent City is inactive.

Test file: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/blob/main/test/firestore.rules.test.mjs

## Important rules gap identified

The current `validAreaActivation()` now checks that the Area references a verified matching Area boundary and that its parent City exists, is active, and passes `validCityActivation()`. It still does **not** perform polygon containment. Existing service-layer containment checks are not equivalent to enforcement in Firestore Rules; polygon containment remains a separate security/backend requirement.

The rules' current admin roles are `super_admin`, `admin`, and `support`. Proposed product roles such as `location_admin`, `operations_admin`, and `support_admin` are not assumed to be implemented. Any role expansion requires an approved permission matrix and matching rules/UI work.

## CI status

- The repository workflow `.github/workflows/test-firestore-rules.yml` runs the tests through Firebase Emulator on pushes to `main`, pull requests, or manual dispatch.
- The GitHub connector did not return a workflow-run result for the latest commit in this pass. Therefore **these new tests are committed but not yet confirmed PASS**. Capture the exact Actions run URL and confirm its conclusion before marking them passed.
- Step 46 remains user-confirmed PASS from the earlier conversation; its exact Actions run URL is still missing.

## Safety / scope

- No production Firebase deployment was performed.
- No service locations were imported or activated.
- This change adds tests only; it does not alter production rules or broaden admin permissions.

## Next step

Verify the Actions run triggered by commit `b0a2266c0dd97f3200c96ac82e77c5e8babae97a`. If it fails, fix the test fixture or rules only after reviewing the failure logs. Then plan a separate security change for parent City state and polygon containment, with explicit emulator tests.


## Follow-up — parent City fixture correction (2026-10-17)

- Commit `bafe724b628d7a4a79ae2569fdcc49827dca93f7` updates `test/firestore.rules.test.mjs` in `dojoplatform2026/DOJO-WALK-Firebase`.
- Review found the shared test fixture's active parent City referenced a verified boundary whose `locationId` belonged to a different City. Since the rules deliberately require an exact boundary/location ID match, the Area-success test would be denied for the wrong reason.
- Added a separate verified test boundary for `city-parent` and updated the inactive-parent fixture to use that same matching boundary. This makes the positive and negative Area-parent tests reflect the intended rule checks.
- This is a fixture correction only; the Firestore rules themselves were not changed by this commit.
- Emulator/CI execution is still **not confirmed**. Do not claim PASS until the Actions conclusion or local emulator output is inspected.

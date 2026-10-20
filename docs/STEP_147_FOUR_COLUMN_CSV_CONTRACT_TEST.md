# DOJO WALK — Step 147: Four-Column CSV Contract Test

Date: 2026-10-18
Branch: `step-119-boundary-geometry`
Status: test added to GitHub; execution not yet verified.

## What changed
Added a focused test to:
`test/features/service_location/services/location_csv_preview_parser_test.dart`

Test name:
`maps State, District, City, and Area as four distinct source values`

The test deliberately puts the CSV headers in a different order (`Area,City,State,District`) and checks that the preview parser:
- Maps each source field by header name, not by fixed column position.
- Preserves State, District, City, and Area as four separate keys/values.
- Does not silently collapse City into District.
- Still reports the row as syntactically valid only; this is not permission to import/write data.

## Commit
`a730b93d53c67837d76e1268b1818d6ac96dbf3f`

## File
https://github.com/dojoplatform2026/DOJO-WALK-Admin/blob/step-119-boundary-geometry/test/features/service_location/services/location_csv_preview_parser_test.dart

## Validation
- Confirmed via GitHub fetch that the test file contains the new test.
- The workflow-run lookup returned no run for this commit at the time of inspection. Therefore the test has **not been reported as executed or passed** in this step.
- No District schema, Firestore rules/callables, production data, deployment, activation or merge was changed.

## Next step
Step 148: inspect the Actions workflow history for the latest Admin branch and check whether the focused Service Location tests plus full Flutter analyze/test/Web build are running. If checks are absent, report that accurately; do not claim a pass. Continue with safe tests only until the product approval gate for District/City semantics is resolved.

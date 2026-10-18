# Step 235 — CI Verification: Name Index Client-Write Denial

Date: 2026-10-18

## Result

**PASS on the latest combined branch commit** `edad8502e590f1cedb3c105130dae9792bcf63a9`.

- Firestore Rules Emulator Tests: [run 39141863343 — success](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39141863343)
- Trusted Location Geometry and Callable Tests: [run 39141863422 — success](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39141863422)

The Rules emulator run passed on the latest commit after the test expectations were updated to match the stricter policy. The trusted callable/geometry workflow also passed, confirming the tested callable build and integration path remained green.

## Earlier intermediate failure explained

An earlier Rules run on commit `b508995a9d41dd8b2c91d5a11a3e2a09e58e2aae` failed because the Rules file had already been tightened while the older test file still expected a direct active-super-admin name-index create to succeed. The failure was the outdated test expectation, not a reason to loosen the Rules. The next commit updated the test and the latest Rules emulator run passed.

## Security patch status

- `service_location_name_indexes`: client SDK create/update/delete denied.
- Read access remains governed by the existing `isAdmin()` helper.
- Named-location + index writes remain the responsibility of the trusted callable.
- Changed files were fetched back and verified in Step 234.
- No production deployment was performed.
- Draft PR #6 remains unmerged.

## Next step

Step 236: inspect the full Firebase PR diff and test coverage for unintended changes, then document a review checklist. Do not merge or deploy without explicit approval.

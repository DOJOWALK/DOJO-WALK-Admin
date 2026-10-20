# Step 191 — CR-Only CSV Line Ending Regression Test

Date: 2026-10-18
Branch: `step-119-boundary-geometry`

## Change
Added a regression test proving the read-only location CSV parser handles legacy CR-only line endings and reads two data rows without row-validation errors.

Test commit: `5d3c541ef09ce9d72019933c5437d1b99e9c1eb0`.

## Verification
The previous branch head `a63ed9e12c81cea413805ad9709d8253dfc12a06` had successful Geometry Unit Tests and Web Build checks.
For this Step 191 commit, CI has started but was queued/in progress at report creation. Do not mark this new test PASS until the checks for the current head finish successfully.

## Safety
Test-only change. CSV import remains preview-only. No schema changes, Firebase writes, production imports, location activation/deactivation, deployment, or PR merge.

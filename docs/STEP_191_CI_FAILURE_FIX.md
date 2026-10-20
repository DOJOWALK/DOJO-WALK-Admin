# Step 191 — CI Failure Fix

Date: 2026-10-18
Branch: `step-119-boundary-geometry`

## Failure found
The Step 190 CI failure was in the newly added header-normalization test. The fixture used `District_Name` and `City-Name`, which normalize to `districtname` and `cityname`; those are not the required headers `district` and `city`. The parser correctly rejected them. This was a test-fixture mistake, not a parser regression.

## Fix
Updated the fixture to use ` S T A T E `, `dis-trict`, `ci_ty`, and `a-rea`. These normalize to the four exact required header keys and test the intended behavior.

Fix commit: `19fccbbd1b13af3120ab9d900afc1d687e1fdb76`.

## Verification
The previous Step 190 CI runs failed (48/49 tests and 67/68 tests passed). New CI for this fix must complete before marking the test PASS.

## Safety
Test-only change. No Firestore schema changes, production imports, activation/deactivation, deployment, or Partner/Customer migration. Admin PR #7 remains Draft.

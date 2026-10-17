# Step 188 — BOM and Windows CRLF CSV Regression Test

Date: 2026-10-18
Branch: `step-119-boundary-geometry`

## Change
Added a parser regression test for a UTF-8 BOM at the start of the CSV header and Windows CRLF record endings. The test also confirms an optional source code with leading zeroes remains a string in the read-only preview.

Test commit: `df6686dde48ff95b4e6606eb4a4ae08148813bc1`.

## Verification
Step 187's UI fix passed both `build-web` and `geometry-unit-tests`.
CI for the Step 188 test commit must finish before this new test is marked PASS.

## Safety
Test-only change. No Firestore writes, schema migration, production import, activation/deactivation, deployment, or Partner/Customer migration. Admin PR #7 remains Draft.

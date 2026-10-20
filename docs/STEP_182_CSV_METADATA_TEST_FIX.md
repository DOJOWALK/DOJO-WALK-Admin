# Step 182 — CSV Metadata Test Failure and Fix

Date: 2026-10-18
Branch: `step-119-boundary-geometry`

## Finding
The first CI run for Step 181 failed in the new test `preserves optional source codes and version columns in read-only preview`. The test fixture used a literal backslash-n sequence instead of a real newline between the CSV header and data row. Existing parser behavior was correct; the test input was malformed for the intended scenario.

## Fix
Updated the test fixture to use a real newline escape in the Dart string. No production/parser logic changed in this fix.

## Commit
`54593b258faf79066565a6c1adab2cd992aaadf5`

## Verification
CI has been triggered for the fix. Do not consider Step 181 validated until the exact fix commit's geometry-unit-tests and build-web checks complete successfully.

## Scope and safety
No Firebase writes, schema changes, deployment, production import, or activation changes. Admin PR #7 remains Draft and unmerged.

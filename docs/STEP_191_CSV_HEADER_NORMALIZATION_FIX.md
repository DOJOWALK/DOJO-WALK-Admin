# Step 191 — Fix CSV Header Normalization Regression Fixture

Date: 2026-10-18
Branch: `step-119-boundary-geometry`

## Finding
Step 190 CI exposed an incorrect expectation in the new test: `district_name` normalizes to `districtname`, not the required header `district`; similarly `City-Name` normalizes to `cityname`, not `city`. The parser's documented contract removes separators; it does not strip words or suffixes.

## Fix
Updated the test fixture to use ` STATE `, `dis-trict`, `C_i_t_y`, and `Area`. These test case folding, surrounding whitespace, hyphens, and underscores while preserving the parser's existing contract. No parser behavior was changed.

Test fix commit: `eb99e1ac59a1ee040821ba81229639a5387c87cd`.

## Verification
Step 190 CI failed on this test (48 passed / 1 failed in geometry tests; 67 passed / 1 failed in web build). The corrected test needs fresh CI on the latest commit before it can be marked passing.

## Safety
Test-only correction. No Firestore schema changes or writes, no production import, no location activation/deactivation, no deployment, and no merge. Admin PR #7 remains Draft.

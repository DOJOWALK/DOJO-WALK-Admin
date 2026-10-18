# Step 190 — Required CSV Header Normalization Test

Date: 2026-10-18
Branch: `step-119-boundary-geometry`

## Change
Added a parser regression test for header normalization using valid variations within the parser's documented contract: surrounding spaces and case changes, underscores between letters, and hyphens between letters. The test asserts the four required location fields map correctly.

The first CI run exposed that the initial fixture used `district_name` and `City-Name`, which normalize to `districtname` and `cityname` (the parser removes separators; it does not remove words such as `name`). The test fixture was corrected rather than broadening parser behavior without a product requirement. A double-escaped newline in the fixture was also corrected.

Latest test fix commit: `95d2d50b9af4081d7a4a697763c4955a85cbc176`.

## Verification
CI on the earlier Step 190 commit failed because the test fixture did not match the parser's normalization contract. New CI for the corrected commit must complete before marking the test PASS.

## Safety
Test-only change. No schema changes, Firebase writes, production imports, activation/deactivation, deployment, or Partner/Customer migration. Admin PR #7 remains Draft.

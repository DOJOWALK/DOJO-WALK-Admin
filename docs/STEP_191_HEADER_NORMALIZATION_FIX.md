# Step 191 — Fix Header Normalization Test Fixture

Date: 2026-10-18
Branch: `step-119-boundary-geometry`

The Step 190 CI failure was traced to the test fixture, not the parser: `District_Name` normalizes to `districtname`, and `City-Name` normalizes to `cityname`; neither is the required key `district` / `city`. The test now uses `dis-trict` and `ci_ty`, which normalize to the required names, while also checking case and surrounding whitespace.

Fix commit: `93f00b027e803e59638583b71e2c707cceaf503a`.

CI must complete for the latest branch head before marking this step passed. This is a test-only change; no schema changes, production imports, activation/deactivation, deployment, or app migration. Admin PR #7 remains Draft and unmerged.

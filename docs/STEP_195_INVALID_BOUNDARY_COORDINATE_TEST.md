# Step 195 — Invalid Boundary Coordinate Regression Test

Date: 2026-10-18
Branch: `step-119-boundary-geometry`

## Change
Added a regression test to `test/features/service_location/models/service_location_boundary_test.dart` for NaN latitude, infinite longitude, and latitude/longitude values outside valid geographic ranges. The test asserts that each point is rejected by the existing model validator.

Test commit: `a3330b413200f4d84759bdd98d9d1343d1d51243`.

## Previous CI recovery
The earlier required-header normalization fixture failed because its original example did not match the normalizer's supported separator behavior. The parser/test fixture was corrected in subsequent commits. Latest checked branch head before this Step was `f57fea28671f311285196885fcefc453ea00df97`; both geometry tests and web build passed on that head.

## Verification
CI for this new Step must complete before marking this test PASS.

## Safety
Test-only change. No Firestore schema or production data changes. No import, activation/deactivation, deployment, PR merge, or Partner/Customer migration.

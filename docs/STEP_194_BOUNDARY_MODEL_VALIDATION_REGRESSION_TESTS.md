# Step 194 — Boundary Model Validation Regression Tests

Date: 2026-10-18
Branch: `step-119-boundary-geometry`

## Change
Added two unit tests to `service_location_boundary_test.dart`:
- Reject out-of-range latitude and longitude values.
- Reject a blank location ID and unsupported location type.

This is test-only coverage of existing model validation; production logic and Firestore schema are unchanged.

Test commit: `5967445fa2b5101e71182b32000ac7227c73396b`.

## Previous CI recovery
The current branch head before this change (`15b39136d6b4d41219946a058b8a73fb2ec1c49d`) had both Geometry Unit Tests and Web Build passing. An earlier run failed because the CSV normalization test fixture used `district_name` and `City-Name`, while the parser removes groups of separators but not a separator within a word; the fixture was corrected to `dis-trict` and `ci_ty`, and the later head passed both checks.

## Verification gate
Wait for CI on this commit before marking Step 194 passed.

## Safety
No production writes/imports, activation/deactivation, deployment, PR merge, schema change, or Partner/Customer migration.

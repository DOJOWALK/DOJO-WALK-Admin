# Step 179 — India Reference Filter Regression Tests

Date: 2026-10-18
Branch: `step-119-boundary-geometry`

## Change
Added `test/data/reference/india_locations/india_location_filters_test.dart` to cover:
- District filtering by State LGD code.
- Empty result for an unknown State code.
- Sub-district filtering using both State and District codes.
- No cross-State leakage when only a matching District code is supplied with the wrong State.
- Preservation of Census 2011 State codes with leading zeroes in the reference data.

This is test-only work. It does not change Firestore collections, the service-location schema, CSV imports, activation, or production data.

## Verification status
The test was committed as `cb862be0fc6e7da52267f19e15417a6b4b9a64e9`.
At the time of this report, CI for that commit was queued/in progress; no pass is claimed for this new test until the exact commit's checks finish.

## Compatibility gate unchanged
- The reference datasets are not a production importer.
- State → City → Area remains the existing Admin/Firebase schema.
- A separate District collection and any import writes remain blocked on the product/source approval questions in Step 145.
- Admin PR #7 remains Draft and unmerged.

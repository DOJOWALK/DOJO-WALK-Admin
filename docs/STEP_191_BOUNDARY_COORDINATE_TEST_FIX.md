# Step 191 — Boundary Coordinate Test Fixture Fix

Date: 2026-10-18
Branch: `step-119-boundary-geometry`

## Finding
The Web Build workflow failed while running tests because the test attempted to construct Cloud Firestore `GeoPoint` instances with latitude 91 and longitude 181. The GeoPoint constructor itself asserts valid coordinate ranges, so the test failed before `ServiceLocationBoundary.validate()` could be exercised.

## Change
Replaced that unreachable invalid-GeoPoint fixture with a test using valid coordinate limits (-90/-180 and 90/180). This tests that boundary validation accepts points that the GeoPoint type permits. It does not claim to test impossible out-of-range GeoPoint instances.

Test change commit: `a04a213ebd7246a62bf0ac6eb1127175d98f0f50`.

## Verification
The geometry-unit-tests check on the preceding head passed. The Web Build failed due to the invalid GeoPoint test fixture. CI for this fix must complete before the branch is marked green.

## Safety
Test-only change. No Firestore schema/data changes, imports, activation/deactivation, deployment, PR merge, or Partner/Customer migration.

# Step 120 — Boundary repeated-vertex regression test

Date: 2026-10-19

## Change
- Added a regression test to `test/features/service_location/services/service_location_geometry_test.dart` that rejects a polygon ring repeating a non-consecutive vertex.
- Commit: `89d2fcf9e2fdb8aa51e60617505c93463ab250ed`.

## Verification
- Service Location Geometry Tests — PASS (GitHub Actions run `39159118933`).
- Admin Web Build Check (No Deploy) — PASS (GitHub Actions run `39159118936`).
- Both workflows completed successfully for the test commit.

## Current release blockers
- CSV import remains preview-only; no service-location records are written from CSV.
- State → District → Service City → Service Area hierarchy needs explicit approval and compatible implementation across Admin and Firebase trusted callables/Rules before import writes are safe.
- Official LGD source snapshot reconciliation and authoritative/reviewed service-area polygons remain outstanding.

PR #7 remains open and Draft. No merge, deployment, production import, or activation was performed.

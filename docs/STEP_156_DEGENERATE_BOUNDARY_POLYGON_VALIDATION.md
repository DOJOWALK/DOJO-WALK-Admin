# Step 156 — Reject Degenerate Service Boundary Polygons

Date: 2026-10-18

## Step 155 CI confirmation

All three Step 155 Admin Web Build Check runs completed successfully:
- Helper: https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39071837290
- Tests: https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39071839272
- Final dialog wiring: https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39071856637

The final run's steps all passed, including dependency installation, complete `flutter analyze`, complete `flutter test`, and Flutter Web release build.

## Finding

The polygon validator already rejected repeated consecutive points and self-intersections, but a ring with three or more distinct collinear points could pass the distinct-vertex check while enclosing zero area. Such a boundary is not a usable service polygon.

## Changes

Updated `ServiceLocationGeometry.isValidPolygon` via its ring validator:
- Computes the ring's signed area using the shoelace formula.
- Rejects zero or negligible enclosed area using the existing geometry epsilon.
- Retains the existing coordinate, duplicate-edge, distinct-vertex and self-intersection checks.

Added two geometry tests:
- Rejects a polygon with distinct but collinear vertices.
- Rejects a polygon whose enclosed area is negligible.

## Validation status

New CI runs were triggered for the geometry implementation and its tests. The final result is not yet confirmed in this report; check the workflow runs before claiming Step 156 passes.

## Scope and safety

This is a local geometry validation improvement only. It does not change Firestore schema, callable functions, Rules, imports, service activation, legacy Zones, or the proposed District hierarchy. No production data was written; no merge or deployment occurred.

## Next step

Check CI for the geometry implementation and tests. If successful, continue reviewing the service boundary editor and boundary lifecycle for additional correctness gaps.

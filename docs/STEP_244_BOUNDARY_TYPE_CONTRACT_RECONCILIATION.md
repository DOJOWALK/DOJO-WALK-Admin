# Step 244 — Boundary Type Contract Reconciliation

Date: 2026-10-19

## Finding
A main-branch audit commit raised a potential mismatch because an older Admin boundary model/service accepted locality polygons while the trusted Firebase review callable supports only City and Area.

## Current branch verification
At the current Admin branch before this comment-only change:
- `ServiceLocationBoundary.validate()` accepts only `city` and `area`.
- `ServiceLocationBoundaryService` accepts only `city` and `area`.
- The model regression test rejects a `locality` boundary.
- The Service Location screen opens boundary management only for City and Area.
- Locality service activation does not require its own polygon.

The current branch already resolves the functional mismatch. This step updates the boundary dialog's stale API comment so it no longer advertises locality/village as supported types.

## Validation status
- Previous branch head `f8a7077`: Admin Web Build Check PASS (run 39239664691).
- Previous branch head `f8a7077`: Service Location Geometry Tests PASS (run 39239664630).
- The new comment-only commit triggers fresh CI; do not mark the new head passed until those runs finish.

## Release gate
Admin PR #7 remains Draft/open/unmerged. Current GitHub comparison reported mergeable/clean but one commit behind `main`; recheck exact head/base and all CI after this commit. Other release blockers remain: large PR scope, current official LGD source reconciliation, trusted real GIS polygons and review, and deployed Firebase/production compatibility evidence.

## Safety
No production Firestore writes, CSV import, activation, migration, deployment, merge, or Partner/Customer work performed.

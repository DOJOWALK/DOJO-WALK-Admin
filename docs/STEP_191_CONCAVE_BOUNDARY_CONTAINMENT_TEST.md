# Step 191 — Concave Parent Boundary Regression Test

Date: 2026-10-18
Branch: `step-119-boundary-geometry`

## Change
Added a geometry regression test for a U-shaped/concave City polygon. The Area's four vertices sit inside the two arms, but its horizontal edges bridge the open notch outside the parent boundary. Containment must reject the Area.

Test commit: `da20f7d543dda124aa0c97edc768533727174646`.

## Why it matters
Checking child vertices alone is insufficient for concave parent polygons. The existing containment routine also checks edge midpoints and proper edge crossings; this test protects that behavior against regression.

## Verification
The previous branch head `796f9dc7b8003875c0df513e68dded91a83e81fb` had successful Geometry Unit Tests and Admin Web Build. CI for this new Step 191 commit must complete before this test is marked PASS.

## Safety
Test-only change. No Firestore schema changes, imports, activation/deactivation, deployment, or Partner/Customer migration. Admin PR #7 remains Draft.

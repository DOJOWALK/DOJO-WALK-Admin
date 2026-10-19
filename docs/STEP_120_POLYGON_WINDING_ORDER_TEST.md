# DOJO WALK Admin — Step 120: Polygon Winding-Order Regression Test

## Change
Added a geometry unit test proving that a simple polygon is accepted in both clockwise and counter-clockwise vertex order. Polygon validity should depend on geometry, not ring winding direction.

## Validation
- The review branch's latest Step 119 code head had both Service Location Geometry Tests and Admin Web Build Check (No Deploy) passing.
- Step 120's new test has been committed and its CI is pending.
- This is a synthetic unit-test change; no production location records or boundaries were modified.

## Remaining release blockers
- Full CSV import design is still blocked on the cross-repository District-versus-City schema decision.
- Fresh official LGD reconciliation and authoritative UP/NCR boundary-source verification remain pending.
- Trusted backend deployment and production review settings have not been verified.
- PR #7 remains Draft/open/unmerged. No merge or deployment performed.


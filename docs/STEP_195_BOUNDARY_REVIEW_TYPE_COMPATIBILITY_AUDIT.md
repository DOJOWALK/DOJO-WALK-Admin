# Step 195 — Boundary Review Type Compatibility Audit

Date: 2026-10-18
Branch: `step-119-boundary-geometry`

## CI recovery
Current branch head before this audit: `44cc36f916572a9fe4aaab89506150bdbda2148f`.
- Geometry Unit Tests: PASS — https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39124600426
- Admin Web Build: PASS — https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39124600409

The earlier CSV test failure was a fixture mismatch: parser normalization removes groups of separators, but does not remove a separator inserted inside the word. The fixture was corrected to `dis-trict` and `ci_ty`; both checks now pass.

## Audit finding
Admin `ServiceLocationBoundary.validate()` and `ServiceLocationBoundaryService._isSupportedLocationType()` accept `city`, `area`, and `locality`. The Firebase trusted review callable currently accepts only `city` and `area` boundaries and rejects `locality` during review.

This creates a cross-repository contract mismatch: a locality boundary can pass Admin draft validation and be saved as pending, but cannot complete the trusted verification lifecycle.

## Recommended resolution
Since the current Service Location product flow does not require locality boundaries after an Area, align the Admin boundary model/service validation with the trusted backend's supported types (`city` and `area`) and add regression tests proving `locality` is rejected before save. Do not modify Firebase schema or broaden backend verification support without an explicit product decision.

## Safety
Audit/report only. No code/schema changes, production writes/imports, activation/deactivation, deployment, merge, or Partner/Customer migration. PR #7 remains Draft.

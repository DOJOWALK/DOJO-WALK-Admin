# Step 165 — Boundary Chooser Ordering Tests

## Status
Implemented on `step-119-boundary-geometry`.

## Changes
- Model helper `sortBoundariesForChooser` centralizes ordering for the explicit boundary chooser.
- Order: Pending, Rejected, Verified, then unavailable status.
- Newer `updatedAt` records appear first within the same status.
- Sorting returns an unmodifiable list and does not mutate the caller's input.
- Added two unit tests covering status order and newest-first ordering/input preservation.
- Screen now uses the tested helper.

## Commits
- Helper: `36a455a508e79939d1c279ce38f7f6cb9c63bc26`
- Tests: `dd320efff3b1a2623b6d3f8b2d9a7e45b04a08a2`
- Screen wiring: `dbb55893600f2febd6ba980ca0f2fb1de044ba68`

## CI
- [Admin Web Build Check — helper](https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39073894851): **success**
- [Admin Web Build Check — tests](https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39073914052): **success**
- [Admin Web Build Check — screen wiring](https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39073925564): **success**
- Each workflow completed the repository's dependency installation, full Admin analysis, full test suite, and Flutter Web release build.

## Safety scope
No schema, Firestore Rules, callable Functions, production records, imports, activation state, or legacy Zones were changed. District schema approval remains a blocker for any separate District migration. PR #7 remains unmerged; no deployment or production import was performed.

## Remaining validation
The current CI includes unit tests for the ordering helper but does not add a widget test for selecting/cancelling items in the chooser. The next review should audit remaining Service Locations operational paths and test gaps before any merge decision.

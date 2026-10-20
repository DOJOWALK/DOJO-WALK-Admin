# Step 177 — Service Location UI Workflow Audit

Date: 2026-10-18
Branch: `step-119-boundary-geometry`
Scope: read-only inspection of the current Admin UI and Add Location workflow.

## CI status rechecked

For Step 176 report commit `d49a2df75054ff424d9bf2b89dd565d8593c16f9`:
- Admin Web Build: success — run `39077196709`
- Geometry Unit Tests: success — run `39077196596`

PR #7 is still open, Draft, and unmerged. GitHub currently reports it mergeable/clean; that is not a product approval or release authorization.

## UI workflow checks

| Area | Result | Source evidence |
|---|---|---|
| Responsive shell | PASS | Service Location screen uses different toolbar and map-preview sizes below 600px. |
| Search UX | PASS | Search text is controlled by a controller, supports clear action, and is applied to the location lists. |
| Map safety | PASS | The map preview loads active verified boundary polygons; it does not create boundaries or activate coverage. |
| Add Location error handling | PASS | Save is guarded against repeat taps, catches errors, shows a readable dialog, and resets saving state in `finally`. |
| Parent selection safety | PASS | Dependent dropdowns filter by parent IDs; changing a parent clears descendants; stale selection IDs are not retained when absent from the current options. |
| New-record activation safety | PASS | Add Location creates new country/state/city/area/locality records inactive. |
| Boundary lifecycle | PASS | Boundary editing/review remains separate from location creation and service activation. |
| CSV import safety | PASS | CSV parser validates four required source columns and rows only; it has no Firebase write path. |

## Remaining product/implementation blocker

The user-requested CSV fields State, District, City, and Area remain separate in the preview contract, but the actual service model still has State → City → Area and labels City as “City / District”. No separate District collection/model or foreign-key contract exists in the audited Admin branch.

This cannot be fixed safely as a UI-only change. Once product semantics and stable source codes are confirmed, Admin, Firebase Rules, callable Functions, and emulator tests must be updated together. No schema change is made in this step.

## Release decision

- No production writes, import, activation/deactivation, deployment, or merge performed.
- PR #7 remains Draft.
- Do not start Partner or Customer migration until the Admin schema decision and release gates are complete.

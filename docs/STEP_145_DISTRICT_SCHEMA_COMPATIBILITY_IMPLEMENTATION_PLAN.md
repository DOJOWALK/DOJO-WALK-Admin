# DOJO WALK — Step 145: District Schema Compatibility-First Implementation Plan

Date: 2026-10-18
Admin branch: `step-119-boundary-geometry`
Firebase review branch: `step-138-partner-submission-negative-tests`
Status: planning only; no schema/code/data changes in this step.

## Objective
Support separate State, District, Service City and Service Area concepts without breaking existing service-location documents, legacy `zones`, or the current boundary activation safeguards.

## Approval gate — resolve before implementation
The source import has State, District, City and Area columns. Before implementing, the product owner must confirm:
1. Is the source City column a real administrative City, or a DOJO-defined service coverage grouping?
2. Can one Service City belong to one District only?
3. Does a service coverage Area always belong to one Service City?
4. Are imported District/City/Area records reference-only until an admin explicitly creates or verifies service coverage?
5. Which authoritative source and version will be used for each column, including stable source codes?

Do not infer answers from names or import rows.

## Proposed compatibility-first sequence

### Phase A — schema contract and inventory
- Define a canonical `ServiceDistrict` model and `service_districts` collection only after approval.
- Preserve LGD/source codes as strings to retain leading zeroes.
- Keep legacy `service_cities` and `service_areas` documents readable.
- Treat `districtId` on existing City documents as optional during the compatibility window.
- Never reclassify an existing City/District document automatically.
- Keep legacy `zones` untouched.

### Phase B — Admin read path
- Add District model/service queries and a District tab or equivalent explicit management surface.
- Add State → District filters.
- Make City creation explicitly select the approved parent structure; show a legacy compatibility label where a record has no District.
- Make Area selection depend on the selected Service City.
- Keep the existing map boundary preview and boundary review/activation workflow unchanged.
- Do not make District or reference-only data require a service polygon unless the approved contract says it represents service coverage.

### Phase C — trusted Functions
- Add District collection and parent validation to callable Functions.
- Update status/deactivation child maps transactionally.
- Keep City/Area activation routed through `activateServiceLocation`.
- Verify that the City’s District/State/Country ancestry is consistent where `districtId` is required.
- Preserve a clearly defined legacy path for existing documents without `districtId`; do not weaken validation for newly created records.
- Keep boundary ownership checks tied to the actual City/Area owner and verified parent boundary.

### Phase D — Firestore Rules
- Add collection-level access rules and field allowlists for District records.
- Validate District → State → Country ancestry.
- Validate City → District ancestry for new-schema records while maintaining documented legacy read compatibility.
- Ensure users cannot bypass trusted activation/review callables with direct writes.
- Add tests proving unauthorized direct activation/status writes are rejected.

### Phase E — import staging only
- Parse source columns into a preview model with explicit source code, parent code, source/version and row number.
- Validate duplicate codes, duplicate normalized names within the intended parent, missing parents, malformed rows and ambiguous mappings.
- Generate a row-level preview and error report.
- Do not write imported rows to production service collections in the first implementation.
- Do not generate polygons or mark a City/Area active from administrative reference data.
- Add a deterministic import fingerprint and duplicate-run test before any later write-capable importer is considered.

### Phase F — tests and release gate
- Run Admin formatting, unit tests and web build in CI.
- Run Firebase lint/type-check and emulator Rules/Functions integration suites.
- Inspect all CI job results before reporting pass/fail.
- Review the Admin + Firebase PRs together.
- Merge only after explicit approval and all required checks pass.
- Deploy Functions separately with explicit approval; no deployment is part of this plan.

## Required test matrix

| Area | Scenario | Expected result |
|---|---|---|
| District model | Valid District with State/Country parent | Accepted |
| District model | Missing/invalid State parent | Rejected |
| Source codes | Code contains leading zeroes | Preserved as string |
| Import preview | Duplicate source code | Row flagged; no writes |
| Import preview | Parent District/State missing | Row flagged; no writes |
| Import preview | Duplicate name under different parents | Not incorrectly treated as global duplicate |
| City compatibility | Legacy City has no districtId | Existing record remains readable |
| New City | District required by approved contract but absent | Rejected |
| City ancestry | District belongs to another State | Rejected |
| Area ancestry | Area parent City mismatch | Rejected |
| Boundary review | Boundary owner ID/type mismatch | Rejected |
| Activation | City/Area has no verified boundary | Rejected |
| Activation | Area lies outside parent City polygon | Rejected |
| Deactivation | Active child exists | Rejected |
| Rules | Client attempts direct activation bypass | Rejected |
| Authorization | Non-admin attempts District write/review | Rejected |
| Regression | Existing City/Area boundary tests | Continue to pass |
| Regression | Legacy zones untouched | No unintended changes |

## Files expected to change after approval
Admin:
- Service location models
- Service location service
- Add Location dialog and management screen
- CSV preview/staging parser and its tests
- Schema documentation and status report

Firebase:
- `firestore.rules`
- `functions/src/index.ts`
- relevant Rules/Functions emulator tests
- any required indexes/configuration, if evidence shows they are needed

## Exit criteria
- Approved written meaning for State/District/City/Area.
- Compatibility behavior for legacy records is documented and tested.
- Admin and Firebase changes reviewed as one coordinated schema change.
- Required CI checks pass with actual run results inspected.
- No production import, activation, deployment or merge without explicit approval.

## Next step
Step 146: inspect the current Admin and Firebase PR checks and repository test commands, then prepare the smallest executable test-first implementation slice. Do not start schema implementation until the approval gate above is resolved.

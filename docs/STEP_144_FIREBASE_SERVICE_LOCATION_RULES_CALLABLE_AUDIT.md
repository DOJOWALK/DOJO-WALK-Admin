# DOJO WALK — Step 144: Firebase Service Location Rules & Callable Audit

Date: 2026-10-18
Admin branch: `step-119-boundary-geometry`
Firebase review branch inspected: `step-138-partner-submission-negative-tests`
Status: cross-repository audit only; no Firebase changes made.

## Files inspected
- Firebase `firestore.rules`
- Firebase `functions/src/index.ts`
- Firebase integration tests for boundary review, activation and status changes
- Admin service-location models and service-layer notes from Step 143

## Confirmed server-side behavior

### 1. City and Area activation is callable-only
`activateServiceLocation` accepts only `locationType: city|area`, checks an active `super_admin`, requires a verified boundary reference, and checks active Country and State ancestry. For an Area, it also requires an active parent City and checks that the Area geometry is covered by the City's verified boundary. It re-reads relevant documents in a transaction before activation.

### 2. Boundary review is callable-only and audited
`reviewServiceLocationBoundary` accepts only City/Area boundaries, requires an active `super_admin`, only reviews a pending boundary belonging to the referenced location, validates geometry and source metadata, and checks Area coverage by its parent City's verified boundary. The code writes a boundary-review audit record.

### 3. Generic status callable still encodes the current hierarchy
`setServiceLocationStatus` recognizes Country, State, City, Area and Locality. Its parent/child maps explicitly encode:
- State → Country
- City → State
- Area → City
- Locality → Area

It blocks generic activation of City/Area and directs those through `activateServiceLocation`. It also prevents deactivating a parent with active children.

### 4. Firestore Rules encode the same existing parent chain
The Rules include helpers that require a City to reference its Country and State, and an Area to reference its Country, State and City. Rules cover the current `service_countries`, `service_states`, `service_cities`, `service_areas`, `service_localities`, boundary, name-index and import collections.

## Critical gap before a District schema change
The proposed separate `service_districts` level is not represented in the currently inspected callable parent maps or existing ancestry checks. Adding a `districtId` field only in the Admin model/UI would leave the backend enforcing the old chain and could create inconsistent records.

A safe schema change must be coordinated across:
1. Admin models, Add Location form, list/filter queries and save operations.
2. Trusted Functions: create/update validation, parent checks, status/deactivation maps, activation and boundary ownership checks.
3. Firestore Rules: allowed fields, parent consistency, collection access and index/boundary ownership rules.
4. Emulator tests: authorized and unauthorized access, missing/wrong District parent, child deactivation, activation ancestry, legacy records without `districtId`, and existing City/Area geometry cases.
5. Read-only LGD staging: preserve codes as strings; no automatic creation of service coverage entities or inferred boundaries.

## Compatibility decision
Do not modify the current schema until the business meaning of the four source columns is approved:
- State = administrative source record.
- District = distinct administrative source record.
- City = explicitly defined DOJO service grouping, not auto-derived from a district name.
- Area = DOJO coverage area with a reviewed polygon.

Keep legacy City/District records readable. If a new District level is approved, make `districtId` optional for legacy documents initially and introduce explicit validation for newly created documents, rather than requiring a destructive backfill.

## Tests / verification
The repository contains dedicated integration tests for:
- `functions/test/activate_service_location.integration.test.cjs`
- `functions/test/review_service_location_boundary.integration.test.cjs`
- `functions/test/service_location_status.integration.test.cjs`

This audit inspected source and test presence; it did not execute tests. Existing previously recorded CI passes do not validate a future District schema change.

## Next step (Step 145)
Create a coordinated implementation plan with a compatibility-first migration sequence and test matrix. Do not change production data, deploy Functions, activate locations, or merge PRs during planning.

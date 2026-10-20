# Step 127 — Firebase Rules and Callable Impact Audit

Date: 2026-10-18  
Repository reviewed: `dojoplatform2026/DOJO-WALK-Firebase`  
Ref reviewed: `feature/trusted-location-activation`  
Status: **Read-only audit; no Firebase code or deployed configuration changed**

## Evidence inspected

- `firestore.rules` at blob `5d179e99def9c66e402596e54bd9d667e654131b`
- `functions/src/index.ts` at blob `ff234380a82be6daa0430702bd5a222f8776c0c7`
- Admin design proposal: `docs/SERVICE_LOCATION_DISTRICT_CITY_SCHEMA_PROPOSAL.md`
- Admin compatibility matrix: `docs/STEP_126_SCHEMA_COMPATIBILITY_MATRIX.md`

These refs are repository branch content, not proof that this code is deployed to production.

## Findings

### 1. Firestore Rules have strict allowlists

- `service_states` create/update allowlists currently cover `countryId`, `name`, `isActive`, timestamps; there is no `lgdCode` field allowance.
- `service_cities` create/update allowlists currently cover existing State/Country/name, boundary, verification reference, active flag and timestamps; no `districtId` or explicit LGD metadata.
- `service_areas` create/update allowlists currently cover existing Country/State/City/name, boundary and activation fields; no separate District or administrative Sub-District identity.
- The rules include parent helper checks: City must match Country/State; Area must match Country/State/City.
- A new `service_districts` collection rule is not present in the inspected rules excerpt/file. New client writes would require an explicitly designed rule; do not assume the Admin client can write the collection.

### 2. Trusted Functions assume the current hierarchy

- `activateServiceLocation` accepts only `city` or `area`.
- City activation checks Country and State, then a verified City boundary.
- Area activation checks Country and State, its parent City, verified City/Area boundaries, and area containment in the City polygon.
- `setServiceLocationStatus` currently models parent chain Country → State → City → Area → Locality.
- Its child-deactivation checks query active States, Cities, Areas and Localities using the existing parent fields. A new District layer must be incorporated into parent validation and descendant checks without breaking legacy City records.
- Boundary review currently recognizes only City and Area boundary owners. District reference records should not automatically become activatable service coverage polygons.

### 3. Backward-compatible implementation implications

1. Design Rules and callable changes as one coordinated contract; changing only Admin models will not be sufficient.
2. Add the District collection and its authorization/schema checks deliberately; default-deny should remain the behavior for unrecognized fields.
3. New Service Cities with a District parent should validate that District belongs to the same State/Country.
4. Existing Cities without `districtId` must remain readable and must not be silently assigned a District. New-write behavior for legacy records must be specified separately.
5. Existing Areas must continue matching their parent City and existing boundary lifecycle. A new District reference must not weaken polygon ownership/containment checks.
6. Update descendant deactivation protection so active District descendants cannot be orphaned or left active. Also inspect locality ancestry and all callable paths for consistent parent IDs.
7. Add Emulator tests for both old and new records, including absent `districtId`, invalid/mismatched District parent, non-admin access, District under wrong State, City under wrong District, Area under wrong City, activation boundaries and deactivation with active descendants.

## Required test matrix

| Scenario | Expected result |
|---|---|
| Existing legacy City has no `districtId` | Read remains supported; no inferred parent |
| New City references a valid District under its State | Allowed only after schema contract and Rules/Function checks are implemented |
| City references District from another State | Denied |
| District reference has malformed/missing source code | Denied or held in non-operational reference import state, per approved contract |
| Admin sends unapproved extra fields | Denied by strict allowlists |
| Area's City/State/Country ancestry conflicts | Denied |
| Area boundary is not verified or lies outside City polygon | Activation denied |
| Attempt to deactivate District with active descendants | Denied until descendants are safely deactivated |
| Non-super-admin calls trusted activation/review | Denied |
| Legacy Partner zone record exists | Not modified by this schema change; migration requires separate adapter and tests |

## Step 127 result

- [x] Identified the Rules allowlists that would reject new District/LGD fields.
- [x] Identified callable functions that assume the existing parent hierarchy.
- [x] Recorded compatibility requirements for legacy Cities, Areas and activation/deactivation.
- [ ] Schema approved.
- [ ] Rules/Functions implementation and Emulator tests.
- [ ] Cross-app integration tests.
- [ ] Production deployment verification.

No Firebase code, production data, Rules deployment, callable deployment, location activation, import, or merge was performed in this step.

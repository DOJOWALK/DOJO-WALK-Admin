# Step 130 — Trusted District Schema Contract (Pre-Implementation Gate)

Date: 2026-10-19
Admin branch: `step-119-boundary-geometry`
Firebase reference inspected: `DOJO-WALK-Firebase` branch `fix/location-index-import-rules`
Status: **Contract documented; no runtime schema changed in this step**

## Goal
Introduce a real District level without silently treating an LGD District as an operational Service City, breaking legacy records, or allowing clients to bypass trusted location validation.

Target operational hierarchy:
`Country → State → District → Service City → Service Area → optional Locality`

The bundled LGD State/District records are a reference dataset. They are not, by themselves, approved service locations and do not prove a boundary.

## Canonical document proposal

### `service_districts/{districtId}`
Required: `countryId`, `stateId`, `name`
Server-managed: `isServiceActive`, `createdAt`, `updatedAt`, guard/audit fields as needed
Optional provenance: `lgdStateCode`, `lgdDistrictCode`, `referenceDatasetVersion`
District creation starts inactive. A District does not become serviceable just because it exists in LGD reference data.

### `service_cities/{cityId}` — operational Service City
Required for new documents: `countryId`, `stateId`, `districtId`, `name`
Server-managed: `isServiceActive`, `verifiedBoundaryId`, audit/guard fields
Existing legacy documents without `districtId` must remain readable. Do not silently infer a District from a City name. Any backfill needs a separate preview, conflict report, and rollback plan.

### `service_areas/{areaId}`
Required: `countryId`, `stateId`, `districtId`, `cityId`, `name`
The persisted ancestor IDs must match the actual parent chain. Area activation must require a verified polygon fully contained by its parent Service City's verified polygon.

### Optional `service_localities/{localityId}`
Locality remains optional and must not be required in Customer booking. If retained, parent ancestry should include Country, State, District, Service City, and Area, with legacy records preserved.

## Trusted callable requirements
- Extend the location type allowlist, collection mapping, mutable-field allowlist, parent-field lists, and name-index contract together.
- District payload accepts only `countryId`, `stateId`, and `name`; client cannot set activation, boundary verification, or audit fields.
- New District saves validate both Country and State exist and State belongs to Country.
- New Service City saves require District and validate District → State → Country ancestry.
- Area saves validate City → District → State → Country ancestry.
- Parent reparenting remains blocked until a separately reviewed migration policy exists.
- Activation/deactivation child guards must include District → City and preserve ancestor serialization against races.
- Boundary review/activation must continue to use Service City and Area polygons; District is not automatically a boundary owner.
- Name-index uniqueness must be scoped by each entity's canonical parent chain and remain compatible with legacy index records during transition.
- Server authorization and Firestore Rules remain authoritative. UI checks alone are not security.

## Admin UI requirements
- Add a separate District tab/form, with State as its parent.
- Selection cascade: State → District → Service City → Service Area. Changing any parent clears all descendants.
- City/District labels must be unambiguous: “District” means LGD/administrative District; “Service City” means operational service boundary.
- Existing legacy City/District records should be visibly flagged as “needs District mapping” rather than auto-mapped.
- CSV preview should show separate columns for LGD State/District match and existing operational Service City/Area mapping. A successful LGD match is not an import approval.
- Import remains preview-only until a reviewed importer, audit trail, conflict policy, and rollback plan are implemented.

## Required tests before enabling writes
1. District name-index ID parent count and parent-scoped uniqueness.
2. Reject unknown fields and client-supplied activation/boundary metadata.
3. Reject District whose State belongs to another Country.
4. Reject City whose District does not match its State/Country.
5. Reject Area whose City ancestry is inconsistent.
6. Reject activation when required ancestors are inactive.
7. Reject deactivation while active descendants exist, including active District descendants.
8. Preserve legacy City/Area/locality document reads and legacy name-index behavior.
9. Race/transaction tests for activation vs ancestor deactivation.
10. Admin model, cascade-reset, import-preview, geometry and Web build tests.
11. Firebase Rules and trusted Functions CI. No deployment until separately approved.

## Implementation order
1. Firebase pure schema helpers and tests.
2. Firebase trusted save/status/activation ancestry and tests.
3. Firebase Rules/emulator tests; no deploy.
4. Admin models and service methods.
5. Admin District tab and State → District → City → Area cascade.
6. CSV preview and legacy-mapping report.
7. Full CI and review.
8. Only after approval, separately plan migration/backfill and release.

## Explicit safety boundaries
- Customer and Partner apps remain unchanged.
- No production Firestore writes, imports, backfill, activation, deployment, or merge in this step.
- Existing `zones`, `service_cities`, and saved addresses are not deleted or renamed.

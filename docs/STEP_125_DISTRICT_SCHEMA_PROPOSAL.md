# Step 125 — District Schema Proposal (Review Only)

Date: 2026-10-19
Status: **Proposal only — not approved for implementation**

## Goal
Make the service-location hierarchy explicit without silently treating a District as a City, while preserving existing Customer and Partner behavior until a coordinated migration is ready.

## Proposed hierarchy
`Country → State → District → Service City → Service Area`

- **Country:** national scope.
- **State:** state or union territory.
- **District:** administrative district/reference geography.
- **Service City:** a service-operating city or urban service unit within a district. This is a product/service concept and must not be assumed to equal an LGD district.
- **Service Area:** an explicitly reviewed polygon contained by its parent Service City. Activation requires verified geometry.
- **Locality:** optional address/search metadata, not a required customer booking step and not a required parent in this proposed service hierarchy.

## Proposed collection contract
Subject to Firebase/Admin review:
- `service_countries`
- `service_states`
- `service_districts`
- `service_cities`
- `service_areas`
- Existing `service_localities` remains optional and must not become a required booking dependency.
- `service_location_name_indexes` must define a unique, documented normalized-name key and parent-scope rules for every supported entity type.

Do not create production collections or write production documents from this proposal.

## Proposed parent references
- State: `countryId`
- District: `countryId`, `stateId`
- Service City: `countryId`, `stateId`, `districtId`
- Service Area: `countryId`, `stateId`, `districtId`, `cityId`

The final implementation must decide whether ancestor IDs are stored redundantly or derived from parent documents. If stored redundantly, callable validation must verify every reference is consistent and active; clients must not be trusted to supply authoritative ancestor values.

## Boundary rules
- District boundary/reference geometry and service-area geometry are separate concerns.
- A Service Area must have a verified polygon, valid ring structure, no self-intersections or prohibited repeated vertices, non-trivial area, and containment within its verified parent Service City boundary.
- Do not use a circular radius as a substitute for an area boundary.
- Define behavior for areas that cross district boundaries before enabling them; default proposal is to reject cross-parent geometry until an explicit multi-parent model exists.

## Admin and import UX
- Import/review filters: State → District → City → Area.
- Show source/reference IDs and names separately from service activation state.
- CSV import remains preview-only until validation, conflict handling, and approval are complete.
- Preview must report unknown parent IDs, duplicate normalized names, ambiguous matches, invalid geometry, and rows that would be skipped or updated.
- No automatic activation based only on a CSV row or imported boundary.

## Firebase security and callable requirements
- Extend collection allowlists and name-index parent-count/type maps together.
- Keep direct client writes to protected service-location collections and indexes denied.
- Callable payload schemas must strictly validate allowed fields, IDs, parent relationships, normalized names, and activation prerequisites.
- Boundary review and activation must be authorized, auditable, and performed server-side.
- Add Firestore Rules tests, callable schema tests, name-index tests, and geometry/parent-containment tests.
- Treat Rules and Functions changes as one coordinated rollout; passing CI does not prove production deployment.

## Compatibility and migration gates
1. Audit every Admin model/service/screen/query and all existing Firestore field assumptions.
2. Audit Customer booking/address lookup and Partner work-zone/zoneIds selection.
3. Define read compatibility for existing City documents and legacy Partner `zones` before changing writes.
4. Provide a dry-run migration report with counts, unresolved mappings, duplicate candidates, and rollback strategy.
5. Keep old reads supported until migrated data and both apps have verified compatibility.
6. Deploy only after review, CI, staging verification, and explicit release approval.
7. Do not delete legacy fields or collections in the same rollout that introduces the new hierarchy.

## Minimum acceptance test matrix
- Valid State → District → Service City → Service Area parent chain.
- Missing, inactive, or mismatched parent is rejected.
- Unsupported fields and unknown entity types are rejected.
- Duplicate names are handled according to documented parent scope.
- Name-index key is stable and collision/normalization behavior is tested.
- Invalid/self-intersecting/repeated-vertex/tiny-area polygons are rejected.
- Service Area outside parent Service City boundary is rejected.
- Unauthorized direct client writes are denied.
- Admin CSV preview reports errors without writing data.
- Existing Customer booking/address and Partner work-zone reads remain compatible.
- Rollback/read-compatibility path is documented and tested.

## Open decisions before implementation
- Authoritative source and version for District boundaries and identifiers.
- Whether Service City is mapped to an official urban body, a product-defined city, or both with separate identifiers.
- Unique-name scope and normalization rules per entity type.
- Handling of city/service areas that span administrative districts.
- Legacy `zones` mapping and migration ownership.
- Final Firestore document schemas and index definitions.

## Current status and restrictions
This is a design proposal only. No production schema changes, imports, activations, PR merge, deployment, or production writes were performed by this step. The CI checks recorded in Step 124 passed for the stated Firebase commit, but this does not authorize rollout.

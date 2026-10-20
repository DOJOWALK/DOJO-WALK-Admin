# Step 127 — Admin-First District Implementation Plan

Date: 2026-10-19
Branch: `step-119-boundary-geometry`
Status: **Audit and sequencing plan only; implementation not started**

## Confirmed current Admin source state
Reviewed on this branch:
- `lib/features/service_location/services/service_location_service.dart`
- `lib/features/service_location/models/service_location_models.dart`
- `lib/features/service_location/services/service_location_geometry.dart`

Findings:
1. The current hierarchy comments describe Country → State → City/District → Area/Sub-district → Locality/Village.
2. The service has collections for `service_countries`, `service_states`, `service_cities`, `service_areas`, `service_localities`, `service_location_imports`, and `service_location_boundaries`. No `service_districts` collection getter exists in the reviewed service.
3. The unique-name save path maps supported entity types only to country, state, city, area, and locality. City's current allowed fields are `countryId`, `stateId`, and `name`; Area's are `countryId`, `stateId`, `cityId`, and `name`. District is not an implemented entity type in this service.
4. The model defines `ServiceCity` against `service_cities` and describes it as “City / District”; this is a combined legacy concept, not a distinct District model.
5. Geometry helpers validate polygon rings and containment. The helpers alone do not establish that every activation/save path invokes all required checks or that server-side callable validation matches the client rules; those paths need tests.
6. This was a targeted source inspection, not a full repository/build audit.

## Admin-only execution sequence

### Gate A — Baseline and inventory
- Record current branch/head and existing CI checks.
- Inventory Service Location screens, routes/menu entries, model constructors, service methods, import preview flow, map/boundary workflow, and tests.
- Search all uses of `ServiceCity`, `service_cities`, `cityId`, `areaId`, and current callable payload types.
- Establish the current test/build baseline before editing.

### Gate B — Final Admin domain contract
Proposed target hierarchy:
`Country → State → District → Service City → Service Area`

- District is a distinct administrative/reference entity.
- Service City is the operational city/service unit; it must not be assumed to be identical to a District.
- Service Area is a serviceable polygon under a Service City.
- Locality remains optional metadata and must not become a mandatory booking/address selection level.
- Decide canonical IDs, parent relationships, activation fields, name-index scopes, and boundary ownership before coding.
- Keep existing city documents readable during transition.

### Gate C — Admin models and service layer
- Add a dedicated District model and explicit repository/service methods only after Gate B is approved.
- Update City model comments/types to mean Service City without silently reinterpreting old City/District records.
- Update dropdown data flow: State → District → Service City → Service Area.
- Clear downstream selections when an upstream selection changes.
- Validate parent IDs and active status before save/activation.
- Keep locality optional.
- Ensure save/update/deactivate/reparent rules are explicit and tested.

### Gate D — Boundary and activation workflow
- Preserve verified-boundary references and audit/provenance fields.
- Validate Service City geometry against the chosen authoritative boundary source.
- Validate each Service Area polygon against its verified parent Service City polygon.
- Reject malformed/self-intersecting/degenerate geometry and invalid parent containment.
- Activation must be blocked until required boundary review is complete.
- Verify the trusted server callable enforces the same invariants; client-side checks alone are insufficient.

### Gate E — CSV/import preview (no writes yet)
- Add State → District → City → Area filters to preview/review UX.
- Validate source IDs, parent IDs, duplicates, normalized names, missing fields, and boundary status.
- Report create/update/skip/conflict counts and ambiguous mappings.
- Keep import preview-only until a separate reviewed write implementation and rollback plan exist.
- Do not auto-activate records from imported data.

### Gate F — Admin tests and release gate
- Unit tests for models, parent selection/reset logic, allowlists, and name-index payloads.
- Geometry and containment tests for service city and area.
- Import-preview tests proving invalid rows are reported and no writes occur.
- Firebase emulator/integration tests for trusted callable contracts and Rules.
- Run format, static analysis, tests, and Admin Web build; record exact CI run outcomes.
- Keep changes in the existing draft PR until reviewed. No merge/deployment without explicit approval.

## Non-goals for this phase
- Do not change Customer or Partner repositories; they will be adapted after Admin is complete.
- Do not perform production imports, migrations, activation, or data writes.
- Do not deploy Firebase Rules or Functions.
- Do not delete or rename legacy collections/fields.

## Open decisions before implementation
- Authoritative source/version and identifier for Districts and boundaries.
- Whether Service City maps to an official municipal/urban unit, a product-defined service unit, or both with separate IDs.
- Name-index uniqueness scopes and normalization behavior for District and Service City.
- Policy for service cities/areas crossing administrative district boundaries.
- Whether ancestor IDs are stored redundantly or derived, and how the server validates consistency.
- Expected legacy City/District document migration and rollback strategy.

## Result
The current Admin implementation does not yet represent District as a distinct entity. The next code change should not be an isolated collection addition: it must follow a baseline inventory and an approved Admin contract, then update models/service/UI/import-preview/tests as a coherent change. Customer and Partner remain out of scope until Admin completion.

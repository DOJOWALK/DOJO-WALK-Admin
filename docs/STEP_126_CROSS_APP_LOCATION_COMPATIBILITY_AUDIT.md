# Step 126 — Cross-App Location Compatibility Audit

Date: 2026-10-19
Status: **Source audit recorded; no application code changed in this step**

## Scope reviewed
- Admin branch `step-119-boundary-geometry`: service-location service and model.
- Firebase branch `fix/location-index-import-rules`: `functions/src/location_name_index.ts`.
- Partner repository default branch: onboarding work-location and personal-details screens.
- Customer repository default branch: saved-address model and address service.

This is a targeted source audit, not a complete build/test of all four repositories.

## Findings

### 1. Admin currently models City/District as one level
- `ServiceLocationService` uses `service_countries`, `service_states`, `service_cities`, `service_areas`, and optional `service_localities`.
- The service maps the callable type `city` to `service_cities`; the save allowlist currently includes `countryId`, `stateId`, and `name` for City.
- The model comments label the existing model as “SERVICE CITY / DISTRICT” under `service_cities`.
- There is no separate District model in the reviewed service/model files.
- Implication: a separate District layer requires coordinated model, service, UI, query, and migration changes. It must not be treated as already implemented.

### 2. Firebase currently has no District entity type
- `SERVICE_LOCATION_COLLECTIONS` currently contains country, state, city, area, and locality.
- The canonical name-index parent counts are 0/1/2/3/4 respectively for those types.
- The current City payload allowlist supports `countryId` and `stateId`, but not `districtId`.
- Implication: adding District requires synchronized changes to collection/type allowlists, parent counts, payload validation, trusted callable ancestry checks, name-index construction, Firestore Rules, and tests. Admin-only changes would be incompatible.

### 3. Partner onboarding is coupled to legacy `zones`
- `lib/features/onboarding/screens/work_location_screen.dart` streams active documents from `zones`.
- It derives City and Area choices from the legacy `city` and `area` fields.
- It saves selected values to `walkers/{uid}`, including `city`, `state`, `area`, `zoneName`, `zoneNames`, `zones` (legacy document IDs), and `travelMode`.
- `personal_details_screen.dart` accepts and carries the legacy zone names/IDs.
- Implication: do not switch Partner to new service-location collections until a backward-compatible mapping/adapter and rule-compatible write path are tested.

### 4. Customer saved addresses are free-text snapshots
- `SavedAddress` stores textual `area`, `city`, `pincode`, address details, and optional latitude/longitude.
- `AddressService` stores addresses under `users/{uid}/addresses`.
- The model's booking snapshot preserves the textual area and city; the reviewed model has no service City, Area, or District ID fields.
- Implication: current customer address data cannot safely be assumed to map uniquely to a new District/City/Area record. Keep free-text address fields intact; any future IDs must be optional/additive until matching and migration are verified.

## Compatibility decision
Do not enable a new District hierarchy in production yet. The minimum safe path is:
1. Define canonical IDs and parent references for State → District → Service City → Service Area.
2. Keep Customer address text fields and Partner legacy `zones` reads/writes compatible during transition.
3. Add a reviewed mapping table/adapter from legacy zone IDs and free-text city/area values to canonical service-location IDs; report ambiguous and unmatched rows rather than guessing.
4. Implement Admin + Firebase changes together, with strict callable validation and rules tests.
5. Add emulator/integration tests for Partner onboarding writes and Customer booking/address snapshots.
6. Run a dry-run migration and review counts/ambiguities before any approved rollout.
7. Remove legacy compatibility only in a later, separately approved migration after all apps are verified.

## Known risks / not verified here
- This targeted review did not run Flutter builds, emulator tests, or live Firestore queries.
- It does not establish which Firestore Rules/Functions are deployed in production.
- It does not verify the full Customer booking flow or every query in all repositories.
- No PR merge, deployment, data migration, import, activation, or production write was performed.

## Result
The proposed District hierarchy is **not yet cross-app compatible**. Partner is coupled to legacy `zones`, Customer addresses are free-text, and both Admin and Firebase currently treat City/District as the existing combined City entity. A coordinated compatibility layer and tests are required before implementation rollout.

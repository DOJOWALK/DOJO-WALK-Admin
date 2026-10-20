# Step 128 — Admin Service Location Code Inventory

Date: 2026-10-19
Branch: `step-119-boundary-geometry`
Status: **Source inventory completed; no runtime code changed in this step**

## CI result for Step 127
Commit: `af34e92d5c592dcdb09d0e1e56793ad05b12e540`
- Service Location Geometry Tests — run 423 — **PASS**
- Admin Web Build Check (No Deploy) — run 447 — **PASS**
These are CI results for that commit; they do not certify future changes.

## Files reviewed
- `lib/features/service_location/screens/service_location_screen.dart`
- `lib/features/service_location/widgets/add_location_dialog.dart`
- `lib/features/service_location/models/service_location_models.dart`
- `lib/features/service_location/models/location_selection_state.dart`
- `lib/features/service_location/services/service_location_service.dart`
- `lib/features/service_location/services/service_location_boundary_service.dart`
- `lib/features/service_location/services/location_csv_preview_parser.dart`
- `lib/data/reference/india_locations/india_states.dart`
- `lib/data/reference/india_locations/india_districts.dart`
- `lib/data/reference/india_locations/india_sub_districts.dart`
- `lib/data/reference/india_locations/india_location_filters.dart`
- `test/reference_data_integrity_test.dart`
- `lib/screens/auth/auth_gate.dart`
- `pubspec.yaml`

## Findings

### Existing UI and selection model
1. The Service Location screen currently exposes tabs for Countries, States, Cities / Districts, Areas / Sub-districts, Localities / Villages, and Import History.
2. The add-location dialog's writable levels are Country, State, City / District, Area / Sub-district, and Locality / Village. There is no distinct District save flow.
3. `LocationSelectionState` tracks `countryId`, `stateId`, `cityId`, and `areaId`. It clears child selections when a parent is changed, but has no `districtId`.
4. The current Service Location service maps supported Firestore entity types to country, state, city, area, and locality. District is not a supported trusted-save entity in this client service.
5. Boundary management currently supports only `city` and `area` location types; locality does not require a polygon.

### Existing India reference data
1. The Admin repo contains local reference data for 36 State/UT records, 785 district records, and 7,151 sub-district records, as recorded in `docs/LOCATION_REFERENCE_CHECKSUMS.md`.
2. `india_location_filters.dart` already filters Districts by State LGD code and Sub-districts by the State + District LGD-code pair.
3. `test/reference_data_integrity_test.dart` validates counts, unique codes, and parent/name consistency for the reference datasets.
4. The reference filters are local reference helpers. This inventory did not find evidence that they are wired into the live Service Location add/edit flow.

### CSV import preview
1. `location_csv_preview_parser.dart` is Firebase-independent and read-only.
2. It expects State, District, City, and Area columns (case-insensitive; spaces/underscores/hyphens are normalized), retains source columns, and checks empty/duplicate headers, required columns/values, row column counts, and duplicate State/District/City/Area combinations.
3. Its `isSyntacticallyValid` flag means syntax/row validation only; it does not validate LGD codes against the reference dataset and is not approval to write or activate Firestore records.
4. Import history exists as a UI tab and Firestore collection, but no import write behavior should be inferred from the parser alone.

### Safety / authorization note
`lib/screens/auth/auth_gate.dart` currently checks only `admin_users/{uid}.isActive == true` before entering AdminShell. An earlier Admin audit documented that Firebase Rules may require a `super_admin` role for protected operations. Reconcile UI access and trusted server/rules policy before production rollout; do not assume the UI gate is the security boundary.

## Implementation decision
Do **not** add only a `districtId` field to the current dropdown state or send it in City payloads: the reviewed trusted backend contract currently rejects unsupported District schema/payload fields. That partial change would produce a UI that cannot safely save data.

The coherent implementation requires a coordinated Admin + Firebase contract:
1. Define distinct meanings/IDs for reference District and operational Service City.
2. Confirm server-owned collections, callable payload allowlists, parent validation, name-index uniqueness scope, activation and reparenting behavior.
3. Add model/service/UI support for District and link Service City to it without silently reinterpreting existing City/District documents.
4. Wire State → District → Service City → Area selection and reset behavior.
5. Validate import preview against reference LGD codes, but keep it read-only until an explicit, reviewed importer exists.
6. Add tests at each layer and run the Admin build and Firebase callable/Rules suites.

## Non-goals
- Customer and Partner repositories remain unchanged until Admin work is completed.
- No Firestore production writes, bulk imports, activation, Firebase deployment, or PR merge.
- Legacy Zones and existing location/address fields are preserved.

## Step result
The reference datasets and read-only CSV preview foundations exist, but the live Service Location hierarchy still combines City/District and is not yet a four-level State → District → City → Area operational flow. CI for the Step 127 documentation commit is green. Next implementation should begin only with the trusted schema contract, then a coherent vertical slice with tests.

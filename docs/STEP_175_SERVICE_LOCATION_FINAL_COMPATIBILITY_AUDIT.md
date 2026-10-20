# Step 175 — Service Location UI and Compatibility Final Audit

Date: 2026-10-18
Branch: `step-119-boundary-geometry`
Status: source-level audit; no schema, Firebase, production-data, activation, or deployment changes.

## UI and Add Location checks

Inspected:
- `lib/features/service_location/screens/service_location_screen.dart`
- `lib/features/service_location/widgets/add_location_dialog.dart`
- `lib/features/service_location/models/location_selection_state.dart`
- `lib/features/service_location/models/service_location_models.dart`

Findings:
- Add Location offers Country, State, City / District, Area / Sub-district, and Locality / Village.
- The current persisted model still represents the City/District choice as `ServiceCity`; there is no distinct `ServiceDistrict` model or `service_districts` collection in the audited model.
- Parent selection is represented by an immutable state helper; changing a parent clears descendant IDs, and the latest option list is used to reject stale IDs.
- The dialog writes new location records inactive and does not itself grant coverage activation.
- The Add Location dialog class/method closures and Save/Cancel actions are present in the reviewed branch source.

## CSV import boundary

Inspected `lib/features/service_location/services/location_csv_preview_parser.dart` and its tests.

- Parser requires separate State, District, City, and Area columns, independent of their order.
- It validates empty/missing/duplicate headers, malformed CSV, row field counts, missing values, and duplicate normalized paths.
- Parser is pure/read-only: it has no Firebase dependency and no database write calls.
- A syntactically valid preview is explicitly not permission to import or activate production service locations.

## Boundary and activation safety

Inspected the Service Location model/service and the existing Step 144 Firebase cross-audit.

- City and Area activation must continue through trusted callable Functions and requires a verified boundary.
- Area geometry must fit inside the verified parent City boundary.
- Boundary verification and service activation remain separate operations.
- Existing Firestore Rules and callable Functions encode Country → State → City → Area → Locality; the Admin model currently mirrors that existing hierarchy.

## Compatibility blocker — do not merge as a completed four-column implementation

The source CSV's State, District, City, and Area are four distinct fields, but the persisted service hierarchy currently combines City/District and attaches Area directly to that entity. The current preview parser does not write imported records, which is the safe behavior. Do not infer a mapping from names or create production entities from the CSV.

Before a District schema change, resolve the product gates recorded in `docs/STEP_145_DISTRICT_SCHEMA_COMPATIBILITY_IMPLEMENTATION_PLAN.md`:
1. Whether source City means an administrative City or a DOJO service grouping.
2. Whether a Service City has exactly one District parent.
3. Whether each service Area has exactly one Service City parent.
4. Whether imported records remain reference-only until an admin explicitly creates/verifies coverage.
5. The authoritative source/version and stable codes for every column.

## CI and PR

At the start of this audit, the previous fix commit `9dc2dadd4328fa7bd0ea005976b68e83b13b5d24` had successful Admin Web Build and Geometry Unit Tests checks. The report commit below is new; its own CI must be checked independently.

PR #7 remains Draft/open/unmerged. This audit does not authorize merging, deploying, importing production data, changing activation status, modifying legacy Zones, or migrating Partner/Customer apps.

# Step 141 — Admin District Hierarchy Integration

## Implemented
- Added the `ServiceDistrict` Firestore model for `service_districts`.
- Added District query, lookup, save and trusted status methods in `ServiceLocationService`.
- Added optional `districtId` support to the City model while preserving documents that do not have a District (legacy City).
- Added server-callable payload mapping for District and District-aware City save.
- City save validates that the District belongs to the selected Country and State.
- Existing City records cannot silently add, remove, or change District through ordinary save; the service surfaces a migration-required error.
- Add Location dialog now has separate District and City levels. The City dropdown is filtered by the selected District.
- Added selection-state tests ensuring changing State clears District/City/Area and changing District clears City/Area.

## Current limitations
- District records are created through the Add Location dialog, but the main Service Locations listing still needs a dedicated District list/status-management view.
- Existing Cities are not migrated automatically. Legacy Cities without `districtId` remain supported.
- No import, production write, deployment or merge was performed.

## CI
- Service Location Geometry Tests: [run 39168767076](https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39168767076)
- Admin Web Build Check (No Deploy): [run 39168767104](https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39168767104)

See the CI runs for final status; do not treat this step as fully validated until both complete successfully.

# Step 142 — District list and activation controls

## Implemented
- Added a dedicated **Districts** tab to Service Locations.
- Moved the existing City list into its own **Cities** tab.
- District list shows the District name, parent State/Country IDs and current service status.
- District activation/deactivation uses the trusted `setServiceLocationStatus` callable through `ServiceLocationService.setDistrictStatus`; activation checks active ancestors and deactivation is subject to active-descendant protections on the server.
- Add Location levels and tab indexes align: Country, State, District, City, Area, Locality, Import History.

## Validation
- Service Location Geometry Tests: [run 39169117702](https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39169117702)
- Admin Web Build Check (No Deploy): [run 39169117844](https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39169117844)

Check those runs for final completion status before considering this step validated.

## Safety / remaining
- Existing legacy Cities without `districtId` are not migrated automatically.
- No CSV import, production writes, deployment or PR merge was performed.
- The District list currently displays parent IDs rather than resolving State/Country display names; improving that presentation is a follow-up UI refinement.

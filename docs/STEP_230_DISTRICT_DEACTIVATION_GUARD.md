# Step 230 — District-Aware Deactivation Guard

## Change
Updated `ServiceLocationService._hasActiveChild` so a State cannot be deactivated while it has an active `service_districts` child. The existing direct City query is retained for legacy Cities without a District parent. Added a District branch that checks for active City children linked by `districtId`.

## Integration blocker discovered
The currently reviewed Firebase callable source on `feature/trusted-location-activation` does not list `district` in `setServiceLocationStatus` valid types, collection mapping, parent mapping, or child configuration. Admin's `setDistrictStatus` calls this callable with `locationType: district`, so District status changes would be rejected by that backend revision. This must be fixed and emulator-tested in the companion Firebase work before Admin can be considered merge-ready.

## Validation
- Admin Web Build Check (No Deploy) and focused geometry/reference-data tests are expected to run against this commit; results must be checked before claiming success.
- No production writes, migration, activation, deployment, or merge performed.
- Partner and Customer work remains deferred until Admin/Firebase schema compatibility is finalized.

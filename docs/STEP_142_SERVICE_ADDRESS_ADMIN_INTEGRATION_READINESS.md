# DOJO WALK Admin — Step 142: Service Address Integration Readiness

Date: 2026-10-18
Repository: `dojoplatform2026/DOJO-WALK-Admin`
Branch: `step-119-boundary-geometry`
Status: Review/audit only; no merge, deployment, import, or activation.

## User-approved delivery order

1. Finish and review Service Address / Service Locations in Admin.
2. Merge the approved Admin work.
3. Only after Admin is complete, migrate Partner.
4. Then integrate Customer.

No Partner or Customer migration is part of this step.

## Confirmed Admin implementation

- The review branch has `lib/features/service_location/screens/service_location_screen.dart`, registered as the Service Locations screen in the current review branch's change set.
- The screen provides Countries, States, Cities/Districts, Areas/Sub-districts, Localities/Villages and Import History tabs, an Add Location action, search, and an active-boundary map preview.
- `ServiceLocationService` uses the `service_countries`, `service_states`, `service_cities`, `service_areas`, `service_localities`, `service_location_imports`, `service_location_name_indexes`, and `service_location_boundaries` collections.
- City and Area activation is routed through trusted callable Functions. Verified boundary and activation are distinct operations.
- CSV support currently validates/previews data; the Admin PR description explicitly says end-to-end import writes are not implemented.
- The Admin PR #7 remains Draft/open/unmerged. Its PR notes that legacy Zones are not modified and that the current City/District hierarchy is not yet compatible with a CSV that separately supplies State, District, City and Area.

## Blocking decisions and implementation gates

1. **Schema decision:** Current hierarchy is Country → State → City/District → Area/Sub-district → optional Locality. The proposed alternative is Country → State → District → Service City → Service Area. Do not silently treat a district as a service city or an LGD sub-district as a service area.
2. **Address semantics:** Customer-entered house/flat, society, landmark and pickup instructions should remain booking-address data, separate from service-coverage polygons. Locality should not be mandatory when the customer supplies a free-text address.
3. **Import writes:** Keep import preview-only until the hierarchy, LGD source snapshot, duplicate/parent resolution, staging, idempotency and rollback strategy are implemented and tested.
4. **Boundary quality:** Only reviewed, valid polygons may be verified and activated. Names, radius circles or administrative labels alone do not prove service coverage.
5. **Backend parity:** Firebase Rules and trusted callables must enforce the same schema and activation rules; client-only changes are insufficient.
6. **Existing records:** Preserve legacy `zones` and existing service records during Admin completion. Any migration must be separately tested and approved.

## Next Admin-only work

- Reconcile the schema proposal against the current models, Add Location dialog, screen tabs, Firestore Rules and callable Functions.
- Record each mismatch as a concrete implementation/test item.
- Implement the approved schema end-to-end in Admin and Firebase review branches, run emulator tests, then run the full Admin analyze/test/Web-build workflow.
- Keep the PR Draft until all gates are resolved and reviewed.

## Release safety

This step changes documentation only. No code behavior changed. No PR was merged, no deployment was triggered, no production data was imported, and no service location was activated.

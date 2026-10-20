# Step 176 — Admin ↔ Firebase Service Location Contract Audit

Date: 2026-10-18
Admin branch: `step-119-boundary-geometry`
Firebase review branch inspected: `step-138-partner-submission-negative-tests`
Scope: read-only cross-repository source audit; no schema or runtime changes.

## Files reviewed

Admin:
- `lib/features/service_location/services/service_location_service.dart`
- `lib/features/service_location/models/service_location_models.dart`
- `lib/features/service_location/widgets/add_location_dialog.dart`
- `lib/features/service_location/services/location_csv_preview_parser.dart`

Firebase:
- `firestore.rules`
- `functions/src/index.ts`

## Contract checks

| Check | Result | Evidence |
|---|---|---|
| Admin uses the expected service collections | PASS | Country, State, City, Area, Locality, boundary, import, and name-index collection names match the current Rules/Functions design. |
| New records are created inactive | PASS | Add Location passes inactive values; Rules require inactive creation for service-location documents. |
| City parent validation | PASS | Admin checks Country/State references; Rules constrain the existing City schema to `countryId` and `stateId`. |
| Area parent validation | PASS | Admin checks parent City and matching Country/State; Rules use the current `cityId` parent contract. |
| Locality parent validation | PASS | Admin checks the selected Area hierarchy; current Rules expect `areaId`, `cityId`, `stateId`, and `countryId`. |
| Trusted activation callable names | PASS | Admin calls `activateServiceLocation` and `setServiceLocationStatus`; the inspected Functions source defines the trusted service-location activation/status flow. |
| Boundary verification | PASS | Admin boundary review uses the callable flow; Firebase review requires active `super_admin`, a pending owned boundary, source metadata and valid polygon geometry. |
| Area geometry containment | PASS | Firebase verifies Area geometry against the verified parent City polygon before verification/activation. |
| Separate District entity | BLOCKED / NOT IMPLEMENTED | Existing collections and rules still represent City directly under State; no `service_districts` contract is present in the reviewed Admin model. |
| Four-column CSV production import | NOT ENABLED | Parser validates State/District/City/Area as preview-only input. It has no Firebase dependency and must not be treated as production import approval. |

## Compatibility decision

The current Admin write contract is compatible with the *existing* Firebase hierarchy. It is **not yet a complete implementation** of the desired separate State → District → Service City → Service Area hierarchy.

Do not add a District parent field or collection on only one side. Before implementation, resolve the five product/source gates in `docs/STEP_145_DISTRICT_SCHEMA_COMPATIBILITY_IMPLEMENTATION_PLAN.md`, then update Admin, Firestore Rules, callable Functions and emulator tests together. Keep legacy documents readable and leave legacy `zones` unchanged.

## CI snapshot

For the Step 175 report commit `8ee7729aedb5787cfe9c61132aa58a60a8336b6c`:
- Geometry unit tests: success.
- Admin Web Build: success (run #39076928720).
- These checks validate the current code branch, not District-schema readiness.

## Guardrails

This audit did not merge PR #7, deploy Functions or Rules, write production data, activate/deactivate coverage, change CSV import behavior, or migrate Partner/Customer apps. PR #7 remains Draft/open pending the remaining product and release gates.

# Step 132 — District-Aware Name Index Contract

Date: 2026-10-19
Repository: `DOJO-WALK-Firebase`
Branch: `fix/location-index-import-rules`
Final commit: `eee74fa88122fb5586e1e13388cf5b6a735ceadd`

## Added
- `functions/src/district_name_index_contract.ts`
- `functions/test/district_name_index_contract.test.cjs`

## Contract
The additive District-aware index tuple is:
- District: `[service_districts, [countryId, stateId], normalizedName]`
- City: `[service_cities, [countryId, stateId, districtId], normalizedName]`
- Area: `[service_areas, [countryId, stateId, districtId, cityId], normalizedName]`
- Locality: `[service_localities, [countryId, stateId, districtId, cityId, areaId], normalizedName]`

Parent IDs are trimmed and constrained to safe IDs. Names use the same trim/lowercase/whitespace normalization and SHA-256 JSON tuple format as the existing index helper.

## Backward compatibility
The existing `location_name_index.ts` and trusted callable have not been changed. Legacy City index tuples continue to use Country + State; legacy Area and Locality tuples remain untouched. The new helper is not yet wired to writes because the Admin Dart index calculation and transactional parent verification must be migrated together.

## CI
- Trusted Location Geometry and Callable Tests — run 228 — **PASS**.
- Test Firestore Security Rules — run 239 — **PASS**.

## Remaining
The next step is a tested transactional callable integration and rules coverage. This helper alone does not enable District CRUD and does not perform Firestore writes.
No merge, deploy, production import, or Customer/Partner changes.

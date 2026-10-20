# DOJO WALK — Step 229: Direct Write and Import Path Audit

## Scope inspected
- lib/features/service_location/services/service_location_service.dart
- lib/features/service_location/screens/service_location_screen.dart
- lib/features/service_location/widgets/add_location_dialog.dart
- lib/features/service_location/services/service_location_boundary_service.dart
- lib/features/service_location/services/lgd_staging_parser.dart
- lib/features/service_location/services/location_csv_preview_parser.dart

## Findings
1. The shared save helper in service_location_service.dart calls saveServiceLocationWithNameIndex; its previous client transaction/index write was removed in Step 228.
2. The Admin screen contains no direct saveCountry/saveState/saveCity/saveArea/saveLocality/saveImport calls and no direct service-location collection writes were found in the inspected screen source.
3. saveImport writes only a record to service_location_imports; it is not a bulk location importer and does not write service_location_name_indexes.
4. service_location_boundary_service.dart still writes boundary records directly in transactions. These are separate boundary-document operations and are not name-index writes; verification/review uses the trusted review callable.
5. LGD staging and CSV preview parser files parse and validate input data; they do not persist service location documents.
6. The old _nameIndexes getter, _nameIndexId, _normalizeName, and imports used solely by the former client-side index transaction may now be unused and should be removed in a separate cleanup after static analysis confirms there are no references.

## Verification limits
- This was a source-level audit of the named files on branch step-119-boundary-geometry; it is not proof about every file in other repositories or deployed rules.
- Admin Flutter build/tests have not been executed in this step.
- No evidence of a separate bulk location-write/import path was found in the inspected Service Location feature, but a repository-wide static search/build remains needed.
- Do not tighten direct name-index Firestore Rules until Admin build/tests pass and all client/import paths are checked.
- No PR merge or deployment occurred.
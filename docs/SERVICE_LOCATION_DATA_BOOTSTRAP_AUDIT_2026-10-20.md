# Service Location Data Bootstrap Audit

Date: 2026-10-20
Branch: `feature/service-locations-premium-3d-ui`

## Findings

1. The Admin Country list reads Firestore collection `service_countries` using `watchCountries()` and `orderBy('name')`. The empty-state is shown only when the query succeeds and returns zero matching documents. Query/permission failures are rendered separately as `Unable to load countries`.
2. The current Firebase rules allow `get/list` on `service_countries` only for an active `super_admin`. Client create/update/delete is deliberately denied.
3. Admin writes named location records through the trusted callable `saveServiceLocationWithNameIndex`; this preserves server-owned name-index integrity and creates new locations inactive. The callable is exported in Firebase Functions source.
4. The repository contains bundled India LGD reference files for 36 State/UT records, 785 district records and 7,151 sub-district records. Those files are local reference data, not proof that equivalent Firestore documents have been imported.
5. The current CSV preview/parser and planner are deliberately read-only. The CSV workflow does not bulk-write country/state/district/city/area records, and Firebase Functions currently exports no dedicated bulk location-data import callable. The import-run callable manages import-run state; it is not a location hierarchy importer.

## Conclusion

The code can show an empty Country list when the Firestore query returns zero documents. The repository source alone cannot inspect live Firestore contents, so this audit does not claim that the production collection was queried directly. The most likely setup gap is the absence of a completed trusted bootstrap/import path for the location master; confirm the live collection in Firebase Console before concluding the exact runtime cause.

## Security constraints to preserve

- Do not relax Firestore rules to allow browser-side writes to hierarchy records.
- Do not auto-activate imported locations or create fabricated boundaries.
- Keep name-index creation and hierarchy writes atomic in trusted server code.
- Import records as inactive drafts; city/area activation must still require reviewed verified polygons.
- Before a bulk import, preview counts, validate parent chains and duplicate names/codes, produce a deterministic fingerprint, and require explicit operator confirmation.

## Next implementation

Build a trusted, idempotent India reference-data import flow that stages and validates State/UT, District, and Sub-district data, reports unmatched/duplicate rows, writes hierarchy records and name indexes transactionally/batched through Firebase Functions, and leaves service activation off. City/Area boundaries remain a separate verified workflow.

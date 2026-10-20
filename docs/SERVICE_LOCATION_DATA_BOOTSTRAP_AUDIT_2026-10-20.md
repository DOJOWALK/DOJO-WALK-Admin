# Service Location Data Bootstrap Audit

Date: 2026-10-20
Branch: `feature/service-locations-premium-3d-ui`

## Findings

1. The Admin Country list reads Firestore collection `service_countries` using `watchCountries()` and `orderBy('name')`. The empty-state is shown only when the query succeeds and returns zero matching documents. Query/permission failures are rendered separately as `Unable to load countries`.
2. The current Firebase rules allow `get/list` on `service_countries` only for an active `super_admin`. Client create/update/delete is deliberately denied.
3. Admin writes named location records through the trusted callable `saveServiceLocationWithNameIndex`; this preserves server-owned name-index integrity and creates new locations inactive. The callable is exported in Firebase Functions source.
4. The repository contains bundled India LGD reference files for 36 State/UT records, 785 district records and 7,151 sub-district records. Those files are local reference data, not proof that equivalent Firestore documents have been imported.
5. Correction after deeper trace: an Admin CSV import orchestrator DOES exist in `LocationCsvImportService.importPreview()`. It validates the CSV, builds a deterministic State → District → City → Area plan, limits a run to 300 planned nodes, records an immutable run plan via `manageServiceLocationImportRun`, and writes each hierarchy node through `saveServiceLocationWithNameIndex`. New records are inactive. This is a client-orchestrated bounded import using trusted per-record writes, not a single server-side bulk-write callable. The CSV preview by itself remains read-only until the operator explicitly confirms import.

## Conclusion

The code can show an empty Country list when the Firestore query returns zero documents. The repository source alone cannot inspect live Firestore contents, so this audit does not claim that the production collection was queried directly. A CSV import path exists for State/District/City/Area, but it requires an already active parent Country and does not seed the Country itself. The likely first-time setup gap is therefore the Country bootstrap and/or the absence of an operator-confirmed completed import run. Confirm the live collection and run history in Firebase Console before concluding the exact runtime cause.

## Security constraints to preserve

- Do not relax Firestore rules to allow browser-side writes to hierarchy records.
- Do not auto-activate imported locations or create fabricated boundaries.
- Keep name-index creation and hierarchy writes atomic in trusted server code.
- Import records as inactive drafts; city/area activation must still require reviewed verified polygons.
- Before a bulk import, preview counts, validate parent chains and duplicate names/codes, produce a deterministic fingerprint, and require explicit operator confirmation.

## Next implementation

1. Confirm or create the `India (IN)` Country through the Admin flow, keep it inactive until an authorized admin reviews it, then activate it using the trusted status workflow.
2. Prepare a CSV with the required `State, District, City, Area` columns. Bundled Dart LGD files are reference assets, not automatically imported Firestore records; map LGD Sub-districts to the chosen Area schema explicitly and do not invent City values or boundaries.
3. Run a small pilot import (within the 300-node limit), retain the run ID and fingerprint, reconcile the recorded plan and imported records, then expand in reviewed chunks.
4. Keep City/Area service activation separate until actual polygons are reviewed and verified.

The current import orchestrator writes records one-by-one through the trusted callable. If scale/performance becomes a problem, a dedicated server-side batch importer can be designed later; it is not a prerequisite for the existing bounded CSV path.

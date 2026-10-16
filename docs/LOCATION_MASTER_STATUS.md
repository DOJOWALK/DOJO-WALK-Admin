# DOJO WALK Location Master — Project Status

## Latest CI result — Step 41 PASS; Step 42 containment validation pending

- [x] Step 38 City hierarchy guard tests passed in GitHub Actions run [38973476430](https://github.com/dojoplatform2026/dojo-admin/actions/runs/38973476430), including Flutter analysis/tests, Firestore Emulator persistence smoke test, and Flutter Web release build.
- [x] Added a State reparent guard: an existing State cannot change Country while any child City exists.
- [x] Added a regression test confirming the failed move leaves the State's original Country unchanged.
- [x] Step 39 CI passed in GitHub Actions run [38973920698](https://github.com/dojoplatform2026/dojo-admin/actions/runs/38973920698), including Python tests, Flutter analyze/tests, Firestore Emulator persistence smoke test, and Flutter Web release build.
- [ ] Official LGD row-level reconciliation and verified contiguous geographic boundaries remain pending; production import/activation remains blocked.
- [x] Details recorded in [Step 39 report](LOCATION_MASTER_STEP_39.md).


## Step 42 — Parent/child polygon containment: CI pending

- [x] Added a planar polygon containment check to the boundary model. It rejects invalid polygons, child vertices outside the parent, and proper child/parent edge crossings; touching/shared edges are allowed.
- [x] Added tests for an Area polygon inside a City, an Area extending outside the City, and invalid polygon input.
- [ ] Full CI validation pending in [workflow 38975696435](https://github.com/dojoplatform2026/dojo-admin/actions/runs/38975696435) and [workflow 38975692845](https://github.com/dojoplatform2026/dojo-admin/actions/runs/38975692845).
- [ ] This is planar geometry only and is not yet wired into the save/verification lifecycle. It does not prove official provenance, full locality hierarchy integration, geodesic correctness, or real-world boundary accuracy. Production import/activation remains blocked.

## Step 43 — Verification lifecycle containment guard: CI PASS

- [x] `markVerified()` now checks Area boundaries against the referenced verified City polygon.
- [x] `markVerified()` now checks submitted Locality polygons against the referenced verified Area polygon.
- [x] Parent location and boundary references are checked inside the same Firestore transaction before writing the verified status.
- [x] CI for commit `49ee3421ecfb6be9e7684cd52df63e442c4225d1` passed: [workflow](https://github.com/dojoplatform2026/dojo-admin/actions/runs/38975978339). Dart/Flutter analyze, unit tests, Firestore Emulator persistence smoke test, reference-data tests, and Flutter Web build all passed.
- [ ] Dedicated Emulator-backed integration tests for the new verification guard remain to be added; the current Emulator smoke test is not a substitute. Production activation/import remains blocked.

Last updated: 2026-10-17

## Step 41 — Imported coordinate validation: PASS

- [x] Initial CI exposed invalid constant `GeoPoint` test fixtures; `flutter analyze` failed before tests ran.
- [x] Updated `ServiceLocationBoundary.fromMap()` to validate finite latitude/longitude ranges before constructing Firestore `GeoPoint` objects, safely skipping malformed imported points.
- [x] Updated regression tests to exercise invalid raw imported map coordinates.
- [x] Full validation passed in [workflow 38975166322](https://github.com/dojoplatform2026/dojo-admin/actions/runs/38975166322) and [workflow 38975162943](https://github.com/dojoplatform2026/dojo-admin/actions/runs/38975162943).
- [ ] These tests do not prove official boundary source, contiguity, or geographic containment.
- [ ] Official LGD row-level reconciliation and authoritative polygon verification remain pending; production import/activation remains blocked.

## Step 40 — Boundary-required activation tests: PASS

- [x] City activation rejected without a verified polygon boundary; failed activation leaves City inactive.
- [x] Area activation rejected without a verified polygon boundary; failed activation leaves Area inactive.
- [x] Full CI validation passed in [run 38974326242](https://github.com/dojoplatform2026/dojo-admin/actions/runs/38974326242).
- [ ] Official LGD row-level reconciliation, authoritative contiguous polygon validation, and geographic containment remain pending. No production import/activation.

## Step 40 — Boundary-required activation tests: CI pending

- [x] Added regression tests that City and Area activation are rejected without a verified polygon boundary.
- [x] Tests assert the failed activation leaves the location inactive.
- [x] Step 40 full validation passed in [GitHub Actions run 38974326242](https://github.com/dojoplatform2026/dojo-admin/actions/runs/38974326242), including Python tests, Flutter analyze/tests, Firestore Emulator persistence smoke test, and Flutter Web release build.
- [ ] These tests cover the activation gate, not official/contiguous polygon geometry or geographic containment.
- [ ] Official LGD row-level reconciliation and authoritative polygon verification remain pending; production import/activation remains blocked.

## Step 39 — State reparent guard: PASS

- [x] Existing State cannot be moved to another Country while any child City exists (active or inactive).
- [x] Regression test verifies rejected move preserves original `countryId`.
- [x] Full validation passed in [GitHub Actions run 38973920698](https://github.com/dojoplatform2026/dojo-admin/actions/runs/38973920698).
- [ ] Official LGD row-level reconciliation, authoritative contiguous polygon validation, and integration/API review remain pending. No production import or activation.

## Latest CI result (Step 23) — PASS

- [x] GitHub Actions run `38958559004` passed on commit `5fd05c561fe1ba18bc7442c17c86ee81360f6f81`; duplicate run `38958552086` also passed.
- [x] The `validate` job completed successfully, including Flutter analysis/tests, Firestore Emulator REST smoke test, and Flutter Web release build.
- [x] Emulator smoke test checks save/reload/clear behavior for test State, District, and Sub-district LGD-code fields without using production Firebase.
- [x] Documented the verified result and next gates in `docs/LOCATION_MASTER_CI_PASS_AND_NEXT_GATE.md`.
- [ ] Full end-to-end Flutter service-class ↔ Firestore Emulator coverage is still separate; the REST smoke test alone does not prove that path.
- [ ] Official latest LGD export reconciliation remains pending. Local counts (36 States/UTs, 785 districts, 7,151 sub-districts) are not proof of current official completeness.
- [ ] Geographic boundary verification and remaining integration/API review remain pending. PR #6 must stay open until those gates pass.

## Step 24A — Official LGD source discovery (2026-10-17)

- [x] Checked Ministry of Panchayati Raj LGD overview and official OGD catalog metadata.
- [x] Official OGD LGD catalog showed updated 2026-10-15; official Districts resource showed updated 2026-10-08.
- [x] Attempted the catalog ZIP link; it returned HTTP 503 in this check, so no export contents were obtained.
- [x] Confirmed the LGD portal's normal download flow includes CAPTCHA; do not bypass it.
- [ ] Record-by-record official reconciliation is still blocked until the official export is obtained.
- [ ] Do not replace Dart data based only on catalog dates or third-party extracts.
- [x] Details saved in `docs/OFFICIAL_LGD_SOURCE_DISCOVERY_2026-10-17.md`.

## Step 24B — Cross-check lead recorded (not official reconciliation)

- [x] Recorded third-party metadata for an LGD-derived dataset dated 2026-10-12 as a comparison lead only.
- [x] Noted advertised metadata counts: 35 distinct state codes, 781 distinct district codes, and 7,081 distinct sub-district codes across a 677,673-row village dataset.
- [x] Explicitly marked these as non-authoritative metadata; no record-level download/comparison was completed and no Dart reference data was changed.
- [x] Saved procedure and caveats in `docs/LGD_CROSSCHECK_LEAD_2026-10-17.md`.
- [ ] Obtain an official downloadable export, calculate its checksum, and compare records/code parent chains before any reference-data edit.
- [ ] Keep production import and activation blocked pending official reconciliation and polygon validation.

## Step 24C — Ministry annual-report count cross-check

- [x] Found the Ministry of Panchayati Raj Annual Report 2025–2026, section 10.9/page 78; its LGD dashboard reports figures as of 2025-12-31.
- [x] Compared those historical totals against the local snapshot: States/UTs 36 vs 36; Districts 785 vs 778; Sub-districts 7,151 vs 7,071.
- [x] Recorded the differences (+7 districts, +80 sub-districts) as reconciliation flags only; totals do not identify individual incorrect records.
- [x] Saved the source and comparison in `docs/OFFICIAL_LGD_COUNT_CROSSCHECK_2025-12-31.md`.
- [ ] Obtain current live LGD exports and reconcile every code/name/parent relationship. The Ministry dashboard is a historical aggregate, not a substitute for row-level exports.
- [ ] Keep PR #6, production import, and service activation blocked until data differences and polygon boundaries are verified.

## Current status

## Firestore Emulator integration coverage (Step 18)

- [x] Added `test/service_location_firestore_emulator_test.dart` to exercise actual Firestore writes and reads for State, District, and Sub-district LGD codes.
- [x] The integration test also saves each record again without its LGD code and asserts that the previous code is no longer returned by the model.
- [x] Updated `.github/workflows/validate_flutter_web.yml` to run unit tests and launch the Firestore Emulator for this integration test. This is emulator-only; it does not connect to production Firebase or deploy anything.
- [x] The emulator workflow passed on commit `5fd05c5` (run `38958559004`).
- [ ] A production Firestore round-trip has intentionally not been run; no production records were changed.
- [ ] Official LGD source reconciliation and geographic boundary verification remain pending.

## LGD code persistence and backward compatibility (Step 16)

- [x] Service save-path audit found that merge writes could preserve an old `lgdCode` when the incoming model had no code; State, District, and Sub-district save maps now explicitly write the nullable field so stale codes can be cleared. Commit `4ea5535ae00a38d38a08338d008c159754c7ea9f`.
- [x] Latest CI verified the save-path fix: commit `f35ee9a` completed successfully (analysis, tests, Flutter Web release build). Emulator-backed Firestore integration coverage is still pending.
- [x] Added model tests for State (integer LGD code), District and Sub-district (string LGD codes).
- [x] Tests cover serialization/reload, copyWith retention, omission of null codes, and loading legacy records that have no lgdCode field.
- [x] Confirmed model tests and Flutter Web release build pass in GitHub Actions on latest commit `f35ee9a` (run `38956005813`).
- [ ] This is model-level serialization coverage, not a live Firestore round-trip test. A Firebase emulator/integration test is still needed before claiming end-to-end persistence.
- [ ] Official LGD reconciliation, geographic boundary verification, and production import remain pending.


- [x] Added an optional India Sub-district reference dropdown for Area/Sub-district records. The options are filtered by both the selected State LGD code and the selected District LGD code.
- [x] Added optional `lgdCode` support to `ServiceArea` parsing/serialization; a selected sub-district's code is saved with the Area record.
- [x] Reset the Sub-district reference selection when its State, District, or location type parent changes to prevent stale code/name combinations.
- [x] Latest GitHub Actions passed for State → District → Sub-district UI/model changes on commit `f35ee9a`; emulator-backed Firestore verification remains separate.
- [ ] The sub-district list is based on the restored 2024-10-07 snapshot; current official LGD reconciliation and geographic boundary verification are still required.


- [x] Added an optional India District reference selector to the Add Location dialog. Its list filters district records by the selected saved State/UT LGD code.
- [x] Added optional `lgdCode` support to `ServiceCity` serialization and parsing; the selected district code is saved with a newly created city/district record.
- [x] State and District picker changes are included in the successful CI validation on commit `f35ee9a`.
- [ ] If a saved State has no LGD code, the dialog leaves manual district-name entry available; reference selection is not silently guessed.

- [x] Added an India State/UT reference dropdown to the Add Location dialog for State records, using the restored `india_states.dart` list.
- [x] Added optional `lgdCode` support to `ServiceState` model parsing/serialization and persisted the code when selected; existing records without this field remain compatible.
- [x] State picker/model changes passed the latest GitHub Actions validation on commit `f35ee9a`.
- [ ] State reference records are restored user-provided LGD-derived data; official live LGD reconciliation is still required before production imports.

- [x] Previous structural audit recorded in the ChatGPT Library.
- [x] Boundary dialog metadata omission fixed in commit `c572371cfd74a9888a66b2e51e7af1e20c627b62`.
- [x] Project file structure documented in `docs/PROJECT_FILE_STRUCTURE.md`.
- [x] Generated Dart reference files located, record counts verified, and SHA-256 integrity manifest committed at `docs/LOCATION_REFERENCE_CHECKSUMS.md`.
- [x] Expected repository paths checked; all three generated reference files have now been restored on the integration branch.
- [x] Restored the exact three generated India reference Dart files to the proposed integration branch; byte sizes and Git blob SHAs verified.
- [ ] Review the integration pull request; merge only after import/API review and build validation.
- [x] Static repository code search completed for `IndiaState`, `IndiaDistrict`, `IndiaSubDistrict`, and their list identifiers; no existing usages were found on `main`.
- [x] API/type review started: state LGD IDs are `int`, while district and sub-district state-code fields are `String`; callers must convert/compare codes deliberately.
- [ ] Finish sub-district API review and add integration tests for State → District → Sub-district filtering. Current tests validate reference-data integrity; UI/API filtering behavior is not yet covered.
- [x] Added a separate non-deploying GitHub Actions validation workflow at `.github/workflows/validate_flutter_web.yml` (runs `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter build web --release` on restore-branch pushes and PRs targeting main).
- [x] Initial validation found three unused-code warnings and six deprecated DropdownButtonFormField `value` usages. The unused import/helper warnings were removed; the six dropdowns were updated to `initialValue` in the following commits.
- [x] Removed the three unused-code warnings and updated all six deprecated dropdown usages to `initialValue`.
- [x] Latest run `38950826261` confirmed `flutter analyze` passes with `No issues found!`.
- [x] Validation workflow adjusted in commit `1a1309a1d151f0d65f941539f981ffe7bcca0d19`: this repository currently has no `test/` directory, so the test step now reports a clear skip instead of failing before the web build.
- [x] GitHub Actions PR validation run `38951129623` completed successfully on commit `6e9ae122fdd6a0b8e25e170da94d1e62a0080d09`: dependencies installed, `flutter analyze` passed, conditional test step passed by skipping because `test/` is absent, and `flutter build web --release` passed. This is a non-deploying CI build, not a Firebase deployment.
- [ ] Reconcile reference counts and records against a current official LGD snapshot.
- [x] State record-count check corrected: the file contains **36 records with 36 unique LGD codes** (the 38 seen previously were the first and last code values, not the record count). The header's 28 States + 8 UTs = 36 is internally consistent. Codes 37/38 are included in the 36 records.
- [x] Parent integrity audit on the restored branch: 785 districts / 785 unique district codes; 7,151 sub-districts / 7,151 unique sub-district codes; no missing state parents, no state-name mismatches, no missing sub-district district parents, and no sub-district/district parent-name mismatches detected in the supplied files.
- [x] Official-source discovery started: the Government of India OGD catalog for LGD lists the Districts dataset as updated 2026-10-08 and the overall LGD catalog as updated 2026-10-09. This confirms a newer official catalog exists, but the actual latest export has not yet been downloaded and compared record-by-record; freshness reconciliation remains pending.
- [x] UP/NCR parent-chain spot-check completed for Gautam Buddha Nagar, Ghaziabad, Hapur, Meerut, Bulandshahr, Baghpat, Shamli, and Muzaffarnagar: every checked sub-district points to the expected UP state code and district code/name in the supplied snapshot.
- [ ] Complete full NCR review, including current official district coverage and map-boundary validation.
- [ ] Verify location boundaries and activation rules in the admin UI.
- [ ] Do not import reference data into production Firebase until the above checks pass.

## Reference data currently in the Library

Folder: `/DOJO WALK Location Master/02_GENERATED_DART/`

| File | Previous audited count | File size | Top-level declaration |
|---|---:|---:|---|
| `india_states.dart` | 36 State/UT records | 6,871 bytes | `IndiaState`, `indiaStates` |
| `india_districts.dart` | 785 district records | 215,355 bytes | `IndiaDistrict`, `indiaDistricts` |
| `india_sub_districts.dart` | 7,151 sub-district records | 1,830,733 bytes | `IndiaSubDistrict`, `indiaSubDistricts` |

These are the previously audited local counts. They are **not** a claim that the records have been reconciled against the latest official LGD export. The source snapshot currently available for sub-districts is dated 2024-10-07, and a fresh official-source reconciliation remains pending.

## Restore and compatibility check

Integrity manifest: [`docs/LOCATION_REFERENCE_CHECKSUMS.md`](LOCATION_REFERENCE_CHECKSUMS.md). It records measured counts, byte sizes, and SHA-256 hashes for the exact Library files. This makes it possible to verify byte-for-byte restoration.

The following files now exist on the integration branch `restore/india-location-reference-data` and are not yet present on `main`:

- `lib/data/reference/india_locations/india_states.dart`
- `lib/data/reference/india_locations/india_districts.dart`
- `lib/data/reference/india_locations/india_sub_districts.dart`

The generated files were restored byte-for-byte from the Library. The GitHub blob SHAs and byte sizes were verified against the new branch. Their top-level names are `IndiaState/indiaStates`, `IndiaDistrict/indiaDistricts`, and `IndiaSubDistrict/indiaSubDistricts`. Repository code search did not return usages of those identifiers. The state model uses an integer `lgdCode`, whereas district records use a string `stateCode`; integration must normalize the comparison intentionally. The validation-only GitHub Actions run `38951129623` completed successfully: dependency resolution, `flutter analyze`, and the Flutter web release build passed. At that point, the test step was skipped because no `test/` directory existed. Reference-data integrity tests have now been expanded to include sub-districts; the latest CI result must be checked before treating them as passing. The workflow does not deploy to Firebase. Do not merge until official-data reconciliation and integration/API review are complete. A follow-up parser audit confirmed 36 state records with 36 unique LGD codes; the earlier “38 records” warning was incorrect and has been corrected. The hierarchy audit found no missing or mismatched parent codes/names across the restored state, district, and sub-district datasets. Current official LGD record-by-record reconciliation remains pending.

Do not recreate the 7,151 records by hand or replace them with sample/partial data. Preserve the exact Library files and official codes when restoring.

## Hierarchy integrity audit (restored branch)

Static parsing of the restored files produced these results:

- States/UTs: 36 records, 36 unique LGD codes.
- Districts: 785 records, 785 unique district codes.
- Sub-districts: 7,151 records, 7,151 unique sub-district codes.
- District state parents: no missing state codes and no state-name mismatches found.
- Sub-district district parents: no missing `(stateCode, districtCode)` parent pairs and no district-name mismatches found.
- Uttar Pradesh: 75 district records and 350 sub-district records. NCR spot-check: Gautam Buddha Nagar (3: Gautam Buddha Nagar, Dadri, Jewar), Ghaziabad (3), Hapur (3), Meerut (3), Bulandshahr (7), Baghpat (3), Shamli (3), and Muzaffarnagar (4) all had matching state/district parent codes and names in this snapshot.

Important limitation: this is an internal consistency audit of the supplied dataset, not proof that the snapshot is current or officially complete. Flutter build validation now passes in CI; official LGD freshness reconciliation remains pending. The earlier note claiming 38 state records was incorrect; it counted the upper code value rather than the number of records and has been corrected.

## Boundary dialog fix

The dialog supplies `verifiedBy: null` and `verifiedAt: null` when creating a pending boundary. This fixes the missing required constructor arguments in that call site; it does not prove that the entire application builds successfully.

Commit: `c572371cfd74a9888a66b2e51e7af1e20c627b62`

## Next planned step

Follow `docs/OFFICIAL_LGD_RECONCILIATION_RUNBOOK.md` to obtain original State, District, and Sub-district exports from the live LGD portal and compare codes, names, additions, removals, and parent mappings. Record source/date/checksums and review every difference before modifying the restored data. The public download flow exposes a CAPTCHA, so an automated fresh export was not obtained during this pass. Then add State → District → Sub-district integration tests and continue the NCR boundary review. The `test/reference_data_integrity_test.dart` suite now checks 36 unique State/UT codes, district-code uniqueness, district parent codes/names, 7,151 unique sub-district codes, sub-district State+District parent pairs, and parent-name consistency. Latest CI run `38952535466` completed successfully, including the expanded reference-data integrity tests and Flutter web release build. Do not merge until official-data reconciliation and integration/API review are complete. No production Firebase import or boundary activation is authorized by this status note.


## Official-source verification follow-up (2026-10-17)

- Reviewed the Ministry of Panchayati Raj's LGD information page and the OGD LGD catalog/resource listings.
- OGD displays an LGD catalog update date of 2026-10-15 and a Districts resource update date of 2026-10-08. However, the pages explicitly state they are a sandbox/testing environment and that content/data/functionality may be incomplete or inaccurate. These dates are therefore **not accepted as authoritative evidence of a current official snapshot**.
- Official references for manual/source verification: [Ministry of Panchayati Raj LGD page](https://panchayat.gov.in/en/lgd/), [LGD live directory portal](https://lgdirectory.gov.in/), [OGD LGD catalog](https://www.data.gov.in/catalog/local-government-directory-lgd), [OGD Districts resource](https://www.data.gov.in/resource/local-government-directory-lgd-districts).
- Next action: obtain an export from the live LGD portal (its download flow may require captcha) or a verifiable official data/API response, save source URL/date/checksum, then compare State, District, and Sub-district codes and parent mappings. No new export has yet been downloaded, so no current-data reconciliation is claimed.


## Reconciliation runbook added (2026-10-17)

Added [`docs/OFFICIAL_LGD_RECONCILIATION_RUNBOOK.md`](OFFICIAL_LGD_RECONCILIATION_RUNBOOK.md) on this branch. It records the source hierarchy, export metadata/checksum requirements, comparison checklist, acceptance criteria, and the CAPTCHA/current-export blocker. No new official data has been imported and no freshness reconciliation is claimed.


## Secondary export lead (2026-10-17)

Found a public third-party GitHub Gist describing a sub-district CSV exported from the live LGD download flow; the gist shows last activity on 2026-06-21. Recorded it in the reconciliation runbook as a secondary comparison lead only. It is not a fresh October 2026 export, does not establish current official completeness, and does not replace direct live LGD downloads for States, Districts, and Sub-districts. No records were changed based on this lead.


## October 2026 secondary dataset lead (2026-10-17)

The reconciliation runbook now records a Dataful dataset labelled “as of 12 Oct 2026,” attributed to Ministry of Panchayati Raj / LGD. Its village-granular table reports 677,673 rows and 35/781/7,081 distinct state/district/sub-district codes. These are coverage counts from a third-party village-based table, not authoritative standalone directory totals. They differ from the restored files' 36/785/7,151 records and justify code-level review, but are not enough to declare the restored snapshot wrong. No data files were changed; direct live LGD exports and automated tests remain pending.


## Initial reference-data automated tests added (2026-10-17)

Added `test/reference_data_integrity_test.dart` on the restore branch. It checks:
- Exactly 36 State/UT records and unique state LGD codes.
- Unique district LGD codes.
- Every district's state code references an existing State/UT.
- District state names match the referenced state's name after trimming and case normalization.

This is the first automated test file, not complete coverage. The CI run after this commit must be checked; do not mark the test as passing until the run reports success. Sub-district-level automated checks and current official-source reconciliation remain pending.


## Sub-district integrity tests added (2026-10-17)

Expanded `test/reference_data_integrity_test.dart` to import the restored sub-district reference file and test:
- Exactly 7,151 sub-district records with unique LGD codes.
- Every sub-district references an existing State + District code pair.
- Sub-district state and district names match the corresponding district parent record.

The test file now covers State, District, and Sub-district hierarchy consistency. The GitHub Actions result for the latest commit has not yet been returned by the workflow-run lookup, so test/build status for this commit remains **unconfirmed** until checked in Actions. Official live LGD reconciliation remains pending.


## CI confirmation (2026-10-17)

- Latest branch-head run: [GitHub Actions run 38952535466](https://github.com/dojoplatform2026/dojo-admin/actions/runs/38952535466).
- Head commit: `30eadc7473118a04adc54c3f1f41ff5a91775e73`.
- Result: **success** — dependency installation, `flutter analyze`, `test/reference_data_integrity_test.dart`, and `flutter build web --release` passed.
- This workflow does not deploy to Firebase. Current official LGD export reconciliation, State → District → Sub-district filtering/API integration review, and boundary validation remain pending. PR #6 remains open and must not be merged on the basis of CI success alone.


## State → District → Sub-district filtering (2026-10-17)

- Added `lib/data/reference/india_locations/india_location_filters.dart` with pure helpers to filter districts by State/UT LGD code and sub-districts by the combined State + District codes.
- Added four tests for Uttar Pradesh district filtering, Gautam Buddha Nagar sub-district filtering, parent scoping, and unknown-state behavior in `test/reference_data_integrity_test.dart`.
- These helpers are reference-data utilities; the Service Locations screen/Firestore import flow has not yet been wired to them. UI/API integration review remains pending.
- Validation is running for the latest commits: [run 38953242437](https://github.com/dojoplatform2026/dojo-admin/actions/runs/38953242437). Do not count the new filter tests as passing until this run completes successfully.
- Official current LGD exports, record-by-record reconciliation, and boundary validation remain pending. PR #6 remains open.


## CI failure and correction (2026-10-17)

- The first validation run after adding hierarchy-filter tests failed at `flutter analyze` because the reference files already contained helpers named `districtsForState` and `subDistrictsForDistrict`, causing ambiguous imports and mismatched signatures.
- Corrected by giving the new pure helpers unique names: `filterDistrictsForStateLgdCode` and `filterSubDistrictsForStateAndDistrict`; updated tests to call those names and removed an unused import.
- The failed run was [38953285492](https://github.com/dojoplatform2026/dojo-admin/actions/runs/38953285492). A fresh CI run must confirm the correction; until then, do not claim the new tests pass.
- No Firebase deployment or production data import was performed. Official LGD reconciliation and screen/import integration remain pending.

- Follow-up source review found two legacy helper calls still remained in the tests (the negative State-code case and the cross-State isolation case). Updated both to the new uniquely named helpers in commit `b2538c17c79237ad5d80103e4c8e621f3d0f828c`. The validation run started before this final test edit is not sufficient; verify CI for the new head commit.

## Step 25 — Repeatable LGD CSV reconciliation tooling (2026-10-17)

- [x] Added `tool/reconcile_lgd_csv.py`, a dependency-free CSV comparator keyed by an explicitly supplied LGD code column.
- [x] Added `tool_tests/test_reconcile_lgd_csv.py` for added/removed/changed records, whitespace trimming, and duplicate-key rejection.
- [x] Added the Python test command to `.github/workflows/validate_flutter_web.yml`.
- [x] Documented usage and manual official-export requirements in `docs/OFFICIAL_LGD_RECONCILIATION_RUNBOOK.md`.
- [x] Latest complete validation run for commit `ec26e38` passed: Python reconciliation tests, Flutter analysis, Flutter tests, Firestore Emulator persistence smoke test, and Flutter Web release build. Run: https://github.com/dojoplatform2026/dojo-admin/actions/runs/38959939935
- [ ] Official record-level comparison is still **PENDING** until original States/UTs, Districts, and Sub-districts exports are downloaded from the live LGD portal and compared. The tool's tests passing do not validate the actual data snapshot.
- [ ] No Dart reference data was changed; PR #6 remains open/unmerged; production import and service activation remain blocked.

## Step 25 — Combined reference-data internal audit (2026-10-17)

- [x] Re-read the three generated Dart reference files from PR head commit `e6f2f22ef02e6cf38326f04b22056790c09e26af` and parsed the records for cross-file checks.
- [x] Counts: 36 States/UTs, 785 Districts, 7,151 Sub-districts.
- [x] State records: 36 unique LGD codes; all 36 CSV state codes are present in the Dart reference list.
- [x] District records: 785 records and 785 unique district codes; no missing State parent; State names and State Census-code fields agree with the State Dart records for all district records.
- [x] Sub-district records: 7,151 records and 7,151 unique sub-district codes; no missing State parent, no missing District parent, and no State/District parent-chain mismatch against the supplied State and District Dart files.
- [x] Source snapshot dates in the Sub-district file are 2024-10-07 for all 7,151 records.
- [ ] State CSV-to-Dart field comparison has 14 field-level differences requiring source review: local-name differences for Chhattisgarh and Odisha; Census 2011 code representation/value differences for Chandigarh, Delhi, Haryana, Himachal Pradesh, Jammu and Kashmir, Ladakh, Punjab, Rajasthan, Telangana, Dadra and Nagar Haveli and Daman and Diu, Uttarakhand, and Uttar Pradesh. These differences are flags, not yet proof of which side is authoritative. Preserve source values until resolved.
- [ ] Obtain a current official LGD export and reconcile all State, District, and Sub-district rows, codes, names, and parent relationships. The internal cross-file audit does not establish current official completeness.
- [ ] Full Flutter service-class ↔ Firestore Emulator integration run, geographic polygon validation, and remaining API review are still required.
- [ ] Keep PR #6 open; do not import into production Firebase or activate service locations until outstanding gates pass.

Audit scope: static cross-file consistency only. No repository source files other than this status document were changed by this audit; no Firebase writes or deployments were performed.

## Step 26 — Service Location activation and boundary code audit (2026-10-17)

- [x] Reviewed `service_location_service.dart`, `service_location_boundary_service.dart`, `service_location_screen.dart`, `add_location_dialog.dart`, and `service_boundary_dialog.dart` at PR head commit `e6f2f22ef02e6cf38326f04b22056790c09e26af`.
- [x] City activation requires active Country + active State and a verified polygon boundary; Area activation requires active Country + State + City and its own verified polygon boundary.
- [x] Locality activation requires active Country + State + City + Area; an individual locality polygon is optional.
- [x] Boundary verification and service activation are separate stages. Boundary service records verifier UID and server timestamp; verified boundaries are not editable/deletable through the reviewed service methods.
- [x] Parent deactivation is blocked when active children exist; reparenting is blocked while child records exist.
- [!] Boundary geometry validation is basic only: at least three distinct valid coordinates are checked. The reviewed validator does not establish polygon non-self-intersection, non-zero area, ring closure/normalization, or geographic correctness/contiguity.
- [!] The boundary lookup checks status, points, source name/reference, verifier, and verified timestamp, but the audit did not establish that the polygon was compared against an authoritative map boundary.
- [ ] Run UI/emulator integration tests for activation rejection/acceptance, parent-child deactivation, reparenting, boundary verification, and stale/missing boundary IDs.
- [ ] Decide and test whether the product needs stricter polygon geometry validation and an authoritative boundary-source/review workflow before service activation.
- [ ] Official LGD row-level reconciliation remains pending; keep PR #6 open and production import/service activation blocked until all required gates are met.

Audit scope: static code review only. No source code was changed in this step; no production Firebase writes or deployment were performed.

## Step 27 — Automated test coverage audit (2026-10-17)

- [x] Reviewed `test/service_location_lgd_compatibility_test.dart`: covers legacy State/District/Area records, LGD-code serialization/reload, preservation of leading zeros, and omission of null LGD codes.
- [x] Reviewed `test/service_location_firestore_emulator_test.dart`: the service-class Emulator test covers save/reload and clearing stale LGD codes for State, District, and Sub-district. It is skipped unless `FIRESTORE_EMULATOR_HOST` is configured.
- [x] Reviewed `.github/workflows/validate_flutter_web.yml`: workflow runs Flutter analyze, Flutter tests, a separate Firestore Emulator persistence smoke test, and a Flutter Web release build without deployment.
- [!] Current named Service Location tests do not directly exercise City/Area activation rejection without verified boundaries, parent active-state preconditions, active-child deactivation blocking, reparenting constraints, or locality activation rules.
- [!] The workflow's Firestore Emulator smoke test is a Node script; it is not evidence by itself that the Dart `ServiceLocationService` activation paths were integration-tested.
- [ ] Add focused service-class Emulator tests for the activation and parent-child cases listed above; run and inspect their results before marking these gates passed.
- [ ] At audit time, workflow run associated with Step 26 commit `271c023672b0898f69845e6ccec6c1c2f2f8defa` was `in_progress`; its final result must be checked separately.
- [ ] Official LGD row-level reconciliation and geographic polygon validation remain pending. Keep PR #6 open and production import/service activation blocked until all required gates pass.

Audit scope: static review of the current named tests and workflow only. No source code was changed; no production Firebase writes or deployment were performed.

## Step 28 — Activation guard integration tests added (2026-10-17)

- [x] Added four Firestore Emulator integration cases to `test/service_location_firestore_emulator_test.dart`:
  1. City activation fails without a verified boundary.
  2. City activation fails when its parent State is inactive, even if a verified boundary exists.
  3. Area activation fails without its own verified boundary.
  4. City deactivation fails while an active Area child exists.
- [x] Updated `.github/workflows/validate_flutter_web.yml` so the Firestore Emulator workflow step runs the existing Node smoke test and then executes the Dart service-location integration test with `FIRESTORE_EMULATOR_HOST=127.0.0.1:8080`. This avoids silently skipping the emulator-only tests during CI.
- [ ] These new tests have been committed but are not yet marked PASS; wait for the CI workflow result and inspect any failures.
- [ ] Additional cases remain: wrong-parent hierarchy, reparenting while children exist, country/state deactivation constraints, locality activation with no locality polygon, and successful activation with a verified boundary.
- [ ] Official LGD row-level reconciliation and robust geographic polygon validation remain pending. Keep PR #6 open and production import/service activation blocked until all required gates pass.

Commit sequence:
- Test additions: `1200cb3ec12803e6d04c88e7a917869ee1769025`
- Emulator CI execution: `34f387b476515f4ee85f64ed556599b4fe94e1f8`

Audit scope: test and CI configuration changes only. No production Firebase writes or deployment were performed.

## Step 29 — CI failure inspected and Firebase Core test setup adjusted (2026-10-17)

- [x] Inspected GitHub Actions job logs for the Firestore Emulator step.
- [x] Node Firestore Emulator smoke test passed for State, City, and Area LGD-code save/read/clear.
- [x] Confirmed the Dart emulator test failed in `setUpAll` before any Dart test ran, with `PlatformException(channel-error ... FirebaseCoreHostApi.initializeCore)`.
- [x] Added `firebase_core_platform_interface/test.dart` test support and `setupFirebaseCoreMocks()` before `Firebase.initializeApp` to mock the Firebase Core host API.
- [ ] The adjustment is not yet verified by a subsequent successful CI run. Firestore plugin platform support may also need a different test strategy; do not mark the activation integration tests as passed until the job confirms it.
- [ ] Official LGD row-level reconciliation and robust geographic polygon validation remain pending. Keep PR #6 open and production import/service activation blocked until required gates pass.

Failure evidence: Node emulator smoke checks passed; Dart test setup failed before test execution. No production Firebase access or deployment occurred.

## Step 30 — Duplicate Firebase app initialization identified (2026-10-17)

- [x] Checked CI runs after Step 29. Python reconciliation tests, Flutter analysis, and standard Flutter unit tests passed.
- [x] Node Firestore Emulator REST smoke test passed for State, City, and Area LGD-code save/read/clear.
- [x] The Dart emulator test now gets past the earlier Firebase Core channel error, but setup failed before any tests ran with `[core/duplicate-app] A Firebase App named "[DEFAULT]" already exists`.
- [x] Updated `test/service_location_firestore_emulator_test.dart` to initialize the default Firebase app only when `Firebase.apps.isEmpty`.
- [ ] This correction is committed as `c56b8c48fbcd2ae8076725c23cd03ba1bfae4af4`; its CI run must complete and be inspected before treating emulator integration tests as passing.
- [ ] Official LGD row-level reconciliation and robust geographic polygon validation remain pending. Keep PR #6 open; no production Firebase writes, imports, or deployments were performed.

## Step 31 — Firebase mock duplicate-app handling refined (2026-10-17)

- [x] Checked CI run [38970661705](https://github.com/dojoplatform2026/dojo-admin/actions/runs/38970661705). Python reconciliation tests, Flutter analysis, and standard Flutter tests passed; 18 tests passed and 5 emulator-only tests were skipped in the normal test stage.
- [x] The dedicated emulator stage still failed before Dart test execution with `[core/duplicate-app] A Firebase App named "[DEFAULT]" already exists`; Node REST smoke tests passed.
- [x] Updated the test setup to catch only Firebase's `duplicate-app` exception from initialization and rethrow any other Firebase initialization error.
- [ ] Fix commit: `2f7782114a4ae0e83b5d4067bf909c70d68bb8d1`. Await and inspect its dedicated emulator CI result; no integration test is considered passed yet.
- [ ] If this remains unstable, move plugin-backed tests to `integration_test` on an emulator/device and keep unit tests independent of native Firebase plugin channels.
- [ ] Official LGD record-level reconciliation and robust polygon validation remain pending. PR #6 stays open; no production Firebase writes/import/deployment occurred.

## Step 32 — Flutter Firestore plugin-channel failure isolated (2026-10-17)

- [x] Inspected CI run [38970950558](https://github.com/dojoplatform2026/dojo-admin/actions/runs/38970950558) for commit `2f7782114a4ae0e83b5d4067bf909c70d68bb8d1`.
- [x] Python reconciliation tests, `flutter analyze`, and the normal Flutter test stage passed. The Node Firestore Emulator REST smoke test also passed for State, City, and Area LGD-code save/read/clear.
- [x] The Dart tests failed because `cloud_firestore` could not establish the Flutter plugin host channel for `FirebaseFirestoreHostApi.documentReferenceSet`. Starting the Firestore Emulator does not provide a native Flutter plugin host inside `flutter test`; this is a test-harness mismatch, not evidence that the Firestore REST emulator itself failed.
- [x] Added `fake_cloud_firestore: ^4.0.0` and changed the ServiceLocationService test file to use an in-memory Firestore fake, so service guards and LGD-code serialization can run as ordinary Flutter unit tests without Firebase Core or native plugin setup.
- [x] Updated the workflow so its emulator stage runs the Node REST smoke test only; the service-layer tests are picked up by the normal `flutter test` stage.
- [ ] The new approach is **not yet CI-verified**. Check the workflow run for the latest branch head before calling these tests passed.
- [ ] The fake tests validate service-layer behavior against an in-memory Firestore implementation, not Firestore Emulator server semantics. Keep the Node REST smoke test as separate emulator coverage.
- [ ] Official LGD row-level reconciliation and robust polygon validation remain pending. Keep PR #6 open; no production Firebase writes, imports, or deployments were performed.

## Step 33 — Activation guard test fixture corrected (2026-10-17)

- [x] Inspected failed CI run [38971324020](https://github.com/dojoplatform2026/dojo-admin/actions/runs/38971324020). Python reconciliation tests and `flutter analyze` passed; the normal Flutter test stage failed with 21 passed and 2 failed.
- [x] Both failures were assertions in the City activation tests: the shared fixture seeded City documents with `isServiceActive: true`, then the tests expected a rejected activation to leave that field false. The service correctly rejected activation, but the test's starting state made its postcondition invalid.
- [x] Changed the shared activation-test fixture's default City status to inactive. The City deactivation test now explicitly seeds an active City, preserving its intended scenario; the Area test still activates its City after seeding a verified boundary.
- [ ] The fixture correction is committed as `643d0c310a981ea88b5d712664f326bc2c07ffe2`; inspect the new CI result before marking tests passed.
- [ ] No production Firebase writes/imports/deployment occurred. Official LGD row-level reconciliation and robust geographic polygon validation remain pending; PR #6 stays open.

## Step 34 — Polygon geometry validation hardening (2026-10-17)

- [x] Run 191 completed successfully: Python LGD reconciliation tests, Flutter analysis, Flutter unit tests, Firestore Emulator REST smoke test, and Flutter Web release build all passed. [Workflow run 191](https://github.com/dojoplatform2026/dojo-admin/actions/runs/38971524233).
- [x] Added geometry checks to `ServiceLocationBoundary.validate()`: reject zero-area/collinear rings, self-intersecting edges, and duplicate adjacent vertices; permit a conventional repeated closing vertex.
- [x] Added focused tests for a valid triangle, repeated closing vertex, zero-area polygon, bow-tie self-intersection, and duplicate adjacent vertices.
- [ ] New code/tests committed in `bd4b6b3605c892f9e948551abb4a9fe0108b7a09` and `24f59c4e43e0d445bb4058a312128bb9d3f4b283`; wait for their CI run before marking this step PASS.
- [ ] This is basic planar geometry validation, not proof of authoritative boundaries, contiguity between neighboring areas, containment within parent polygons, or antimeridian-safe geodesic validity. Those remain required before operational service activation.
- [ ] No production Firebase writes/imports/deployment occurred; PR #6 remains open.

## Step 35 — Boundary activation and locality guard coverage (2026-10-17)

- [x] Step 34 CI passed in [Run 197](https://github.com/dojoplatform2026/dojo-admin/actions/runs/38971911543): Python reference-data tests, Flutter analysis, all Flutter tests, Firestore Emulator smoke test, and Flutter Web release build succeeded.
- [x] Added tests for City activation succeeding with a verified City boundary and persisting its boundary ID.
- [x] Added a test rejecting a boundary with the wrong location type.
- [x] Added tests confirming a Locality can activate without its own polygon when its Area is active, and cannot activate when the parent Area is inactive.
- [ ] Tests committed as `01761c0fde70821d07eeb25e72591accd0997006`; wait for CI before marking Step 35 PASS.
- [ ] Still required: reparenting and broader parent/child deactivation tests; authoritative LGD row-level reconciliation; polygon containment/adjacency/official source verification. No production writes/deployment; PR #6 remains open.



## Step 44 — Boundary verification parent-containment tests (2026-10-17)

- [x] Added `test/service_location_boundary_verification_test.dart` with five service-layer cases: Area inside verified City accepted; Area outside City rejected and remains pending; missing City boundary reference rejected; Locality inside verified Area accepted; wrong parent boundary location reference rejected.
- [x] CI run [38976622599](https://github.com/dojoplatform2026/dojo-admin/actions/runs/38976622599) completed successfully for test commit `af9b4040ffc812dcf616414e406db69aa25bcfbd`. Python reference-data tests, Flutter analysis, Flutter unit tests, Firestore Emulator REST smoke test, and Flutter Web build completed successfully.
- [x] Added [Step 44 report](LOCATION_MASTER_STEP_44.md).
- [ ] Scope caveat: the new Dart tests use `fake_cloud_firestore`, not the Firestore Emulator server. Existing Node REST smoke test checks emulator persistence only and does not execute `markVerified()`; emulator-backed service integration coverage remains outstanding.
- [ ] Official LGD row-level reconciliation, authoritative polygon provenance, robust geographic containment/adjacency checks, and Firestore rules/admin authorization review remain blockers before production activation.
- [ ] No production Firebase writes, location imports, activations, or deployments. Keep PR #6 open.


## Step 45 — Firestore authorization audit (2026-10-17)

- [x] Inspected repository tree, `firebase.json`, `AuthGate`, and `AuthService`.
- [x] Found a production-readiness blocker: no version-controlled `firestore.rules` file is present in this branch tree. Client-side `admin_users/{uid}.isActive` checks gate the UI, but cannot secure direct Firestore/API access on their own.
- [x] Added [Step 45 audit report](LOCATION_MASTER_STEP_45.md) with minimum required rules and Emulator test cases.
- [ ] Do not invent/deploy a ruleset without reviewing the current deployed rules and existing app access patterns. Obtain the canonical rules, commit them to version control, then add Emulator authorization tests.
- [ ] Official LGD row-level reconciliation and authoritative polygon provenance/geographic verification remain pending. PR #6 remains open; no production Firebase rules/data/import/activation/deployment changes were made.


## Step 45 correction — central Firestore rules are in dojo-firebase (2026-10-17)

- [x] Corrected the earlier overly broad finding: `firestore.rules` is absent from the `dojo-admin` repo, but **does exist** in the central [dojo-firebase repository](https://github.com/dojoplatform2026/dojo-firebase/blob/main/firestore.rules). The repository includes `firebase.json` rules mapping and a deployment workflow.
- [x] Reviewed the central rules: service-location collections and boundary lifecycle/activation guards are present.
- [x] New finding: central rules' `isAdmin()` requires active `super_admin`, while Admin `AuthGate` and `AuthService` check only `isActive == true`. Align the UI authorization policy with the server-side role requirement.
- [x] The rules validate boundary location/type/status/provenance for activation but do not implement polygon parent-containment geometry checks. That invariant needs a trusted server-side enforcement strategy if it must be secure against direct client writes.
- [ ] Confirm which rules version is currently deployed; repository workflow presence alone does not prove production deployment state.
- [ ] Add Firestore Emulator authorization tests for unauthenticated, inactive, role-limited users and boundary/activation lifecycle. Keep PR #6 open; no production rules/data/import/activation/deployment changes were made.
- [x] Updated [Step 45 report](LOCATION_MASTER_STEP_45.md) to correct the scope of the earlier finding.


## Step 46 — Firestore Rules Emulator tests: PASS (user-confirmed, 2026-10-17)

- [x] Identified the central source of truth as `dojoplatform2026/dojo-firebase/firestore.rules`.
- [x] Added `package.json`, `test/firestore.rules.test.mjs`, and `.github/workflows/test-firestore-rules.yml` in the central Firebase repo.
- [x] User confirmed the GitHub Actions workflow result is PASS. The exact run ID/link was not captured in this chat, so it still needs to be recorded for audit traceability.
- [x] Initial tests cover unauthenticated denial, active super-admin allowed, inactive/support-role denied, city activation requiring a verified matching boundary, mismatched boundary rejection, and verified boundary edit/delete denial.
- [ ] Add further cases for Area activation, boundary verification/rejection transitions, name indexes, import audit, and collection-by-collection authorization.
- [ ] Align Admin UI access gate with the rules' active `super_admin` requirement.
- [ ] Confirm deployed rules revision and decide trusted server-side enforcement for polygon parent-containment.
- Report: [Step 46](LOCATION_MASTER_STEP_46.md)
- Safety: no production deploy/import/activation or production data changes; keep PR #6 open.


## Step 47 — Admin authorization policy review (2026-10-17)

- [x] Re-read `lib/screens/auth/auth_gate.dart`: the gate allows any `admin_users/{uid}` record with `isActive == true`, regardless of role.
- [x] Re-read `lib/services/auth_service.dart`: login likewise checks only `isActive == true`, not the role.
- [x] Compared this with the Step 45 central-rules audit: privileged Service Location rules require an active `super_admin`. The UI/server authorization policies therefore do not align.
- [x] Kept the product requirement in view: future non-super-admins may have role-scoped screens, so simply forcing every admin to be `super_admin` could incorrectly block intended workflows.
- [ ] Define the role/permission matrix first: which roles can read each service-location collection, create/edit drafts, verify boundaries, activate/deactivate locations, manage imports, and manage global indexes.
- [ ] Add rule tests for each approved role and each protected collection before changing the rules or UI gate.
- [ ] Central Firebase repo file retrieval was unavailable during this step, so no rules code was changed and no claims are made about additional tests.
- [ ] No production Firebase deployment, data writes, imports, or activations. Keep PR #6 open.


## Step 47 follow-up — Firestore security test coverage plan

- [x] Recorded required test cases for Area activation, parent boundary verification, name indexes, import permissions/audit trail, and admin-role authorization in [Step 47 security coverage report](FIRESTORE_SECURITY_TEST_COVERAGE_STEP_47.md).
- [ ] Test implementation and execution are pending: central `dojoplatform2026/dojo-firebase` rules/test/workflow files could not be retrieved by the GitHub connector in this follow-up.
- [ ] Step 46 was user-confirmed PASS, but its exact GitHub Actions run URL is still not recorded.
- [ ] No central Firestore Rules edits, production deployment, data import, or location activation occurred.
- Next: retrieve central rules/test harness, implement emulator-backed cases, run workflow, and record the actual run URL.


## Step 47 follow-up — Firestore security tests added; CI confirmation pending

- [x] Located the correct central rules repository: `dojoplatform2026/DOJO-WALK-Firebase` (main).
- [x] Added emulator-suite cases for Area boundary activation/mismatch, name-index authorization, import actor/role permissions, audit immutability, and active non-super-admin denial.
- [ ] GitHub Actions result for the latest test commit has not yet been confirmed; do not mark these new tests PASS until the actual run is inspected.
- [!] Rules audit found `validAreaActivation()` checks matching verified boundary metadata but does not itself enforce active/verified parent City state or polygon containment.
- [ ] No production rules deployment, data import, or service activation was performed.
- Details: [Firestore Security Test Coverage report](FIRESTORE_SECURITY_TEST_COVERAGE_STEP_47.md).


## Next security hardening update — parent City validation

- [x] Firestore Rules now require Area activation to reference a verified matching Area boundary **and** an existing active parent City whose own verified-boundary activation check passes.
- [x] Added an emulator test that denies Area activation when its parent City is inactive.
- [x] Repaired test fixtures after reviewing the committed test file; active `admin` is explicitly tested as not authorized for super-admin-only service-location writes.
- [ ] GitHub Actions result for the latest commits is still unconfirmed. Do not mark these tests PASS until the run is inspected.
- [ ] Polygon containment is still not computed in Firestore Rules and needs a separate trusted-backend/security design.
- [ ] No production Firebase deployment, location import, or activation was performed.
- Details: [Firestore Security Test Coverage report](FIRESTORE_SECURITY_TEST_COVERAGE_STEP_47.md).


## Test fixture review — 2026-10-17

- [x] Reviewed parent City/boundary IDs in the committed emulator tests.
- [x] Corrected the active parent City fixture to reference a verified boundary whose `locationId` is exactly `city-parent`; inactive-parent test now references that matching boundary too.
- [ ] Emulator/Actions result remains unconfirmed; tests are not marked PASS.
- [ ] Polygon containment remains a separate security gap; no production deployment/import/activation performed.
- Test fix commit: `bafe724b628d7a4a79ae2569fdcc49827dca93f7` in `DOJO-WALK-Firebase/main`.


## Polygon containment security design — 2026-10-17

- [x] Added `docs/SERVICE_LOCATION_POLYGON_SECURITY_DESIGN.md` as a design proposal for trusted server-side activation and full Area-within-City polygon validation.
- [x] Documented geometry checks, role checks, race/revision handling, audit requirements, emulator tests, and safe rollout sequence.
- [ ] Backend/Cloud Function not implemented or deployed.
- [ ] Firestore Rules still do not calculate polygon containment; direct activation must be blocked when the trusted backend is ready.
- [ ] Latest emulator test CI result remains unconfirmed; no PASS claim.
- [ ] No production deployment, data import, or location activation.
- Design commit: `2a545f1eb1635b955811a84cba8f7b15b6e5d558`.


## Trusted activation function scaffold — 2026-10-17

- [x] Created isolated branch `feature/trusted-location-activation` in `dojoplatform2026/DOJO-WALK-Firebase`; work is not merged to `main`.
- [x] Added TypeScript callable function scaffold `activateServiceLocation` restricted to active `super_admin`, with verified boundary metadata checks, parent City checks, full Area polygon containment via Turf, transaction revalidation, and server-created activation audit records.
- [x] Added geometry unit tests for valid polygon, contained Area, crossing/outside Area, invalid coordinate, and too-few-distinct-points.
- [x] Added dedicated GitHub Actions workflow for function build/geometry tests on pull requests.
- [ ] Build/tests have not been executed in this environment; CI result pending a pull request/run. Do not claim PASS.
- [ ] Firestore rules and production deployments have not been changed/deployed by this branch; do not merge or deploy until review, CI, emulator/integration tests, and explicit approval.
- [!] Review note: current implementation supports single-ring Polygon geometry represented by `points: [{lat, lng}]`; holes/MultiPolygon/antimeridian policy are not implemented. Boundary-touching behavior depends on Turf's strict containment semantics and needs tests.
- Branch: `feature/trusted-location-activation` in `DOJO-WALK-Firebase`.


## Review/CI handoff — 2026-10-17

- Opened draft PR in central Firebase repo: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/pull/1
- PR is intentionally Draft and unmerged; it is for CI/review only.
- CI result: pending/not confirmed. Do not report tests as passing until a real Actions result is inspected.
- Outstanding before merge: reconcile boundary schema with Admin service layer, fix/confirm Firestore Rules to block direct client activation writes, add callable/emulator integration tests, inspect geometry edge cases, and review generated audit schema.
- No production deployment, rules deployment, import, or activation performed.


## CI finding and fix — 2026-10-17

- First geometry CI run failed at TypeScript build because GeoJSON `Feature`/`Polygon` types were imported from the wrong package.
- Corrected imports to use `geojson` types and declared `@types/geojson` explicitly.
- Follow-up geometry CI run #3 is in progress; Firestore Rules emulator run #11 is queued as of this update. Neither is confirmed passing.
- Follow-up geometry run: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/38981323120
- Firestore Rules run: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/38981323158


## Client activation bypass closed in draft — 2026-10-17

- Updated the draft branch Firestore Rules so City/Area documents can be created inactive, but clients cannot create an active location or transition an inactive location to active. Activation is intended to go through the trusted callable backend.
- Updated rules emulator tests to reject direct City/Area activation, including an inactive-to-active City update regression case.
- CI from the previous code revision completed successfully: Geometry Build + Unit Tests PASS; Firestore Rules Emulator Tests PASS. These results are for the earlier revision, before the latest direct-activation rule/test edits. The latest revision still requires a fresh run; do not infer its result.
- Latest relevant commits: rules `8319d4e348270b9c3d46cae6122b169b1c35d312`; rules tests `228029e3d8d94045a3c4df996fd590be47e12ddf`.
- Remaining: verify the latest Actions run, add callable/emulator integration tests, reconcile Admin app boundary schema, and wire the Admin UI to call the backend before any merge/deployment.
- No production deployment or activation has occurred.

# DOJO WALK Location Master — Project Status

Last updated: 2026-10-17

## Current status

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

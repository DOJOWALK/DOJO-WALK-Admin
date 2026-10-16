# DOJO WALK Location Master — Project Status

Last updated: 2026-10-16

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
- [ ] Finish sub-district API review and add integration tests for State → District → Sub-district filtering.
- [x] Added a separate non-deploying GitHub Actions validation workflow at `.github/workflows/validate_flutter_web.yml` (runs `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter build web --release` on restore-branch pushes and PRs targeting main).
- [x] Initial validation found three unused-code warnings and six deprecated DropdownButtonFormField `value` usages. The unused import/helper warnings were removed; the six dropdowns were updated to `initialValue` in the following commits.
- [x] Removed the three unused-code warnings and updated all six deprecated dropdown usages to `initialValue`.
- [x] Latest run `38950826261` confirmed `flutter analyze` passes with `No issues found!`.
- [x] Validation workflow adjusted in commit `1a1309a1d151f0d65f941539f981ffe7bcca0d19`: this repository currently has no `test/` directory, so the test step now reports a clear skip instead of failing before the web build.
- [ ] Confirm the new commit's workflow completes, including `flutter build web --release`; no successful release build has been confirmed yet.
- [ ] Reconcile reference counts and records against a current official LGD snapshot.
- [x] State record-count check corrected: the file contains **36 records with 36 unique LGD codes** (the 38 seen previously were the first and last code values, not the record count). The header's 28 States + 8 UTs = 36 is internally consistent. Codes 37/38 are included in the 36 records.
- [x] Parent integrity audit on the restored branch: 785 districts / 785 unique district codes; 7,151 sub-districts / 7,151 unique sub-district codes; no missing state parents, no state-name mismatches, no missing sub-district district parents, and no sub-district/district parent-name mismatches detected in the supplied files.
- [ ] Verify current official LGD source and update freshness; internal consistency does not prove that the 2024-10-07 snapshot is current.
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

The generated files were restored byte-for-byte from the Library. The GitHub blob SHAs and byte sizes were verified against the new branch. Their top-level names are `IndiaState/indiaStates`, `IndiaDistrict/indiaDistricts`, and `IndiaSubDistrict/indiaSubDistricts`. Repository code search did not return usages of those identifiers. The state model uses an integer `lgdCode`, whereas district records use a string `stateCode`; integration must normalize the comparison intentionally. A separate validation-only GitHub Actions workflow has run. `flutter pub get` passed, and the latest checked run passed `flutter analyze` with no issues. Its test step failed because this repository has no `test/` directory, not because a test assertion failed; commit `1a1309a1d151f0d65f941539f981ffe7bcca0d19` changes this step to report that coverage gap and continue to the release web build. The new commit's workflow result still needs checking. The workflow does not deploy to Firebase. Do not merge until a release web build succeeds and the missing automated tests are considered. A follow-up parser audit confirmed 36 state records with 36 unique LGD codes; the earlier “38 records” warning was incorrect and has been corrected. The hierarchy audit found no missing or mismatched parent codes/names across the restored state, district, and sub-district datasets. Current official LGD freshness validation and a successful Flutter web build remain pending.

Do not recreate the 7,151 records by hand or replace them with sample/partial data. Preserve the exact Library files and official codes when restoring.

## Hierarchy integrity audit (restored branch)

Static parsing of the restored files produced these results:

- States/UTs: 36 records, 36 unique LGD codes.
- Districts: 785 records, 785 unique district codes.
- Sub-districts: 7,151 records, 7,151 unique sub-district codes.
- District state parents: no missing state codes and no state-name mismatches found.
- Sub-district district parents: no missing `(stateCode, districtCode)` parent pairs and no district-name mismatches found.
- Uttar Pradesh: 75 district records and 350 sub-district records. NCR spot-check: Gautam Buddha Nagar (3: Gautam Buddha Nagar, Dadri, Jewar), Ghaziabad (3), Hapur (3), Meerut (3), Bulandshahr (7), Baghpat (3), Shamli (3), and Muzaffarnagar (4) all had matching state/district parent codes and names in this snapshot.

Important limitation: this is an internal consistency audit of the supplied dataset, not proof that the snapshot is current or officially complete. Official LGD freshness reconciliation and Flutter build validation remain pending. The earlier note claiming 38 state records was incorrect; it counted the upper code value rather than the number of records and has been corrected.

## Boundary dialog fix

The dialog supplies `verifiedBy: null` and `verifiedAt: null` when creating a pending boundary. This fixes the missing required constructor arguments in that call site; it does not prove that the entire application builds successfully.

Commit: `c572371cfd74a9888a66b2e51e7af1e20c627b62`

## Next planned step

Review the proposed branch, confirm no conflicting names/imports, then run formatting, analysis/tests, and the web build before merging. No production Firebase import or boundary activation is authorized by this status note.

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
- [ ] Run `flutter pub get` and `flutter build web --release`; record the actual CI/build result.
- [ ] Reconcile reference counts and records against a current official LGD snapshot.
- [ ] Complete UP/NCR targeted review.
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

The generated files were restored byte-for-byte from the Library. The GitHub blob SHAs and byte sizes were verified against the new branch. Their top-level names are `IndiaState/indiaStates`, `IndiaDistrict/indiaDistricts`, and `IndiaSubDistrict/indiaSubDistricts`. Repository code search did not return usages of those identifiers. The state model uses an integer `lgdCode`, whereas district records use a string `stateCode`; integration must normalize the comparison intentionally. The full Flutter build and automated checks have not been run for this branch.

Do not recreate the 7,151 records by hand or replace them with sample/partial data. Preserve the exact Library files and official codes when restoring.

## Boundary dialog fix

The dialog supplies `verifiedBy: null` and `verifiedAt: null` when creating a pending boundary. This fixes the missing required constructor arguments in that call site; it does not prove that the entire application builds successfully.

Commit: `c572371cfd74a9888a66b2e51e7af1e20c627b62`

## Next planned step

Review the proposed branch, confirm no conflicting names/imports, then run formatting, analysis/tests, and the web build before merging. No production Firebase import or boundary activation is authorized by this status note.

# DOJO WALK Location Master — Project Status

Last updated: 2026-10-16

## Current status

- [x] Previous structural audit recorded in the ChatGPT Library.
- [x] Boundary dialog metadata omission fixed in commit `c572371cfd74a9888a66b2e51e7af1e20c627b62`.
- [x] Reference-data artifacts located in the Library under `/DOJO WALK Location Master/02_GENERATED_DART/`.
- [ ] Restore and integrate the generated India reference Dart files into this repository.
- [ ] Verify all imports and model/API compatibility after restoring the files.
- [ ] Run `flutter pub get` and `flutter build web --release`; record the actual CI/build result.
- [ ] Reconcile reference counts and records against a current official LGD snapshot.
- [ ] Complete UP/NCR targeted review.
- [ ] Verify location boundaries and activation rules in the admin UI.
- [ ] Do not import location data into production Firebase until the above checks pass.

## Reference data currently in the Library

- `india_states.dart` — 36 State/UT records.
- `india_districts.dart` — 785 district records.
- `india_sub_districts.dart` — 7,151 sub-district records.

These are the previously audited local counts. They are **not** a claim that the records have been reconciled against the latest official LGD export. The source snapshot currently available for sub-districts is dated 2024-10-07, and a fresh official-source reconciliation remains pending.

## Important repository note

The following expected paths were checked on the default branch and were not found:

- `lib/data/reference/india_locations/india_states.dart`
- `lib/data/reference/india_locations/india_districts.dart`
- `lib/data/reference/india_locations/india_sub_districts.dart`

The matching generated files are available in the Library, but have **not** been restored to this repository yet. Do not mark reference-data integration as complete until the files are restored, imports are checked, and the build result is verified.

## Boundary dialog fix

The dialog now supplies `verifiedBy: null` and `verifiedAt: null` when creating a pending boundary. This resolves the missing required constructor arguments in that call site; it does not by itself prove that the entire application builds successfully.

Commit: `c572371cfd74a9888a66b2e51e7af1e20c627b62`

## Next planned step

Safely restore the three generated Dart reference files from the Library to `lib/data/reference/india_locations/`, preserving their existing source values and code strings. Then inspect imports/usages and run the web build. No production Firebase import or boundary activation is authorized by this status note.

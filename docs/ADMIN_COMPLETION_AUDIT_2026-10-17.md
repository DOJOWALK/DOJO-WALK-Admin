# DOJO WALK Admin — Completion Audit

Audit date: 2026-10-17  
Repository: `dojoplatform2026/DOJO-WALK-Admin`  
Working branch: `step-119-boundary-geometry`  
Review PR: [#7 — Step 119 service-location boundary geometry validation](https://github.com/dojoplatform2026/DOJO-WALK-Admin/pull/7)  
India reference-data PR: [#6 — Restore India location reference data](https://github.com/dojoplatform2026/DOJO-WALK-Admin/pull/6)

## Current decision

**Do not merge yet.** Admin work is progressing on the review branch, but a production-ready completion gate has not been met. No merge, deployment, production import, or location activation was performed.

## Work completed on the review branch

- Restored the exact India reference-data blobs from PR #6 into the review branch:
  - `india_states.dart`
  - `india_districts.dart`
  - `india_sub_districts.dart`
  - `india_location_filters.dart`
  - `test/reference_data_integrity_test.dart`
- Expanded the Service Location CI workflow to analyze the reference-data Dart files and run reference-data integrity tests alongside the geometry and CSV parser tests.
- Corrected whitespace normalization in the Admin CSV parent-mapping check. The report now explicitly says it only matches State/City/Area names and that District is not validated; it no longer labels these partial matches as complete parent matches.
- Hardened polygon validation to reject consecutive duplicate vertices that create zero-length edges, and added a regression test.
- Improved Add Location dropdown loading/error states for Country, State, City/District and Area/Sub-district.
- The focused CI run at commit `8ab91b4e828d6fb276f2000895c8ddb80dcf8a10` completed successfully: formatting, whitespace check, focused analyzer, geometry/parser tests, and India reference-data integrity tests.
- A full-project `flutter analyze`, `flutter test`, and release Web build has been added to the no-deploy Admin build workflow. The run for the latest workflow change must finish before its result is recorded.

## Still blocked / not complete

1. **CSV import is preview-only.** There is no end-to-end, transactional import that creates or updates service-location records. The UI deliberately performs no location writes from CSV.
2. **District-to-City data model mismatch.** The CSV/reference source has separate State, District, City and Area/Sub-district concepts, but the current Firestore hierarchy is Country → State → City/District → Area/Sub-district. The current model cannot safely represent both District and City as distinct parent levels. Do not guess or silently map District into City.
3. **Official source reconciliation is pending.** The committed Sub-district CSV snapshot is dated 2024-10-07. Counts and internal parent relationships do not prove that the data is the latest official LGD release. Do not fill missing local-language names by guessing.
4. **Production GIS review is pending.** Synthetic geometry tests are useful regression checks, not a substitute for authoritative geographic boundaries and a review of difficult concave/edge cases.
5. **Trusted backend deployment dependency remains.** Admin PR #7 calls Firebase Functions in `asia-south1`; companion Firebase PR #1 is still draft/unmerged. The callable deployment and Rules cutover must be coordinated and tested before production use.
6. **Live deployment safeguard needs the PR rollout.** The review branch changes Admin Hosting deployment to a manual-only, typed-confirmation workflow. The current `main` workflow remains auto-deploy-on-push until the safeguard is merged.
7. **Production Environment required-reviewer configuration is unverified** because the repository settings endpoint was not accessible during audit.
8. **Cross-app migration is not complete.** The Partner app still reads legacy active `zones`; this Admin branch does not migrate Partner to `service_cities`/`service_areas`. Customer addresses remain free-text and should not be silently rewritten.

## Merge gate

Before calling Admin ready for merge, verify all of the following:

- Latest full-project Admin workflow passes `flutter analyze`, `flutter test`, and `flutter build web --release` without deployment.
- PR #7 and its latest checks are reviewed against the exact latest head SHA.
- PR #6's duplicated/conflicting work is reconciled; do not merge it separately if the required exact files and tests are already included in PR #7.
- The District/City/Area data model decision is documented and implemented consistently across Admin, Firebase Rules/callables and dependent apps before enabling CSV writes.
- Geometry verification/activation enforcement is confirmed in the trusted backend, not only in the Admin client.
- The live deployment safeguard and required production approval settings are verified.
- Official LGD source version and NCR boundary sources are reconciled and recorded.

## Safety

This branch is a review branch. Do not import the reference data into production Firebase, activate any service locations, deploy Functions/Rules/Hosting, or merge either PR until the required checks and explicit release approval are complete.

# DOJO WALK Admin — Completion Audit

Audit date: 2026-10-18  
Repository: `dojoplatform2026/DOJO-WALK-Admin`  
Working branch: `step-119-boundary-geometry`  
Review PR: [#7 — Step 119 service-location boundary geometry validation](https://github.com/dojoplatform2026/DOJO-WALK-Admin/pull/7)  
India reference-data PR: [#6 — Restore India location reference data](https://github.com/dojoplatform2026/DOJO-WALK-Admin/pull/6)

## Latest verification refresh — 2026-10-18

- Regression found and isolated: CI for intermediate commit `58477adf2da937964985020dbd2bda0b407725aa` failed because the new pipe-character regression test used escaped backslash-n text instead of actual Dart newline escapes. The parser itself analyzed cleanly; the focused suite reported 39 passed / 1 failed, and the full suite stopped at the same test.
- The current branch version of `test/features/service_location/services/location_csv_preview_parser_test.dart` contains the correct single-backslash Dart newline escapes and now explicitly asserts that the pipe-character fixture has no file-level parse errors. On code commit `745225445a3e04482c5bdac2336bb8b453305bef`, Service Location Geometry Tests run [39065152196](https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39065152196) passed. The full Admin Web Build Check run [39065152183](https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39065152183) was still in progress at the last status check; do not claim full-suite/build verification until it completes.

- Latest previously full-CI-verified code head: `e1fde3a478d587e22238a2c2c06f1762084355e1`.
- New parser hardening on the review branch: duplicate CSV row keys now use length-prefixed normalized fields instead of a literal pipe delimiter. This prevents false duplicate detection when a valid location name itself contains `|`. Added a regression test with two distinct parent paths. Commits: `6cc3eed86c83c9520b0b2763a95b799550633b37` (parser) and `58477adf2da937964985020dbd2bda0b407725aa` (test).
- CI for the parser hardening and regression test has **not yet been confirmed**. Do not treat the earlier green checks as validation of these new commits.
- Admin Web Build Check (No Deploy), run [39056623516](https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39056623516): **SUCCESS** at the previously verified head — dependency install, full-project `flutter analyze`, full `flutter test`, and `flutter build web --release` all passed. No deployment was performed.
- Service Location Geometry Tests, run [39056623398](https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39056623398): **SUCCESS** at the previously verified head — formatting, whitespace, focused analysis, geometry/parser tests, and reference-data integrity checks passed.
- PR #7 remains Draft/open/unmerged. Firebase companion PR #1 remains Draft/open/unmerged.
- Next safe task: verify CI on the new parser/test commits, then continue read-only validation coverage without introducing Firestore writes or guessing the District/City schema. Full transactional import remains blocked on the schema decision and trusted backend support.

## Current decision

**Do not merge yet.** Admin work is progressing on the review branch, but a production-ready completion gate has not been met. No merge, deployment, production import, or location activation was performed.

## Work completed on the review branch

- Follow-up (2026-10-18): renamed the CSV parser's primary readiness property to `isSyntacticallyValid`; the Admin preview now uses this explicit name. The legacy `canProceed` getter remains deprecated for compatibility and is documented as syntax-only, not import approval. Parser test naming now reinforces that a clean preview does not authorize Firestore writes. Historical note: this parser-readiness change was followed by the preview traceability change and the code head listed in the verification refresh above; use the exact CI run links above for current validation.

- Follow-up safety clarification (2026-10-18): the CSV preview now shows an orange, explicit blocking notice that syntax validation is **not** import approval. It states that the screen performs no location writes, the current hierarchy lacks a separate District level, and a trusted transactional importer is not implemented.

- Follow-up traceability improvement (2026-10-18): the read-only CSV preview now displays the selected source filename and SHA-256 checksum of the preview text. Editing pasted content invalidates the previous preview and clears stale parent-match results; re-validating a selected file preserves its filename. This is preview-only metadata, not a persisted import record. Code commit: `4dcf686928d1c1ccef8ef69ba2367b6c85e4594a`; CI for this exact code head still needs confirmation.

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
- Replaced the static Admin map preview with active verified City/Area boundary polygons, map fitting, tap-to-identify, and a refresh control. The boundary documents are fetched in one query rather than one serial read per polygon.
- The focused CI run at commit `8ab91b4e828d6fb276f2000895c8ddb80dcf8a10` completed successfully: formatting, whitespace check, focused analyzer, geometry/parser tests, and India reference-data integrity tests.
- Full-project `flutter analyze`, `flutter test`, and the no-deploy `flutter build web --release` all passed at code commit `2366912dde77e98b94abad75f134f1c5fda604ba`: https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39049905720.

## Still blocked / not complete

1. **CSV import is preview-only.** There is no end-to-end, transactional import that creates or updates service-location records. The UI deliberately performs no location writes from CSV.
2. **District-to-City data model mismatch.** The CSV/reference source has separate State, District, City and Area/Sub-district concepts, but the current Firestore hierarchy is Country → State → City/District → Area/Sub-district. The current model cannot safely represent both District and City as distinct parent levels. Firebase Rules also use strict field allowlists that do not currently include `lgdCode` or a separate district parent, so adding fields only in Admin would be rejected or leave trusted callable validation inconsistent. A design-only proposal is recorded in `docs/SERVICE_LOCATION_DISTRICT_CITY_SCHEMA_PROPOSAL.md`; it has not been implemented or approved for production. The schema must be agreed and tested across Admin, Firebase Rules/callables and dependent apps before import. Do not guess or silently map District into City.
3. **Official source reconciliation is pending.** The committed Sub-district CSV snapshot is dated 2024-10-07. Official OGD source discovery is recorded in `docs/OFFICIAL_LGD_SOURCE_DISCOVERY_2026-10-17.md`; newer metadata was found, but official current CSV bytes have not been retrieved/reconciled. Counts and internal parent relationships do not prove that the data is the latest official LGD release. Do not fill missing local-language names by guessing.
4. **Production GIS review is pending.** Synthetic geometry tests are useful regression checks, not a substitute for authoritative geographic boundaries and a review of difficult concave/edge cases.
5. **Trusted backend deployment dependency remains.** Admin PR #7 calls Firebase Functions in `asia-south1`; companion Firebase PR #1 is still draft/unmerged. The callable deployment and Rules cutover must be coordinated and tested before production use.
6. **Live deployment safeguard needs the PR rollout.** The review branch changes Admin Hosting deployment to a manual-only, typed-confirmation workflow. The current `main` workflow remains auto-deploy-on-push until the safeguard is merged.
7. **Production Environment required-reviewer configuration is unverified** because the repository settings endpoint was not accessible during audit.
8. **Cross-app migration is not complete.** The Partner app still reads legacy active `zones`; this Admin branch does not migrate Partner to `service_cities`/`service_areas`. Customer addresses remain free-text and should not be silently rewritten.

## Merge gate

Before calling Admin ready for merge, verify all of the following:

- Full-project Admin workflow passed `flutter analyze`, `flutter test`, and `flutter build web --release` without deployment at code commit `2366912dde77e98b94abad75f134f1c5fda604ba`; the latest branch head differs only by documentation commits.
- PR #7 and its latest checks are reviewed against the exact latest head SHA.
- PR #6's duplicated/conflicting work is reconciled; do not merge it separately if the required exact files and tests are already included in PR #7.
- The District/City/Area data model decision is documented and implemented consistently across Admin, Firebase Rules/callables and dependent apps before enabling CSV writes.
- Geometry verification/activation enforcement is confirmed in the trusted backend, not only in the Admin client.
- The live deployment safeguard and required production approval settings are verified.
- Official LGD source version and NCR boundary sources are reconciled and recorded.

## Safety

This branch is a review branch. Do not import the reference data into production Firebase, activate any service locations, deploy Functions/Rules/Hosting, or merge either PR until the required checks and explicit release approval are complete.

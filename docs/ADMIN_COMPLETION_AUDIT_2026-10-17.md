# DOJO WALK Admin — Completion Audit

Audit date: 2026-10-18  
Repository: `dojoplatform2026/DOJO-WALK-Admin`  
Working branch: `step-119-boundary-geometry`  
Review PR: [#7 — Step 119 service-location boundary geometry validation](https://github.com/dojoplatform2026/DOJO-WALK-Admin/pull/7)  
India reference-data PR: [#6 — Restore India location reference data](https://github.com/dojoplatform2026/DOJO-WALK-Admin/pull/6)

## Latest verification refresh — 2026-10-18

- **Latest verified code head: `745225445a3e04482c5bdac2336bb8b453305bef`.** Both relevant GitHub Actions workflows completed successfully on this exact SHA: Admin Web Build Check (No Deploy), run [39065152183](https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39065152183), and Service Location Geometry Tests, run [39065152196](https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39065152196).
- Full Admin workflow steps all passed: dependency installation, complete-project `flutter analyze`, complete `flutter test`, and `flutter build web --release`. Geometry workflow steps all passed: formatting, whitespace check, focused integration analysis, geometry/parser tests, and reference-data integrity checks. **No deployment was performed.**
- Regression history: intermediate commit `58477adf2da937964985020dbd2bda0b407725aa` failed because the pipe-character regression test used escaped backslash-n text instead of actual Dart newline escapes. The focused suite then reported 39 passed / 1 failed. The newline fixture was corrected; the newer full suite now passes.
- The current branch version of `test/features/service_location/services/location_csv_preview_parser_test.dart` uses actual Dart newline escapes and asserts that the pipe-character fixture has no file-level parse errors.

- Parser hardening on the review branch: duplicate CSV row keys now use length-prefixed normalized fields instead of a literal pipe delimiter, preventing false duplicate detection when a valid location name contains `|`. Regression test covers two distinct parent paths. Commits: `6cc3eed86c83c9520b0b2763a95b799550633b37` (parser) and `58477adf2da937964985020dbd2bda0b407725aa` (initial test; corrected afterward).
- Earlier successful CI runs remain historical evidence only; the latest pass above is the authoritative check for the current code head.
- Admin Web Build Check (No Deploy), run [39056623516](https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39056623516): **SUCCESS** at the previously verified head — dependency install, full-project `flutter analyze`, full `flutter test`, and `flutter build web --release` all passed. No deployment was performed.
- Service Location Geometry Tests, run [39056623398](https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39056623398): **SUCCESS** at the previously verified head — formatting, whitespace, focused analysis, geometry/parser tests, and reference-data integrity checks passed.
- PR #7 remains Draft/open/unmerged. Firebase companion PR #1 remains Draft/open/unmerged.
- Next safe task: verify CI on the new parser/test commits, then continue read-only validation coverage without introducing Firestore writes or guessing the District/City schema. Full transactional import remains blocked on the schema decision and trusted backend support.

## Read-only cross-repository integration audit — 2026-10-18

### Verified evidence

- Admin review branch schema proposal remains design-only. Its recommended logical hierarchy is `Country → State → District → Service City → Service Area`; it explicitly says a City must not be inferred from a District/Sub-district name and an Area must not be treated as an LGD Sub-district without evidence. No approval or production implementation was found in the reviewed proposal.
- Firebase companion PR #1, [trusted service-location activation backend](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/pull/1), is still Draft/open/unmerged at head `80b9df5602d85fbbeb063071711743d7dfb37b6c`. Its two PR workflow runs passed: [Firestore Rules tests](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39041653227) and [Trusted Location Geometry and Callable Tests](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39041653090). These are automated PR checks, not proof of production deployment. The PR describes manual-only deployment gates; production Environment required-reviewer configuration remains unverified.
- Partner onboarding still reads active documents from `zones`, builds City/Area dropdowns from legacy `city` and `area` fields, and saves matching legacy zone document IDs into `walkers/{uid}.zones`. The reviewed Partner `main` code does not query `service_cities` or `service_areas`; no migration or compatibility adapter was found in the files reviewed.
- **Potential Partner Rules mismatch found:** the Partner repo's own `firestore.rules` owner-update allowlist does not include `state`, `zoneName`, `zoneNames`, or `travelMode`, while `WorkLocationScreen` attempts to update those fields on an existing in-progress walker record. If this repository-local Rules file is deployed, that update can be rejected. The actual deployed Rules source/version was not verified, so treat this as a confirmed source mismatch and a deployment-risk item—not as proof of current production behavior. Resolve with an Emulator test and compare against the centrally maintained Firebase Rules before any rollout.
- The Admin PR #7 and Firebase PR #1 remain Draft/open/unmerged. No Firestore writes, location activation, migration, merge, or deployment were performed during this audit.

### Integration conclusion

**Blocked — do not enable CSV writes or migrate Partner yet.** The Admin schema decision, trusted callable/Rules cutover, and legacy Partner zone compatibility must be agreed and tested together. Keep legacy `zones` readable until a separately reviewed mapping preserves existing zone IDs and walker records; do not auto-map by matching names alone.

### Next safe step

Add/execute read-only contract tests and Firebase Emulator tests for:
1. legacy Partner zone reads and walker profile update fields;
2. old City/District documents without `districtId` and proposed new District → Service City → Area ancestry;
3. callable-only boundary review/activation, including rejection of direct client verification writes;
4. rollback compatibility across Admin, Rules/callables, and Partner.

No production Rules or Functions deployment is part of this step.

## Admin completion progress — Step 127 (2026-10-18)

### Firebase Rules / trusted callable impact audit

Added [`docs/STEP_127_FIREBASE_RULES_CALLABLE_IMPACT_AUDIT.md`](STEP_127_FIREBASE_RULES_CALLABLE_IMPACT_AUDIT.md) in commit `f2fd1c96c7c1612628af0a2a398e2756cfce05f2`.

Read-only review of the Firebase branch identified:
- strict Rules allowlists currently do not include the proposed State LGD code, City `districtId`, or new District collection;
- City and Area ancestry helpers enforce the existing Country/State/City shape;
- trusted activation and status callables assume Country → State → City → Area → Locality;
- District support must be implemented together in Rules, trusted Functions, descendant/deactivation guards and Emulator tests;
- legacy Cities without `districtId` must remain readable without guessed mapping.

No Firebase code or deployed configuration was changed.

### Step 127 status

- [x] Rules allowlist impact documented.
- [x] Trusted callable and hierarchy assumptions documented.
- [x] Legacy compatibility and Emulator test matrix recorded.
- [ ] Schema decisions approved.
- [ ] Coordinated Admin/Firebase implementation.
- [ ] Partner/Customer compatibility tests.
- [ ] Full CI and release review.

## Admin completion progress — Step 126 (2026-10-18)

### Schema compatibility matrix added

Added [`docs/STEP_126_SCHEMA_COMPATIBILITY_MATRIX.md`](STEP_126_SCHEMA_COMPATIBILITY_MATRIX.md) in commit `8890bee3c9bb45aeb240b18c13f6ab0e7f73fa15`.

The matrix records:
- current versus proposed collection/field semantics;
- exact import mapping rules for State, District, operational Service City and Service Area;
- stable ID and official source-provenance requirements;
- backward compatibility for legacy Cities without `districtId`, existing Areas, Partner `zones`, bookings and walker zone IDs;
- coordinated Admin/Firebase/Partner/Customer test requirements;
- explicit no-write/no-activation/no-merge gates.

### Step 126 status

- [x] Cross-app schema compatibility matrix documented.
- [x] Unsafe name-only mapping and silent District/City or Area/Sub-District equivalence prohibited in the design.
- [ ] Product/schema decisions approved.
- [ ] Admin and Firebase schema changes implemented together.
- [ ] Partner/Customer compatibility verified with tests.
- [ ] CSV write path implemented and tested.
- [ ] Full CI and final review.

No application code, Rules, production data, imports, activations, deployments or merges were changed in this step.

## Admin completion progress — Step 125 (2026-10-18)

### Cross-repository schema blocker tracked

Created GitHub Issue [#8 — Approve cross-app Service Location schema before enabling CSV import](https://github.com/dojoplatform2026/DOJO-WALK-Admin/issues/8).

The issue turns the branch/schema audit into explicit acceptance gates covering:
- official LGD State/District reference data versus operational Service City/Area;
- stable IDs, parent references, and legacy documents without `districtId`;
- Partner legacy `zones` and walker zone IDs;
- Admin models, parent dropdowns and CSV preview mapping;
- shared Firebase Rules/Functions and Emulator coverage;
- dry-run/idempotent import, auditability, failure recovery, and source provenance.

### Current implementation decision

CSV import remains **preview-only**. The current mapping check can compare existing State/City/Area names but explicitly does not validate District, because the current schema has no separate District level. This result is not an import-readiness signal and must not be used to write or activate records.

### Step 125 status

- [x] Schema/compatibility blocker recorded in a dedicated GitHub issue with acceptance criteria.
- [x] Existing schema proposal retained as design-only; no undocumented hierarchy was implemented.
- [ ] Schema decision approved.
- [ ] Admin/Firebase/Partner compatibility changes implemented and tested.
- [ ] Transactional CSV import implemented and tested.
- [ ] Merge/deployment/release approval.

No application code, Rules, production data, imports, activations, merges or deployments were changed in this step.

## Admin completion progress — Step 124 (2026-10-18)

### Branch review followed by schema compatibility check

The branch report was refreshed in commit `3a2cfeceb1efa68eb52ffb95b0d7812869b1a4d5`. The review confirmed that Admin branch history and company-flow audit reports are separate workstreams; neither historical branch should be merged wholesale.

The schema check then compared the current Admin model, the District/City proposal, Firebase PR #1 Rules/callables, and Partner's checked-in Rules.

**Confirmed compatibility blocker:**
- Current Admin model uses `service_states`, `service_cities` (City/District combined), and `service_areas` (Area/Sub-district combined). Current State/City/Area models do not include LGD code fields.
- The Admin proposal recommends a distinct logical `District` between State and operational `Service City`, with operational `Service Area` kept distinct from official LGD Sub-district.
- Firebase PR #1 callables and Rules currently validate the combined City/Area collections and their parent fields; a new District collection or district parent relationship is not implemented in that branch.
- Partner source Rules include legacy `zones` and walker profile paths. No safe legacy-zone-to-new-area ID mapping has been established. The reviewed Partner Rules file is not proof of deployed production Rules.
- Therefore the CSV fields `State, District, City, Area` cannot safely be written into the current hierarchy by name matching or by silently treating District as City and Area as LGD Sub-district.

### Decision for implementation sequence

1. Keep CSV import preview-only and preserve the current no-write guard.
2. Define and approve the cross-repository logical contract: LGD State/District reference entities; separate operational Service City and Service Area; official Sub-district retained as reference data rather than silently reused as a service area.
3. Decide stable document IDs, parent references, legacy ID preservation, and a backward-compatible read/mapping strategy for Partner's existing `zones` and `walkers/{uid}` records.
4. Update Admin models/services/UI and trusted Firebase callable validation/Rules together, then add emulator tests for old records, new hierarchy, invalid parent chains, permissions, activation, and no direct client verification.
5. Only after that, implement transactional import with dry-run, idempotency, duplicate/source reconciliation, rollback/audit metadata, and explicit import approval.

### Step 124 status

- Cross-branch report/status audit: **PASS — refreshed**.
- Cross-repository schema compatibility audit: **PASS — blocker documented**.
- Schema implementation: **NOT STARTED; requires one consistent contract before code changes**.
- CSV transactional import: **NOT IMPLEMENTED**.
- Production data, deployment, activation and merges: **NOT performed**.

## Admin completion progress — Step 122 (2026-10-18)

### PR #6 unique test/tool asset compatibility review

Reviewed the PR #6 patches for the additional activation, hierarchy, LGD compatibility, boundary verification, and CSV reconciliation tests/tools against the current PR #7 branch.

**Finding: these files must not be copied verbatim.** The patch review identified concrete API/dependency drift:
- PR #6 activation test injects an `activateLocation` callback into `ServiceLocationService`; the current PR #7 constructor instead accepts Firestore and Functions and calls trusted Cloud Functions internally.
- PR #6 tests import `fake_cloud_firestore`, which is not present in the current PR #7 `pubspec.yaml`.
- PR #6 LGD compatibility tests expect `lgdCode` model properties, but the current PR #7 `ServiceState`, `ServiceCity`, and `ServiceArea` models do not expose those properties.
- PR #6 boundary verification tests need to be checked against the current boundary model/service and trusted callable contract before they can be reused.
- The Python CSV reconciliation utility and its unit tests are separable from Flutter runtime code, but still require an explicit run in CI and review of the report semantics before adoption.

### Step 122 decision

- Do not merge PR #6 separately.
- Do not blindly copy its unique test files into PR #7.
- Rework the useful tests against the current trusted-callable design, or explicitly decide that the old LGD-code model extension is superseded by the approved schema plan.
- Keep the CSV reconciliation utility as a candidate for a later reviewed, tested port; it does not perform Firebase writes and must remain separate from the preview-only UI until transactional import is implemented.

### Completion status

PR #7's latest head CI remains green from Step 121. This step was a source/patch audit only; no application code, dependencies, production data, Rules, or deployments were changed. The PR remains Draft/open/unmerged.

## Admin completion progress — Step 121 (2026-10-18)

### Latest branch-head CI recheck

The current PR #7 head is documentation commit `1cf8768583b76bcfe8d01caceb2189c346052077`. Both PR workflows completed successfully on that exact head:
- Admin Web Build Check (No Deploy): [run 39065771483](https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39065771483) — success.
- Service Location Geometry Tests: [run 39065771496](https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39065771496) — success.

The checks are non-deploying validation only. PR #7 is still Draft/open/unmerged.

### PR #6 vs PR #7 reconciliation

The file-level comparison found **16 overlapping paths** between PR #6 and PR #7, including the four India reference-data Dart files, reference-data integrity tests, Service Location screen/service/boundary dialog files, walker details, bookings/coupons screens, pubspec, and location status/source discovery docs. These should not be merged as two independent changes without resolving the overlap.

PR #6 also contains additional unique test/validation assets not present in PR #7's changed-file list, including:
- Firestore Emulator smoke/integration tests and hierarchy guard tests;
- boundary geometry and verification tests;
- LGD compatibility tests and CSV reconciliation Python tests;
- additional CI workflow and location-master audit records.

**Disposition:** do not merge PR #6 separately yet. Before closing or superseding it, port/reconcile the unique test assets that remain relevant into PR #7 and run the full Admin CI. The overlapping implementation files require patch-by-patch comparison; file-name overlap alone does not prove that PR #7 contains every useful change from PR #6.

### Current completion state

- Admin full analysis/tests/release build on current PR #7 head: **PASS**.
- Focused geometry/parser/reference-data CI on current PR #7 head: **PASS**.
- PR overlap reconciliation: **AUDIT STARTED; UNIQUE TEST ASSETS STILL NEED REVIEW/PORTING**.
- District/City schema: **BLOCKED pending approved cross-repository contract**.
- CSV transactional import: **NOT IMPLEMENTED**.
- Production LGD/GIS source reconciliation: **PENDING**.
- Firebase/Partner migration, production settings, merge and deployment: **NOT COMPLETE / NOT AUTHORIZED**.

No production data writes, activation, migration, deployment, or merge were performed in this step.

## Current decision

**Do not merge yet.** Admin work is progressing on the review branch, but a production-ready completion gate has not been met. No merge, deployment, production import, or location activation was performed.

## Work completed on the review branch

- Follow-up (2026-10-18): renamed the CSV parser's primary readiness property to `isSyntacticallyValid`; the Admin preview now uses this explicit name. The legacy `canProceed` getter remains deprecated for compatibility and is documented as syntax-only, not import approval. Parser test naming now reinforces that a clean preview does not authorize Firestore writes. Historical note: this parser-readiness change was followed by the preview traceability change and the code head listed in the verification refresh above; use the exact CI run links above for current validation.

- Follow-up safety clarification (2026-10-18): the CSV preview now shows an orange, explicit blocking notice that syntax validation is **not** import approval. It states that the screen performs no location writes, the current hierarchy lacks a separate District level, and a trusted transactional importer is not implemented.

- Follow-up traceability improvement (2026-10-18): the read-only CSV preview now displays the selected source filename and SHA-256 checksum of the preview text. Editing pasted content invalidates the previous preview and clears stale parent-match results; re-validating a selected file preserves its filename. This is preview-only metadata, not a persisted import record. Code commit: `4dcf686928d1c1ccef8ef69ba2367b6c85e4594a`; this change is included in the later branch head `745225445a3e04482c5bdac2336bb8b453305bef`, whose full CI checks passed.

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

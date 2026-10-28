# DOJO WALK Admin — GitHub File Structure Audit

**Audit date:** 2026-10-29  
**Repository:** `DOJOWALK/DOJO-WALK-Admin`  
**Audited ref:** PR #51 head `df5562f2166d864f3817d06caff0a480076a3c91`  
**Working branch:** `ui/notion-brand-foundation-2026-10-28`  
**Status:** Inventory only; no source files moved or deleted by this audit.

## 1. Scope and safety

The repository tree was read from the exact PR-head commit. The tree contains 394 entries and GitHub reported `truncated: false`. This is a path inventory, not a claim that every feature is complete or that the application was built during this audit.

Notion remains the source of truth. The user-provided target tree is a desired logical organization, but the current implementation has established legacy paths and a Notion-aligned hybrid layout. Do not move or delete code solely to make the tree visually identical. Each migration needs an import/reference audit, tests, and exact-head CI.

## 2. Observed current layout

| Area | Paths observed at audited PR head | Finding / next action |
|---|---|---|
| App entry and composition | `lib/main.dart`, `lib/app/app.dart`, `lib/app/theme.dart` | Existing. Keep stable while organizing features. |
| Shared/core | `lib/utils/`, `lib/app/`, `lib/services/` | No top-level `lib/core/` directory observed in this tree. Introduce core subfolders only when moving a real shared responsibility with tests; avoid duplicate utility/theme sources. |
| Dashboard | `lib/screens/dashboard/admin_shell.dart`, `lib/screens/dashboard/dashboard_screen.dart` | Established path. Keep as the company command center per UI map. |
| Bookings | `lib/screens/bookings/bookings_screen.dart`, `booking_status_helper.dart` | Established path, not yet `lib/features/bookings/`. Do not move without a tested migration plan. |
| Live Operations | `lib/screens/live/` | Established path, including booking detail helper and map widget. Keep until a Notion-backed migration is approved. |
| Authentication | `lib/screens/auth/`, `lib/services/auth_service.dart` | Established legacy ownership; inspect before any consolidation. |
| Service Location | `lib/features/service_location/{models,screens,services,utils,widgets}/` | Already organized by responsibility; preserve. Create Zone remains State/UT → District → City → Zone, with no Locality selector. |
| Walker Management | `lib/features/walkers/{models,screens,services,utils,widgets}/` | Existing feature-grouped domain. Preserve. |
| Other Admin domains | `lib/features/access_control`, `audit`, `customers`, `finance`, `notifications`, `pets`, `reports`, `settings`, `support` | Feature-grouped domains exist. Verify each against the UI map; do not create parallel screens. |
| India reference data | `lib/data/reference/india_locations/india_states.dart`, `india_districts.dart`, `india_sub_districts.dart`, `india_location_filters.dart` | Files exist at the audited head. Source provenance, determinism, IDs, counts, and parent-child integrity must be verified before production import. |
| Tests | `test/screens/`, `test/features/`, `test/data/`, `test/reference_data_integrity_test.dart` | Mixed legacy and feature-aligned test paths. Keep tests near the existing domain convention; move only with imports and CI verified. |
| CI | `.github/workflows/admin-main-full-validation.yml`, `admin-web-build-check.yml`, `build_web.yml`, `service-location-geometry-tests.yml` | Four workflows exist. Do not delete or consolidate workflows until triggers, required checks, and duplicate coverage are audited. |
| Data templates | `data/templates/service_location_import_template.csv` | Existing template. This is distinct from generated/reference data and production imports. |
| Documentation | `docs/PROJECT_FILE_STRUCTURE.md`, `docs/LOCATION_MASTER_STATUS.md`, `docs/architecture/`, `docs/ui/`, and many dated `STEP_*.md` reports | Documentation is extensive and historical. Do not bulk-delete or relocate historical evidence; update the canonical index and links instead. |
| Coupons | No `lib/features/coupons/` implementation is part of the Notion-aligned target. | Do not recreate a coupon feature/menu. DOJO WALK uses no coupon-code system. |

## 3. Comparison against the requested target tree

- **Already present or functionally represented:** `.github/workflows/`, `docs/`, `data/`, `lib/main.dart`, `lib/app/app.dart`, `lib/data/reference/india_locations/`, `lib/features/service_location/`, `lib/features/walkers/`, `lib/firebase_options.dart`, `test/`, `web/`, and Flutter project configuration.
- **Different from the simplified target tree:** Dashboard, Bookings, Live Operations and Auth use existing `lib/screens/` paths; shared authentication is under `lib/services/`; multiple additional feature domains exist under `lib/features/`.
- **Not observed as a top-level folder at this head:** `lib/core/`, `lib/data/repositories/`, and a complete generic `lib/shared/` layer. Do not create empty placeholders. Add these only when there is a concrete shared implementation to place there.
- **Target-only/obsolete item:** `lib/features/coupons/` must not be added.
- **Workflow naming:** The target mentions `build_web.yml`, which exists, but it is not the only workflow. Keep all workflows until their roles and required-check dependencies are verified.

## 4. Safe migration order

1. Keep the current hybrid layout and map each domain to its canonical path in `docs/ui/NOTION_FILE_STRUCTURE_CONTRACT.md` and `docs/ui/ADMIN_UI_NOTION_FILE_MAP.md`.
2. Audit all imports and route references before moving any file.
3. For each proposed move, make a small isolated change; update imports and tests in the same commit.
4. Run formatter, `flutter analyze`, relevant tests, full `flutter test`, and `flutter build web --release`.
5. Record the exact commit SHA and actual workflow run. A missing/empty status response is not a pass.
6. Do not merge, deploy, or expand Firebase integration during the UI-first phase.

## 5. Current-head recheck — 2026-10-29

Rechecked directly against PR #51 head `df5562f2166d864f3817d06caff0a480076a3c91`; GitHub returned a complete recursive tree (`truncated: false`, 394 entries).

- `lib/core/`, `lib/data/repositories/`, and `lib/shared/` are not present as tracked paths. They remain target architecture folders only; do not create empty placeholders.
- Existing dashboard/auth/bookings/live screens remain under `lib/screens/`; do not create duplicate feature copies.
- All four India reference Dart files are present: `india_states.dart`, `india_districts.dart`, `india_sub_districts.dart`, `india_location_filters.dart`.
- The branch has a successful Admin Web Build Check at earlier commit `f8ff6a53daba7a70436c9419755a20c3bb9f4b7a` (run `40777254854`). The current PR head is `df5562f2166d864f3817d06caff0a480076a3c91`, so that earlier success is **not** proof that the current head passed. Current-head status response was empty; CI needs a new run or explicit workflow evidence before calling it green.

## 6. Audit result

**Inventory completed; structural migration not yet performed.** The repository already contains a working mixed layout and a more detailed Notion-driven file map. The next implementation task is to reconcile the user's desired logical tree with that canonical map, then select one low-risk migration only if the mapping proves a real maintenance benefit. No production data or Firebase state was changed.

## 7. Follow-up recheck — 2026-10-29

The repository was rechecked at PR #51 head `97e3fadab6cf51897c4c1389dcecfe750db5c0cc` using GitHub's recursive Git tree API:

- Tree response: `truncated: false`, 394 entries.
- The four India location Dart files are tracked. The sub-district source blob is 1,830,733 bytes; a content-preview response returned no text for this large file, so that preview must not be interpreted as an empty source file.
- `lib/core/`, `lib/data/repositories/`, and `lib/shared/` remain absent as tracked paths. Do not create empty directories solely to match the diagram.
- The four workflows remain present: `admin-main-full-validation.yml`, `admin-web-build-check.yml`, `build_web.yml`, and `service-location-geometry-tests.yml`.
- Reference data provenance remains **unverified**: the Dart comments identify a user-supplied LGD CSV, but the corresponding raw source file, source URL, retrieval date, licence/terms, checksum and reproducible generation command were not found under `data/reference/india_locations/`. Do not import this data into production Firebase until that evidence and integrity review are complete.
- Current PR head has no reported commit statuses and no workflow run associated with that exact SHA in the inspected API responses. The latest successful Admin Web Build Check returned by the branch run list is run `40777254854` for older code commit `f8ff6a53daba7a70436c9419755a20c3bb9f4b7a`; it is not proof of a pass on the current head.
- No source files were moved or deleted during this follow-up. PR #51 remains Draft; no merge, deploy, or backend expansion.

### Follow-up result and remaining blocker

- Added `data/reference/india_locations/README.md` in documentation commit `2ceb58f1849fbff8cbc491421f2d34cacd909cd9`. It documents the separation between source artifacts, staging, audits and generated Dart, plus the validation gates before production import.
- `data/reference/india_locations/source_manifest.md` is intentionally **not created yet** because the raw source artifact and its provenance fields are not available in the repository. Creating a manifest with guessed URLs, dates, licences or checksums would be misleading.
- The README-only commit does not change Dart code. Exact-head CI status is still unreported; historical CI success remains limited to the earlier code commit noted above.
- Next safe task: obtain the actual LGD CSV/source artifact and verify its provenance, then populate the manifest and audit the generated dataset. Until then, do not regenerate or import reference data.


## 8. Latest exact-head recheck — 2026-10-29

This section supersedes earlier head-specific counts and CI observations above where they conflict.

- Pull request: #51, still **open and Draft**; base `main`; working branch `ui/notion-brand-foundation-2026-10-28`.
- Exact PR head inspected: `9b9724796d69620e6dac1ec87946df1b2689d744`.
- Recursive Git tree inspection returned **397 paths**. The current tree includes `.github/workflows/build_web.yml`, the other existing validation workflows, `docs/ui/` maps/contracts, the established `lib/screens/` and `lib/features/` hybrid layout, and the four India reference Dart files.
- Current canonical file ownership remains documented in `docs/ui/NOTION_FILE_STRUCTURE_CONTRACT.md` and `docs/ui/ADMIN_UI_NOTION_FILE_MAP.md`. The user's simplified tree is a logical target, not permission to move files mechanically.
- `lib/core/`, `lib/data/repositories/`, and a generic `lib/shared/` layer are not present as tracked paths. Do not add empty placeholders. Introduce them only alongside a real responsibility and a tested migration.
- Do **not** create `lib/features/coupons/`; coupon-code functionality is excluded by the product decision.
- Exact-head CI recheck for `9b9724796d69620e6dac1ec87946df1b2689d744` returned no commit statuses and no associated PR workflow runs in the inspected responses. Therefore, current-head CI is **unverified**, not passed. The older successful run does not establish a pass for this SHA.
- No production files were moved or deleted during this audit. No Firebase/backend expansion, merge, or deployment was performed.

### Next action

Continue with a path-by-path Notion mapping audit. Prefer documenting the canonical location and gaps over cosmetic moves. Before any code move, check imports, routes, tests, workflow triggers and release gates; then make one isolated change and verify CI against its exact resulting SHA.

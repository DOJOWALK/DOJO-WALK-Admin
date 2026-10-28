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

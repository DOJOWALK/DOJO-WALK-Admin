# DOJO WALK — Company Project File Structure

Last updated: 2026-10-29

> **Notion precedence:** This document contains an older target-tree snapshot. For the Admin repository's current file ownership and UI mapping, follow `docs/ui/NOTION_FILE_STRUCTURE_CONTRACT.md`, `docs/ui/ADMIN_UI_NOTION_FILE_MAP.md`, and `docs/ui/NOTION_POL040_FILE_MAP.md`. Do not move files to match the legacy tree below without a Notion-backed migration plan.

This document defines the intended, maintainable file structure for the DOJO WALK repositories. It distinguishes existing paths from planned paths; a documented target folder is not proof that the folder already exists in GitHub.

## 1. Repository boundaries

- `DOJO-WALK-Admin`: Admin web portal, company operations UI, service-location operations, boundary review and administrative workflows.
- `dojo-walk-customer`: Customer app, profile, dogs, addresses, booking and walk tracking views.
- `dojo-partner`: Walker/partner onboarding, availability, assigned walks and active walk operations.

Keep app-specific UI and logic in its own repository. Shared data contracts should be documented and versioned; do not copy whole app folders across repositories.

## 2. Admin repository — target structure

```text
dojo-admin/
├── .github/
│   └── workflows/
│       └── build_web.yml
├── docs/
│   ├── PROJECT_FILE_STRUCTURE.md
│   ├── LOCATION_MASTER_STATUS.md
│   ├── architecture/
│   ├── data_dictionary/
│   ├── runbooks/
│   └── decisions/
├── data/
│   └── reference/
│       └── india_locations/
│           ├── source_manifest.md
│           └── README.md
├── lib/
│   ├── main.dart
│   ├── app/
│   │   └── app.dart
│   ├── core/
│   │   ├── constants/
│   │   ├── errors/
│   │   ├── routing/
│   │   ├── theme/
│   │   └── utils/
│   ├── data/
│   │   ├── reference/
│   │   │   └── india_locations/
│   │   │       ├── india_states.dart
│   │   │       ├── india_districts.dart
│   │   │       └── india_sub_districts.dart
│   │   └── repositories/
│   ├── features/
│   │   ├── auth/
│   │   ├── dashboard/
│   │   ├── bookings/
│   │   ├── walkers/
│   │   ├── live_operations/
│   │   ├── service_location/
│   │   │   ├── models/
│   │   │   ├── screens/
│   │   │   ├── services/
│   │   │   └── widgets/
│   │   ├── coupons/
│   │   └── settings/
│   ├── shared/
│   │   ├── widgets/
│   │   └── services/
│   └── firebase_options.dart
├── test/
│   ├── core/
│   ├── features/
│   └── data/
├── web/
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

### Current known paths confirmed on the repository default branch

- `lib/main.dart`
- `lib/app/app.dart` (imported by `main.dart`)
- `lib/features/service_location/models/service_location_models.dart`
- `lib/features/service_location/services/service_location_service.dart`
- `lib/features/service_location/widgets/service_boundary_dialog.dart`
- `.github/workflows/build_web.yml`
- `pubspec.yaml`
- `docs/LOCATION_MASTER_STATUS.md`

Current working-branch audit (2026-10-29) confirms `lib/data/reference/india_locations/india_states.dart`, `india_districts.dart`, and `india_sub_districts.dart` exist, alongside `india_location_filters.dart`. Treat the older absence note as historical and do not restore duplicate files. Verify declarations, source provenance, imports, IDs, and parent-child integrity before changing or integrating generated data. Some folders in the illustrative target tree remain planned rather than existing.

## 3. Reference data rules

- Keep raw government source files, generated Dart, staging outputs and audit reports separated.
- Record source URL/name, retrieval date, publication/update date if available, licence/terms, checksum and generation command in a source manifest.
- Preserve official codes as strings whenever leading zeros or non-numeric identifiers matter. Do not silently replace blank or placeholder codes.
- Keep generated Dart deterministic and do not manually patch individual generated records without updating the source/staging data and audit.
- Do not mix reference data with live customer address records.
- Validate unique IDs, parent-child relationships, record counts and source differences before integration.
- Never import reference records into production Firebase until source validation, schema review and import dry-run pass.

## 4. Service-location domain

Current Admin Create Zone form hierarchy (latest POL-038/POL-040):
`State/UT -> District -> City -> Zone`

**Do not add a Locality selector to Create Zone.** This four-selector UI contract supersedes the older broader reference-data hierarchy below. Reference datasets may contain additional government geography levels, but they are not extra Create Zone selectors.

Expected responsibilities:
- `models/`: typed models and serialization only.
- `services/`: Firestore access, validation, unique-name indexes and state transitions.
- `screens/`: page-level UI and navigation.
- `widgets/`: reusable UI components such as boundary editor/dialog.
- Boundary draft saving, boundary verification and service activation are separate operations.
- Zone is the only service activation unit. State/UT, District and City are reference hierarchy records, not independently activated service areas. Zone launch/activation requires a verified polygon and valid parent chain. A radius-only circle is not a substitute for a verified Zone polygon.
- Customer pickup/drop-off addresses remain separate from the service-area reference hierarchy.

## 5. Customer repository — target feature grouping

```text
dojo-walk-customer/
├── docs/
├── lib/
│   ├── main.dart
│   ├── app/
│   ├── core/
│   ├── data/
│   ├── features/
│   │   ├── auth/
│   │   ├── home/
│   │   ├── dogs/
│   │   ├── addresses/
│   │   ├── booking/
│   │   ├── bookings/
│   │   ├── live_walk/
│   │   ├── support/
│   │   └── profile/
│   ├── l10n/
│   └── shared/
├── test/
├── web/
└── pubspec.yaml
```

## 6. Partner repository — target feature grouping

```text
dojo-partner/
├── docs/
├── lib/
│   ├── main.dart
│   ├── app/
│   ├── core/
│   ├── data/
│   ├── features/
│   │   ├── auth/
│   │   ├── onboarding/
│   │   ├── documents/
│   │   ├── work_zone/
│   │   ├── assigned_walks/
│   │   ├── live_walk/
│   │   ├── earnings/
│   │   └── profile/
│   └── shared/
├── test/
├── web/
└── pubspec.yaml
```

These Customer and Partner trees are target groupings, not an audit of every existing file in those repositories.

## Company-wide flow and ownership

The company-level workflow, repository ownership, shared contract rules, Service Location lifecycle, and recommended folder placement are maintained in
[`docs/architecture/DOJO_WALK_COMPANY_FLOW_AND_FILE_STRUCTURE.md`](architecture/DOJO_WALK_COMPANY_FLOW_AND_FILE_STRUCTURE.md).

Canonical business flow:
`Company/System Management → Operations → India Location Master → Customer → Partner/Walker → Booking/Live Walk → Support → Reports/Audits`.

This is a cross-repository flow, not a reason to duplicate app folders. Keep each feature in its owning repository, preserve existing paths until migration tests pass, and use canonical shared IDs/contracts for entities used by multiple apps. The architecture guide distinguishes intended organization from implementation that has actually been verified.

## Dashboard-first navigation structure

The Admin shell is defined in `lib/screens/dashboard/admin_shell.dart`. Keep **Dashboard** as the main company command center. Live Operations is launched from the Dashboard's prominent action and retains its dedicated map screen at `lib/screens/live/live_operations_screen.dart`; it is not a separate sidebar destination. Dashboard UI and metrics live in `lib/screens/dashboard/dashboard_screen.dart`.

Company flow and implementation boundary: `docs/architecture/DOJO_WALK_COMPANY_FLOW_AND_FILE_STRUCTURE.md`.

## 7. Engineering and release gates

1. Inspect existing files before moving or renaming anything.
2. Avoid duplicate models, duplicate routes and duplicate sources of truth.
3. Run formatting and static analysis for changed Dart files.
4. Run relevant unit/widget tests.
5. Run `flutter pub get` and `flutter build web --release` for Admin Web.
6. Record the actual CI/build run and commit SHA in `docs/LOCATION_MASTER_STATUS.md`.
7. Do not claim build success based only on a commit or empty status response.
8. Deploy only after the release checks pass; keep production imports and migrations separate from code deployment.

## 8. Immediate next actions

- Restore the three generated Dart reference files from the Library after checking declarations, IDs and import usage.
- Inspect the current feature tree and ensure files are placed under the existing architecture rather than creating duplicate model/service layers.
- Add focused tests for reference-data counts, key uniqueness and parent-child integrity.
- Run the actual web build and record the result.


## 9. Current GitHub structure audit — 2026-10-29

Verified against the open UI branch `ui/notion-brand-foundation-2026-10-28` at `fd18275d5fa0822653a06c435cee9098a18960ce`:

- Existing domain code is organized primarily under `lib/features/<domain>/`; the dashboard, auth, bookings and Live Operations retain their established `lib/screens/` paths. Preserve these real paths; do not create duplicate `lib/features/dashboard/`, `lib/features/bookings/`, or `lib/features/live_operations/` trees just to make the layout look uniform.
- Service Location uses `lib/features/service_location/{models,screens,services,utils,widgets}/`; its tests mirror it under `test/features/service_location/`.
- India reference data currently exists under `lib/data/reference/india_locations/`; integrity tests are under `test/data/reference/india_locations/` and `test/reference_data_integrity_test.dart`.
- UI mapping contracts are `docs/ui/NOTION_FILE_STRUCTURE_CONTRACT.md`, `docs/ui/ADMIN_UI_NOTION_FILE_MAP.md`, and `docs/ui/NOTION_POL040_FILE_MAP.md`.
- No coupon-code system: do not restore a Coupons screen/menu from the legacy example tree.
- The `build_web.yml` workflow exists, as do `admin-web-build-check.yml`, `admin-main-full-validation.yml`, and `service-location-geometry-tests.yml`. Keep workflow responsibilities distinct; do not delete or rename workflows without checking triggers and branch protections.
- Structural changes require: Notion requirement → path mapping update → compatibility/import audit → focused tests → analyzer/full test suite/Web release build. Record exact commit and run evidence. Do not merge, deploy, or add Firebase integration in this UI phase.

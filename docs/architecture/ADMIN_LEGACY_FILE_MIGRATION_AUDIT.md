# DOJO WALK Admin — Legacy File Migration Audit

Date: 2026-10-24
Branch: `feature/admin-fresh-architecture-2026-10-24`
Scope: static repository-tree and entry-point/import review. This is not a full Dart dependency-graph scan or emulator test.

## Verified entry point

- `lib/main.dart` is present in the inspected branch tree.
- `lib/app/app.dart` builds `DojoWalkAdminApp` and sets `FreshAdminAuthGate` as the app home.
- `lib/features/shell/admin_app_shell.dart` imports the fresh Dashboard, Add Location, Boundary Review, and Live Operations screens.
- The new shell does not import the legacy `lib/screens/dashboard/admin_shell.dart`.

## File inventory and decision

| Path / group | Decision | Reason / safe next action |
|---|---|---|
| `lib/app/app.dart`, `lib/core/auth/**`, `lib/core/theme/**` | KEEP | Fresh app entry, auth gate, identity and theme dependencies. Review authorization tests before production. |
| `lib/features/dashboard/presentation/admin_dashboard_screen.dart` | KEEP | Fresh Dashboard presentation. Dashboard counts intentionally remain unclaimed until data contracts are connected. |
| `lib/features/live_operations/presentation/live_operations_screen.dart` | KEEP | Fresh Live Operations presentation. Nearby-walker status is explicitly not checked; no live feed is claimed. |
| `lib/features/service_location/**` | KEEP / REVIEW | Current fresh location workflow and domain/import/boundary code. Review callable, Firestore read-after-write, security rules and emulator coverage before production. |
| `lib/screens/auth/**`, `lib/screens/dashboard/**`, `lib/screens/live/**`, `lib/screens/bookings/**`, `lib/screens/coupons/**` | PRESERVE; migration candidate | Legacy shell still imports these files. The inspected new entry point does not route to the old shell, but do not delete until repository-wide imports, tests, and any rollback needs are fully checked. |
| `lib/features/walkers/**` | PRESERVE; classify individually | Legacy walker feature files are in a feature-named directory but use older `screens/services/widgets` organization. The current fresh shell does not import them. Preserve until walker scope and future Admin-vs-Partner responsibilities are reviewed. |
| `lib/services/auth_service.dart` | PRESERVE; migration candidate | Imported by legacy `AdminShell`; not imported by the fresh shell shown in this audit. Do not delete while the legacy code remains. |
| `lib/data/reference/india_locations/**`, `review/lgd_exports/**`, `test/data/reference/**` | KEEP | Reference data and audit/review material; never remove as part of UI cleanup. |
| `lib/firebase_options.dart`, `pubspec.yaml`, workflows, tests | KEEP / REVIEW | Required configuration and validation surface; check project/platform values and dependency use before any changes. |

## Structural gaps against the approved target

1. Fresh code is only partially feature-first; the shell currently has no fresh routes for access control, Area Manager assignments, bookings, walkers, coupons, payments or audit.
2. The documented target has `app/router.dart` and dependency setup, but the inspected current app uses `home: FreshAdminAuthGate()` and no router/dependency container is visible in `lib/app/app.dart`.
3. The existing `lib/features/walkers/**` files are not yet normalized to `data/domain/presentation`; keep them preserved and migrate only after the Admin/Partner responsibility contract is defined.
4. Legacy screens remain in the repository. Their presence is intentional until dependency and rollback review is complete; fresh UI should not be added to `lib/screens/**`.

## Workflow evidence for inspected HEAD

Inspected commit: `4c130f5ee31ad71452b42f40df8017a6e468f5d0`.

- Service Location Geometry Tests run `40052990042`: completed successfully.
- Admin Web Build Check (No Deploy) run `40052990023`: in progress at audit time.
- Admin Main Full Validation (No Deploy) run `40052989990`: in progress at audit time.

These are commit-specific GitHub Actions states; they do not prove production readiness, live Firebase behavior, or successful deployment.

## Next safe migration steps

1. Wait for the Web Build and Full Validation results on the inspected HEAD; inspect logs if either fails.
2. Enumerate all Dart imports/references to legacy screens and services, including tests and route entry points; mark each KEEP / MIGRATE / REMOVE with evidence.
3. Add missing role/scope model and authorization tests before exposing Area Manager or access-control screens.
4. Verify callable request/response and Firestore read permissions using emulator-backed tests, including save → re-read → inactive state and duplicate handling.
5. Only remove a legacy file after a full reference scan, passing checks, and explicit confirmation that rollback/preserved functionality is not needed.
6. Do not merge or deploy without explicit approval.


## Latest verified checkpoint — 24 Oct 2026

Reviewed PR #37 current head `6ccf4bac253cc40a15f665afbaa0ac80c111d123` after the earlier checkpoint above.

- PR #37 remains open and draft; no merge or deployment was performed.
- The three PR-triggered checks associated with this inspected head are complete and successful: Service Location Geometry Tests (`40068826948`), Admin Main Full Validation / No Deploy (`40068826832`), and Admin Web Build Check / No Deploy (`40068826773`).
- Current navigation has Dashboard, Add Location, and Boundary Review. Live Operations is embedded within Dashboard as requested; it is not a separate navigation destination.
- Dashboard intentionally displays placeholders instead of invented booking/walker totals. The embedded Live Operations view offers a permission-aware device/browser “My Location” action, labels “Possible Walker Nearby” as “Not checked,” and states that the live feed is not connected.
- File structure remains **partially normalized, not complete**: fresh files are in feature-first folders, but legacy `lib/screens/**`, `lib/services/**`, and older `lib/features/walkers/**` organization remain. They are preserved intentionally because the full reference/dependency and rollback scan has not been demonstrated.
- Production blockers remain: authenticated Firebase Emulator coverage for Admin identity revocation and Add Location save/read-back; real geographic map-based boundary review; live walker/booking feed and authorized actions; Founder/CEO approval controls; Area Manager assigned-area server enforcement; and verification that deployed Firebase revisions match reviewed source.

### Migration rule

Do not bulk-delete or bulk-move legacy files merely to make the tree look clean. First run a repository-wide reference/dependency scan, classify each candidate KEEP / MIGRATE / REMOVE, move one coherent feature at a time, and require formatter, analyzer, full tests, web build, and relevant emulator tests after each migration. Keep this PR draft until those gates and explicit review are complete.

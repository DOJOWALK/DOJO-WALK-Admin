# AdminShell Navigation Widget Test Addition — 2026-10-31

## Scope
- Repository: `DOJOWALK/DOJO-WALK-Admin`
- Branch: `ui/notion-brand-foundation-2026-10-28`
- PR: #51 (Draft; no merge/deploy)
- Production source: `lib/screens/dashboard/admin_shell.dart`
- Test: `test/screens/dashboard/admin_shell_test.dart`

## Testability change
Added optional `dashboardDataSource` injection to `AdminShell` and passed it to `DashboardScreen`. This allows AdminShell widget tests to use deterministic streams without initializing Firebase for the Dashboard. The production default remains unchanged: when no source is supplied, DashboardScreen uses its existing Firestore data source.

## Tests added
1. Desktop sidebar contains the expected destinations and does not show a duplicate Live Operations menu entry.
2. Mobile drawer opens, selects Settings, and closes after navigation.
3. Logout confirmation Cancel closes the dialog without signing out.

The tests use a local fake `DashboardDataSource`; no production data is read or written.

## Validation
- Test file committed and re-fetched from the branch.
- Source inspection confirms `AdminShell.dashboardDataSource` is passed into DashboardScreen.
- Flutter tests, formatter and analyzer have **not been executed in this environment**.
- GitHub Actions exact-head lookup for `3e8d754d9da82f7117894b43ebe6691962250f57` returned no workflow runs. This is **not a CI PASS**.
- PR #51 remains Draft/open/unmerged. No Firebase repository, schema, Rules, Functions, production data or deployment changed.

## Next validation gate
Run the focused test `flutter test test/screens/dashboard/admin_shell_test.dart`, then full `flutter analyze`, `flutter test` and `flutter build web --release` on the exact branch head. Fix any failures before considering the navigation change validated.

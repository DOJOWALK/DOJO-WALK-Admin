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
- GitHub Actions run `41229820235` checked PR #51's merge ref `4e7a5401e25f013ba84a7530712c2d90c8bc07be` (including commit `eb9110d3574fde6533ccc4c0c0158f433d607d49`). Static analysis **passed**; full suite reported **353 passed, 2 failed**; Web build was skipped after the test failure.
- Failure 1: desktop assertion expected no `Live Operations` text, but the Dashboard itself has a `Live Operations` card heading. The sidebar did not add a duplicate menu entry; the assertion was over-broad.
- Failure 2: mobile drawer assertion expected `Service Locations` immediately, but the item is below the visible scroll area and was not built by the lazy ListView. The test should scroll to Settings before tapping it.
- These are test expectation/visibility issues identified from CI logs; the test correction below must be re-run before claiming PASS.
- PR #51 remains Draft/open/unmerged. No Firebase repository, schema, Rules, Functions, production data or deployment changed.

## Follow-up correction
- Narrow the desktop assertion to expect the single Dashboard card heading `Live Operations`; this catches a duplicate text entry while allowing the legitimate Dashboard heading.
- Scroll the mobile drawer to the Settings destination with `ensureVisible` before tapping; do not assert that a below-the-fold lazy-list item is initially built.

## Next validation gate
Re-run `flutter test test/screens/dashboard/admin_shell_test.dart`, then full `flutter analyze`, `flutter test` and `flutter build web --release` on the updated PR head. Fix any remaining failures before considering the navigation change validated.

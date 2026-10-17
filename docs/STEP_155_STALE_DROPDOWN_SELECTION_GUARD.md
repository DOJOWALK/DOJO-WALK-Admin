# Step 155 — Guard Against Stale Add Location Dropdown IDs

Date: 2026-10-18

## Previous CI result

Step 153's Admin Web Build Check completed successfully:
https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39071556035

The final workflow conclusion was `success`, covering dependency installation, full `flutter analyze`, the complete `flutter test` suite, and Flutter Web release build for commit `f98f0233ac17bf4abdf804c99cc009b1a428b4e6`.

## Step 155 implementation

Added a pure Dart helper `retainAvailableSelection` to `location_selection_state.dart`. It returns a selected ID only if the ID still exists in the latest options list.

Applied the helper to all four parent dropdowns in `add_location_dialog.dart`:
- Country
- State
- City / District
- Area / Sub-district

This prevents a dropdown from trying to render a selected value when its document is no longer present in the latest stream results, such as after deletion or parent-filtered data changes.

Added three tests covering:
- An unavailable/deleted selection becomes null.
- A currently available selection is preserved.
- A null selection stays null.

The selection-state test file now contains eight tests.

## CI for Step 155

The three Admin Web Build Check runs have now all completed successfully:
- Helper: https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39071837290
- Tests: https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39071839272
- Dialog wiring: https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39071856637

The final dialog-wiring run completed all stages successfully: dependency installation, full `flutter analyze`, full `flutter test`, and Flutter Web release build.

## Scope and safety

No Firebase schema, Firestore Rules, callable functions, import flow, or location hierarchy changed. No production import, activation, merge, or deployment occurred. PR #7 remains Draft/open; District schema/product approval remains a gate.

## Next step

Inspect the three Step 155 CI runs and confirm the final commit's full analyze, test, and web build result. Fix any failures before the next change.

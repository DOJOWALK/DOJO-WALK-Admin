# Step 153 — Dependent Dropdown Form-State Reset

Date: 2026-10-18

## Change made

Updated `lib/features/service_location/widgets/add_location_dialog.dart` so the dependent dropdown form fields receive keys tied to their parent selections:
- State dropdown key depends on selected Country.
- City / District dropdown key depends on selected Country and State.
- Area / Sub-district dropdown key depends on selected City.

This forces Flutter to recreate the dependent dropdown field when its parent changes. It prevents a FormField's internally retained value from displaying a stale child selection after the immutable selection state has correctly cleared the corresponding ID.

Commit: `f98f0233ac17bf4abdf804c99cc009b1a428b4e6`

## Scope

- No Firestore schema, Rules, callable functions, or import behavior changed.
- No District entity added.
- Existing save-as-inactive behavior retained.
- No production import, activation, merge, or deployment performed.

## Validation

The updated file was fetched back from the target branch and confirmed to contain all three parent-dependent keys. This is source-level verification only; CI for this new commit has not yet been confirmed.

The Step 152 Admin Web Build Check for dialog wiring completed successfully:
https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39071430872

That successful run tested commit `198796223585a0ce47d2c3cdfbf73044701a8ba5`, before this Step 153 change, so it must not be treated as validation of Step 153.

## Next step

Inspect the CI run for commit `f98f0233ac17bf4abdf804c99cc009b1a428b4e6`, including `flutter analyze`, the full `flutter test` suite, and the web release build. If successful, continue with Add Location tests around dependent dropdown behavior; otherwise fix failures first.

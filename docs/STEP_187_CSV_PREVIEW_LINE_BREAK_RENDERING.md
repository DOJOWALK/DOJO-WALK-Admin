# Step 187 — CSV Preview Line Break Rendering Fix

Date: 2026-10-18
Branch: `step-119-boundary-geometry`

## Change
Fixed the CSV preview subtitle formatting in `service_location_screen.dart`. Validation errors and optional source metadata now use actual Dart newline escapes so they render on separate lines instead of showing a literal backslash-n sequence.

## Verification
The Step 186 head `527a7a7af734b1dba69395c0347d97f96f5007e2` passed both `geometry-unit-tests` and `build-web`.
This Step 187 UI fix is commit `478cded0c36d448183f8ae9b071ea39fc30d2c50`; its own CI must finish before this change is reported as passed.

## Scope and safety
Display-only fix. No parser/schema change, Firebase writes, production imports, activation/deactivation, deployment, or Partner/Customer migration. Admin PR #7 remains Draft.

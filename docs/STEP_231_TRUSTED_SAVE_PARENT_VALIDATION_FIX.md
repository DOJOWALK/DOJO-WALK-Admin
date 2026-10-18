# Step 231 — Fix trusted-save parent validation and verify CI

Date: 2026-10-18

## Finding
The Admin checks for commit `a3533d867339b0de96e8e7d3eca10ee96357ff66` failed during `flutter analyze` because the obsolete variable `parentIds` was referenced twice in `lib/features/service_location/services/service_location_service.dart`. The helper `_parentIdsFromDocument` was also unused.

## Change
- Parent IDs are now validated directly from the already-filtered trusted-callable payload fields for the selected location type.
- Missing/blank parent IDs fail locally with a clear `StateError`.
- Removed the obsolete `_parentIdsFromDocument` helper.
- No Firestore Rules, Firebase production data, activation state, or deployment was changed.

## Verification
- Updated source fetched back from GitHub after commit and verified.
- Confirmed `parentIds` and `_parentIdsFromDocument` no longer occur in the service file.
- Commit: `158f6351bd071411d949d75d093edb73c266b570`
- Admin CI was queued/in progress when this report was prepared; final build/test status must be checked separately.

## Next gate
Do not tighten Firestore Rules until Admin Flutter analysis/tests/build and the remaining direct-write/import-path audit are complete.

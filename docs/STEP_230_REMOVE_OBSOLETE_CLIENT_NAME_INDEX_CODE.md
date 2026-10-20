# DOJO WALK — Step 230: Remove Obsolete Client Name-Index Code

## Change
- Removed unused dart:convert and crypto imports from the Admin service-location service.
- Removed the old client-side _normalizeName and _nameIndexId SHA-256 helpers.
- Removed the unused _nameIndexes collection getter.
- Removed obsolete parentIds/isNew parameters from the shared save helper and all five location save calls.
- Updated the service comment to state that uniqueness is enforced by the trusted server callable.
- Kept saveServiceLocationWithNameIndex as the shared persistence path.

## Verification
- Updated service file was fetched back from branch step-119-boundary-geometry and verified at blob SHA c48b69e2404952eb58f4623dbb3fc3be3964832b.
- Source checks confirm the old hash helper and _nameIndexes getter are absent and the trusted callable remains.
- Admin Web Build Check runs flutter pub get, flutter analyze, flutter test, and flutter build web --release. The run triggered for this commit was still in progress when this report was written; no PASS is claimed.
- Geometry unit-test workflow was also still in progress.

## Safety
- No Firestore Rules changes, merge, or deployment were performed.
- Keep name-index write restrictions unchanged until Admin CI is green and all relevant client write paths are reviewed.
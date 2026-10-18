# Step 145 — Area District visibility and City compatibility tests

## Changes
- Area cards include the parent City's optional District ID in search.
- Area cards display either the linked District ID or an explicit legacy/unlinked City label.
- Added tests proving that City model parsing and serialization preserve legacy documents without `districtId`, District-linked City documents, and explicit `copyWith` updates.
- This is display/test coverage only. The Area persistence schema and Firebase callable/index contract remain unchanged.

## Validation
- Service Location Geometry Tests and Admin Web Build Check were triggered for the code commits. Check their GitHub Actions status before treating this step as fully validated.

No production import, deployment, PR merge, or Customer/Partner repo changes were made.

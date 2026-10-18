# Step 221 — Name Index Parent ID Validation

Date: 2026-10-18

## Changes made
Firebase repository: `dojoplatform2026/DOJO-WALK-Firebase`  
Draft PR: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/pull/6

- Tightened `service_location_name_indexes` Rules validation so each parent ID must be a string, non-empty, and no longer than 128 characters.
- Applied validation to each parent list position for State, City, Area, and Locality index shapes.
- Added negative emulator cases for empty, non-string, and oversized parent IDs.
- Kept expected parent counts by collection: Country 0, State 1, City 2, Area 3, Locality 4.
- Admin service review confirms the save transaction deletes the old index only when the name/hierarchy-derived index ID changes, then creates/sets the new index and writes the location document in the same transaction. This matches immutable index identity fields in Rules.

## Commits
- Rules commit: `e329a5de5c759a880ed03bc6af973b911683c096`
- Tests commit / current PR head: `dfb6b23c9b4c3809679b20d76e3404ce9f0f0230`

## CI status at report time
- Workflow YAML validation for run #156: success.
- Firestore Rules Emulator Tests for run #156: test step completed successfully; workflow cleanup was still in progress at the last check.
- Trusted Location Geometry and Callable Tests for run #145: success.
- Workflow YAML validation for run #156: success.

## Remaining security limitation
Rules still cannot verify that the document ID is the SHA-256 of the normalized tuple. The Admin client computes it; consider moving authoritative index writes behind a trusted callable/server path before production rollout.

## Merge/deploy status
PR #6 remains open and draft. Not merged. No production deployment performed.

# DOJO WALK — Step 228: Admin Save Methods Use Trusted Callable

## Completed
Updated `lib/features/service_location/services/service_location_service.dart` so the shared `_saveUniqueNamedDocument` path invokes Firebase callable `saveServiceLocationWithNameIndex` instead of directly writing the name index and location document in a client transaction.

This shared path is used by `saveCountry`, `saveState`, `saveCity`, `saveArea`, and `saveLocality`. It now:
- Maps collection names to the five server-supported location types.
- Sends only each type's approved editable fields.
- Sends the explicit hierarchy parent IDs and stable document ID.
- Checks the callable response returns the expected ID.
- Leaves activation and boundary fields to their separate trusted workflows.

## Verification
- Admin service update commit: `6da05014201a24459de561b191d60c5c37fa2548`
- Updated file fetched from GitHub and verified to contain the callable invocation and no client transaction in the shared save helper.
- Firebase callable CI for server commit `0a42c73b5372ff4f23f7d039b1d7ac23f6deb728` completed successfully:
  - Trusted Location Geometry and Callable Tests: success
  - Firestore Rules Emulator Tests: success
- These CI runs validate the Firebase server commit, not the Admin Flutter edit. An Admin Flutter build/test has not been run in this step.

## Still required
- Audit any separate bulk-import or direct-write paths outside the shared save helper; this step does not claim all imports are migrated.
- Add/execute Admin-side tests and validate the callable payload contract end to end.
- Only after all write paths are migrated and verified should direct client name-index writes be restricted in Firestore Rules.
- PR #6 remains draft/unmerged; no deployment occurred.

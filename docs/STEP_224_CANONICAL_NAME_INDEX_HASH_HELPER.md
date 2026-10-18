# DOJO WALK — Step 224: Canonical Name-Index Hash Helper

## Work completed
Added a server-side TypeScript helper in the Firebase repository:
- `functions/src/location_name_index.ts`
- `functions/test/location_name_index.test.cjs`

The helper uses Node's SHA-256 implementation and UTF-8 bytes of the JSON tuple `[collectionPath, trimmedParentIds, normalizedName]`, matching the current Dart client's hash contract. It normalizes names with trim, lowercase, and collapsed whitespace; validates supported collection names, name length, parent ID lengths, and expected parent counts for all five hierarchy levels.

## Tests added
1. Name normalization.
2. Exact hash contract compared with an independently calculated SHA-256 value.
3. Different parent chains produce different IDs.
4. Invalid collection, empty name, and wrong parent count are rejected.
5. Empty and oversized parent IDs are rejected.

## GitHub verification
- Helper commit: `43822fb1ca58aa6962c6ea312b773ac4acc65e91`
- Test commit: `f8a06dc1d319316bfcc086c9a21e1c620c73d126`
- Both new files were fetched from branch `fix/location-index-import-rules` after commit and verified present.
- CI was triggered for the test commit. At the time of writing, the trusted-location build/tests and Firestore Rules emulator tests were still in progress; workflow YAML validation had succeeded.

## Important limitations
This is a foundational helper, not the complete Step 223 callable migration. The callable does not yet invoke this helper, Admin's five save methods have not yet been migrated, and direct client index writes have not been restricted. No production deployment or PR merge was performed.

## Next
Integrate the helper into a trusted callable that validates the full hierarchy and performs atomic location/index writes; migrate every Admin write path; add transaction and authorization tests; only then tighten Firestore Rules.

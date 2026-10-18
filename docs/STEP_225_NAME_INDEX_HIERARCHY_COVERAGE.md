# DOJO WALK — Step 225: Name-Index Hierarchy Coverage

## Completed
Added `functions/test/location_name_index_hierarchy.test.cjs` to cover all five supported hierarchy levels with the exact parent-count contract:
- Country: 0 parents
- State: 1 parent
- City: 2 parents
- Area: 3 parents
- Locality: 4 parents

The test also checks that generated IDs are 64-character lowercase hexadecimal SHA-256 strings and rejects normalized names longer than 120 characters.

## Verification
- Test commit: `09075be8812beb011905d6ce2ccca137000321af`
- New test file was fetched from the PR branch and verified present.
- Draft PR #6 remains open and unmerged.
- CI triggered for this commit:
  - Trusted Location Geometry and Callable Tests: in progress at check time.
  - Firestore Rules Emulator Tests: in progress at check time.
- No claim is made that the new tests have passed until the workflow reports success.

## Scope boundary
The hash helper and tests are foundational only. The trusted callable has not yet been implemented or wired to the Admin client. The five Admin save paths still use the client transaction. Direct name-index writes have not been restricted. No deployment or merge was performed.

## Next
Implement the trusted callable and client migration as one coordinated change, preserving full field data, hierarchy checks, existing activation controls, and rename/reparent index cleanup. Tighten Rules only after every write path is migrated and CI is green.

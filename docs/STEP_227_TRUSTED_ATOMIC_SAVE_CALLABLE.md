# DOJO WALK — Step 227: Trusted Atomic Save Callable

## Implemented
Added exported callable `saveServiceLocationWithNameIndex` to `functions/src/index.ts` on the Firebase PR branch.

The callable:
- Requires Firebase Authentication and an active `admin_users/{uid}` record with an admin role.
- Accepts only country, state, city, area, or locality.
- Applies the shared server-side payload validator and a narrower mutable-field allowlist.
- Rejects client changes to boundary and activation fields; those remain separate trusted workflows.
- Validates that referenced parents exist and checks ancestry consistency for City, Area, and Locality.
- Rejects parent changes for an existing location.
- Computes the SHA-256 name-index ID on the server.
- Checks name collisions and writes the location and name index in one Firestore transaction.
- Creates new locations inactive; existing activation and boundary fields are not overwritten by the save payload.

## Verification
- Callable code commit: `0a42c73b5372ff4f23f7d039b1d7ac23f6deb728`
- Callable file fetched from GitHub after commit and verified.
- CI runs for this commit were in progress when this report was written:
  - Trusted Location Geometry and Callable Tests
  - Firestore Rules Emulator Tests
- Build/test success is not claimed until the workflow results complete.

## Remaining work / safety
- Admin Flutter save methods and bulk/import writes are not yet migrated to this callable.
- Do not tighten direct name-index Firestore Rules until all Admin write paths are migrated and tested.
- The PR remains draft and unmerged; no production deployment occurred.

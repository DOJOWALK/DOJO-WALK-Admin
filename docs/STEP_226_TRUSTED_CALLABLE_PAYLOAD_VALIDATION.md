# DOJO WALK — Step 226: Trusted Callable Payload Validation

## Completed
Added a schema-validation layer to `functions/src/location_name_index.ts` for the planned trusted service-location save callable.

The validator:
- Uses per-type allowlists for country, state, city, area, and locality payloads.
- Rejects unknown fields rather than silently accepting them.
- Validates required name and parent ID shapes and bounds.
- Validates country code shape.
- Returns a copy with the trimmed name.

Added `functions/test/location_name_index_payload.test.cjs` with cases for all five payload types, unknown-field rejection, malformed parents, empty/oversized names, and invalid country code.

## Verification
- Helper update commit: `6f17fd8145f11b095960bf3de55f73a4a056b00d`
- Test commit: `6fa07214ad170e6af6e2ca337c36131d7f9525f4`
- Both changed files were fetched from the PR branch after commit and verified present.
- CI workflows were queued for commit `6fa07214ad170e6af6e2ca337c36131d7f9525f4`:
  - Trusted Location Geometry and Callable Tests: queued
  - Firestore Rules Emulator Tests: queued
- Test success is not yet confirmed.

## Security boundary
This is only a schema guard. It is not yet called from a callable and does not itself authenticate admins, validate the stored parent chain, enforce immutable parent relationships, verify boundary state, or atomically save the location and hash index. The Admin client still writes the index directly. Do not tighten index Rules until callable and all client/import paths are migrated.

No PR merge or production deployment was performed.

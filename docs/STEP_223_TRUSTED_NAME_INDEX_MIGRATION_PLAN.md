# DOJO WALK — Step 223: Trusted Name-Index Write Migration Plan

## Status
- Step: 223
- Result: implementation boundary and migration safety plan documented
- Production changes: none
- Firebase deployment: none
- PR merge: none

## Why this is not a rules-only fix
Firestore Rules can validate the shape of `service_location_name_indexes/{indexId}`, but cannot recompute SHA-256 over the same UTF-8 JSON tuple used by the Admin client and prove that the document ID matches the payload. A trusted server-side write path is needed for that integrity guarantee.

## Current client write path
The Admin client method `_saveUniqueNamedDocument` computes the normalized name and hash index ID, then uses a Firestore transaction to read the target document and index, detect collisions, remove a prior index when the name/parent tuple changes, and write the index and location document together. The public save paths are `saveCountry`, `saveState`, `saveCity`, `saveArea`, and `saveLocality`.

These save paths also enforce important application constraints before writing:
- state belongs to its country and cannot be re-parented;
- city belongs to the selected country/state and cannot be re-parented;
- area inherits and validates the city hierarchy and may require a verified boundary when active;
- locality inherits and validates the area hierarchy;
- new service locations must be created inactive and activation is handled separately.

A replacement callable must preserve these checks or strengthen them server-side. Moving only the hash calculation to a callable would not be sufficient.

## Safe implementation sequence
1. Add a callable for a narrowly defined named-location save contract. Accept a supported location type, document ID (or server-generated ID), name, parent IDs, and a strictly allow-listed location payload. Never accept client-supplied index IDs or trust client-supplied normalized names.
2. Require an authenticated, active admin. Re-check admin status inside the transaction. Match the existing project's admin authorization model intentionally; do not silently broaden a super-admin-only callable to every admin role.
3. In the callable, validate the complete parent chain from Firestore, location type, immutable parent relationships on update, name length, allowed fields, and inactive-on-create behavior. Preserve existing verified-boundary/activation safeguards.
4. Recompute the exact existing hash contract: UTF-8 SHA-256 of JSON encoding of `[collectionPath, trimmed parent IDs, normalized name]`; normalization is trim, lowercase, and collapse whitespace.
5. In one Firestore transaction, read all required documents and the target index, reject a collision owned by another document, write the named location and index atomically, and delete the old index on rename. Keep all transaction reads before writes.
6. Migrate each Admin save method and any import/bulk-write path to the callable. Check all references to `_saveUniqueNamedDocument` and any direct index writes before changing Rules.
7. Add unit/integration coverage for exact hash compatibility, duplicate names under same parents, same name under different parents, rename, immutable-parent rejection, invalid hierarchy, wrong/missing hash, inactive-admin denial, collision rollback, and stale-index cleanup.
8. Only after every client write path has migrated and CI passes, tighten Rules to deny direct client create/update/delete of name-index documents. Do not apply that restriction prematurely; it would break the current Admin save path.

## Step 223 decision
Do not introduce a partial callable or deny direct index writes yet. Either change without migrating every caller would leave inconsistent trust boundaries or break create/rename operations. The next coding pass should implement the callable and Admin migration together, with tests, then tighten Rules in a separate verified change.

## Verification limitations
This step is a code-path review and migration design note. It does not claim that a callable has been implemented, that tests ran, or that production is protected against a mismatched hash ID. Existing CI status belongs to the previously verified PR head and must be rechecked after code changes.

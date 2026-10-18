# Step 222 — SHA-256 Name Index Trust Boundary Audit

Date: 2026-10-18

## Repositories reviewed
- Admin: `dojoplatform2026/DOJO-WALK-Admin`, branch `step-119-boundary-geometry`
- Firebase: `dojoplatform2026/DOJO-WALK-Firebase`, draft PR #6, branch `fix/location-index-import-rules`
- PR: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/pull/6

## Findings
1. Admin computes name-index IDs client-side using SHA-256 over JSON-encoded `[collectionPath, trimmed parentIds, normalizedName]`.
2. Admin then writes the index document and target location document in the same Firestore transaction.
3. Current Firestore Rules validate the index payload shape, hierarchy parent count, parent ID strings and timestamp; they do not calculate the SHA-256 ID from the payload.
4. A repository search did not find an existing callable dedicated to authoritative name-index writes. Existing callable functions cover boundary review, activation and status changes.
5. Therefore an active super_admin client can still submit a shape-valid index payload under a document ID that does not match the payload's expected hash. This is an integrity gap, not an authorization bypass for non-admins.

## Recommended next implementation
- Add a trusted callable/server transaction for creating/updating a named location and its index, or otherwise centralize index writes behind a trusted server API.
- Preserve the existing hash algorithm exactly: JSON array ordering, trimmed parent IDs, normalized lower-case/whitespace-collapsed name, UTF-8 and SHA-256.
- Make the server validate the location type, parent chain, uniqueness, and target document before atomically writing location + index and deleting a stale prior index.
- Restrict direct client writes to `service_location_name_indexes` once all Admin write paths are migrated.
- Add emulator/integration tests for mismatched hash ID, duplicate name, rename, reparent, transaction rollback, and active/inactive admin authorization.
- Do not change rules to deny client writes before the Admin app migration ships; that could break location creation/renaming.

## Latest CI confirmation for current PR head
Head: `dfb6b23c9b4c3809679b20d76e3404ce9f0f0230`
- Firestore Rules Emulator test step: success (run #156).
- Workflow YAML validation: success (run #156).
- Trusted Location Geometry and Callable Tests: success (run #145).

## Status / safety
PR #6 remains open, draft, and unmerged. No production deployment was performed. The SHA-256 integrity limitation remains open until server-authoritative index writes and Admin migration are implemented and tested.

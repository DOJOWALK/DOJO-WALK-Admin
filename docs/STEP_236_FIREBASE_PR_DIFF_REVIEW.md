# Step 236 — Firebase PR #6 Diff and Coverage Review

Date: 2026-10-18

## Scope checked
- Repository: `dojoplatform2026/DOJO-WALK-Firebase`
- PR: [#6 — Harden service location index and import audit rules](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/pull/6)
- Base: `feature/trusted-location-activation` (`80b9df5602d85fbbeb063071711743d7dfb37b6c`)
- Head: `fix/location-index-import-rules` (`edad8502e590f1cedb3c105130dae9792bcf63a9`)
- PR remains open and draft; no merge or deployment was performed.
- Reviewed all 7 changed paths returned by GitHub: Firestore rules, callable implementation, helper, three helper test files, and Rules emulator tests.

## Positive findings
1. Client SDK writes to `service_location_name_indexes` are explicitly denied; trusted callable writes the index and location in one Firestore transaction.
2. Callable validates authenticated active admin role, location type/ID, payload allowlist, required parents, parent-chain consistency, immutable parent IDs on update, and duplicate name-index collisions.
3. New locations are initialized inactive. Existing activation/boundary fields are excluded from the callable's mutable-field list and are not overwritten on update.
4. Import audit metadata now requires the six expected fields, rejects extra fields, bounds string lengths, binds `importedBy` to the caller, and requires server request time for `importedAt`. Updates/deletes remain denied.
5. Tests cover canonical hash compatibility, normalization, hierarchy parent-count constraints, malformed payloads, and client-side index-write denial.
6. Latest reported CI evidence from Step 235 shows both Rules Emulator Tests and Trusted Location Geometry and Callable Tests passed for the combined head commit.

## Review gaps / follow-up
- **Coverage gap (not a confirmed runtime defect):** the new name-index tests exercise pure helper functions and Rules tests exercise direct SDK denial, but the reviewed diff does not add focused callable integration tests for `saveServiceLocationWithNameIndex`. Add emulator/callable coverage for unauthorized/inactive actors, parent-chain mismatch, duplicate names, rename index replacement, rejected parent changes, and atomic rollback when one write fails.
- **Import status semantics remain intentionally loose:** `status` and `verificationStatus` are bounded non-empty strings, not enums. The PR description acknowledges this. Before production rollout, compare all actual Admin-written values and decide whether to define allowed values; do not invent an enum without confirming current model usage.
- **Index identity is trusted-server enforced:** Firestore Rules cannot recompute the SHA-256 document ID. This is acceptable only while all client index writes remain denied and every write path uses the trusted callable.
- **Operational limitation:** CI passing does not mean production rules/functions have been deployed. Keep PR draft and do not merge/deploy until the follow-up coverage and import-value review are resolved.

## Result
**Step 236: REVIEW COMPLETE — no unexpected changed paths found in the GitHub file list; no production changes made.** The reviewed patch appears directionally sound for closing direct index writes. Callable transaction behavior still needs dedicated integration tests before treating this path as fully verified.

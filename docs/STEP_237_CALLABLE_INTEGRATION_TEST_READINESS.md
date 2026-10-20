# Step 237 — Callable Integration-Test Readiness

Date: 2026-10-18

## Scope
Reviewed the Firebase feature branch's Functions test setup before adding callable integration tests.

- Branch: `fix/location-index-import-rules`
- Head reviewed: `edad8502e590f1cedb3c105130dae9792bcf63a9`
- Functions package script: `npm test` runs `npm run build && node --test test/*.test.cjs`.
- TypeScript config compiles `src/**/*.ts` into `lib`; tests import compiled helpers from `lib`.
- Existing new name-index tests cover normalization, deterministic hash, parent count, and payload allowlisting. They do not invoke the exported callable or test its Firestore transaction.

## Test plan for `saveServiceLocationWithNameIndex`

### Authorization
- No Firebase auth => `unauthenticated`.
- Missing admin profile, inactive admin, and unsupported role => `permission-denied`.
- Active `admin` and `super_admin` can proceed for valid payloads.

### Payload and hierarchy
- Unknown location type, malformed ID, unknown payload key, missing/oversized name, invalid parent ID => `invalid-argument`.
- Missing parent, mismatched state/city/area ancestry => `failed-precondition`.
- Attempt to move an existing location to a different parent => `failed-precondition`.
- Attempts to pass activation or boundary fields => rejected by the callable allowlist.

### Index and transaction behavior
- First create writes one inactive location plus the canonical index.
- Same normalized name under the same parent returns `already-exists` for another location.
- Same name under a different parent is allowed.
- Rename writes the new index and removes the old index only when the old index points back to this location.
- Failed operation leaves neither partial location nor partial index writes.
- Repeating a save with unchanged name/parent preserves a single canonical index.

## Important implementation detail
A meaningful callable test needs a Firestore emulator and an invocation path that exercises the exported callable handler with authenticated request context. Pure helper tests or Rules tests alone cannot prove the callable's transaction and authorization behavior. Confirm the existing CI workflow can start the Functions/Firestore emulators and seed `admin_users` before implementing the integration suite; do not add a test that merely mocks away Firestore transaction semantics and then call it emulator coverage.

## Result
**Step 237: TEST READINESS REVIEW COMPLETE.** The gap is confirmed. This step records the exact acceptance cases; no Firebase production data, deployment, or PR merge was performed. Next: inspect the repository's emulator workflow/configuration, then implement callable-level tests and verify the CI run on the PR head.

# Step 131 — Additive Trusted District Contract Helpers

Date: 2026-10-19
Firebase repository: `DOJO-WALK-Firebase`
Branch: `fix/location-index-import-rules`
Commit: `13f824e78d2ddaac449a668ec3acc6a3cc6aa261`

## Implemented
- Added `functions/src/district_schema_contract.ts` with safe parent-ID normalization and explicit District → City → Area ancestry consistency helpers.
- Added `functions/test/district_schema_contract.test.cjs` with tests for valid IDs, unsafe IDs, unexpected client-controlled fields, mismatched City District, consistent ancestry, and mismatched Area ancestry.

## CI
- Test Firestore Security Rules — run 237 — **PASS**.
- Trusted Location Geometry and Callable Tests — run 226 — **PASS**.

## Important scope limitation
These helpers are additive and deliberately **not wired into the existing production callable or collection allowlist** yet. Existing callable behavior has not been changed by this step. The tests validate the new pure contract helpers and the existing workflow suites; they do not prove that District CRUD is available end-to-end.

## Next required work
1. Extend name-index schema while preserving legacy index compatibility.
2. Implement District save/status callable paths and transactional parent validation.
3. Update activation/deactivation descendant guards and Firestore Rules tests.
4. Wire Admin model/service/UI to the trusted contract only after backend tests pass.

## Safety
No Customer or Partner changes. No merge, deployment, production import, or production Firestore writes.

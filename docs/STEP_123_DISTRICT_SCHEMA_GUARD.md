# Step 123 — District Schema Guard Regression

Date: 2026-10-19

## Change made
Added two unit tests to Firebase PR #6 branch `fix/location-index-import-rules`:

- `service_districts` is rejected as an unknown collection by the current name-index contract.
- A City payload containing `districtId` is rejected by the current strict allowlist.

Commit: `35548005c1cce66bc3d2ba7480ad1d15fe49b0eb`.

These are guard tests, not implementation of District. They intentionally keep the current schema explicit so the Admin cannot accidentally submit District fields that Firebase does not support.

## Verification status
- Trusted Location Geometry and Callable Tests: running (workflow run `39160239017`).
- Test Firestore Security Rules: running (workflow run `39160239016`).

## Next gate
Wait for both CI workflows. If they pass, the next implementation step is a coordinated schema proposal for Admin + Firebase; do not enable CSV database writes or deploy until that design, migration compatibility, and callable/Rules tests are reviewed.

No PR was merged, no Firebase deployment occurred, and no production records were written.

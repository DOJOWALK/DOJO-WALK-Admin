# Step 139 — Concurrent District Deactivation / City Activation Test

## Purpose
Exercise the race between activating a District-aware City and deactivating its District using Firestore Emulator integration tests.

## Test behavior
A randomized test fixture starts with an active Country, State and District, plus an inactive City with a valid verified boundary. It runs the trusted City activation callable concurrently with District deactivation and asserts:
- exactly one competing transition succeeds;
- if City activation wins, the District remains active;
- if District deactivation wins, the City remains inactive.

The test checks the guard-write concurrency contract introduced in Step 138. It runs only when `FIRESTORE_EMULATOR_HOST` is configured and refuses to run without the emulator.

## Changes
Firebase test file: `functions/test/activate_service_location.integration.test.cjs`
Firebase commit: `5012aeba6bb2c8be989dce3315588e769413f1f9`

## CI
- Trusted Location Geometry and Callable Tests: [run 39167606630](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39167606630)
- Test Firestore Security Rules: [run 39167606561](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39167606561)

CI was still running when this report was created; confirm final conclusions before treating Step 139 as validated. No merge, deployment, or production data import was performed.

# Step 239 — Callable Emulator Tests Added

Date: 2026-10-18

## Change
Added `functions/test/location_name_index_callable.test.cjs` on Firebase branch `fix/location-index-import-rules`.

Commit: `87acf1ae065ee9295ff793c84a3be63b4b473a92`

File:
https://github.com/dojoplatform2026/DOJO-WALK-Firebase/blob/fix/location-index-import-rules/functions/test/location_name_index_callable.test.cjs

## Coverage added
- Reject unauthenticated callable request.
- Reject missing and inactive admin profiles.
- Reject activation fields included in the client payload and verify no index was written.
- Invoke the exported v2 callable handler directly with authenticated request context while the workflow starts the Firestore Emulator.
- Verify new country creation writes the location and canonical index and forces `isActive: false`.
- Verify duplicate name is rejected without replacing the existing index.
- Verify rename updates the location, removes the old index, and creates the new index.

The test uses unique IDs and schedules cleanup of the created admin/location/index documents.

## CI status at report time
GitHub Actions run 154 was triggered by this commit:
https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39143881014

At the time of this report, dependency installation had passed and the emulator build/test step was still in progress. Therefore **the new tests are committed but not yet confirmed passing**. Re-check this run before treating the change as validated.

## Not done
- No PR merge or Firebase deployment.
- No claim that production data was changed.
- Parent-hierarchy, different-parent duplicate, idempotent repeat-save, and transaction-failure rollback scenarios are not covered by this initial batch and remain follow-up coverage.

# Step 238 — Callable Integration Test Harness Inspection

Date: 2026-10-18

## Scope
Inspected the Firebase feature branch `fix/location-index-import-rules` at HEAD `edad8502e590f1cedb3c105130dae9792bcf63a9`. This step was a read-only configuration review; no Firebase code, rules, deployments, or production data were changed.

## Findings

1. `firebase.json` configures Functions source/runtime and Firestore rules, but does not declare emulator ports or an explicit Functions emulator.
2. `.github/workflows/test-location-geometry.yml` installs Node 22 and Java 21, then runs `firebase emulators:exec --project demo-dojo-walk-tests --only firestore "cd functions && npm test"`. Thus the current test job starts only the Firestore emulator.
3. `functions/package.json` runs `npm run build && node --test test/*.test.cjs`. Existing test file `functions/test/location_name_index_payload.test.cjs` tests payload validation helpers, not the exported callable or its Firestore transaction.
4. The callable uses Firebase Functions v2 `onCall`, initializes Admin SDK at module load, and calls Firestore transactions. The current harness therefore does not yet prove authenticated callable behavior, role checks, or atomic location/index writes.
5. A proper integration test should invoke the callable with request auth context and use the Firestore emulator for transaction assertions. Avoid claiming integration coverage from helper-only tests or replacing the transaction with a fake.

## Recommended implementation sequence

- Add a focused callable test harness compatible with the installed Firebase Functions v2 version; inspect lockfile/dependency support before selecting a test helper.
- Ensure Admin SDK points at the Firestore emulator and isolate test data by unique IDs / cleanup.
- Cover unauthenticated and inactive/missing admin rejection; invalid payload/parent and hierarchy mismatch; duplicate name under the same parent versus same name under different parents; rename index cleanup; and idempotent saves.
- Run the actual workflow command and report the observed CI result. Keep the PR draft until these tests pass and status/verification enum validation is separately reviewed.

## Outcome
**Configuration review complete; callable integration tests are still a gap.** Existing emulator CI only starts Firestore, which is sufficient for direct Firestore integration if the test invokes the exported handler correctly, but does not itself invoke the callable. No code-level test was added in this step.

## References
- Firebase branch: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/tree/fix/location-index-import-rules
- Emulator workflow: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/blob/fix/location-index-import-rules/.github/workflows/test-location-geometry.yml
- Function package: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/blob/fix/location-index-import-rules/functions/package.json
- Existing helper tests: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/blob/fix/location-index-import-rules/functions/test/location_name_index_payload.test.cjs
- Firebase PR #6: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/pull/6

# Step 205 — Firebase Emulator Test Execution Audit

Date: 2026-10-18

## Result

**Existing GitHub Actions run: PASS. Root Firestore Rules unit suite: NOT VERIFIED by that run.**

Repository: `dojoplatform2026/DOJO-WALK-Firebase`
Review branch: `step-138-partner-submission-negative-tests`
Branch head: `2676e313476254279d041bf7db0a3ea9844b429f`

Verified GitHub Actions run:
- Run #139: [Tests: reject invalid Partner application submissions](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39070246869)
- Conclusion: `success`
- Job: `Build, geometry and callable integration tests`
- The run's job summary reports setup, dependency installation, and the Firestore Emulator test step all completed successfully.

## Important coverage gap

The repository-root `package.json` defines:
```json
"test": "node --test test/*.test.mjs"
```
and the root contains `test/firestore.rules.test.mjs`, which uses `@firebase/rules-unit-testing` to exercise Firestore Security Rules.

However, the workflow `.github/workflows/test-location-geometry.yml` runs:
```sh
npx --yes firebase-tools emulators:exec --project demo-dojo-walk-tests --only firestore "cd functions && npm test"
```
It runs `functions/npm test`, not the repository-root `npm test`. Therefore this green CI run proves the configured Functions/geometry/callable test job passed, but **does not prove the root `test/firestore.rules.test.mjs` suite ran or passed**.

## Safety / deployment

- No production Firebase rules were deployed.
- No rules were copied between repositories.
- The deployed production rules revision has not been verified here.
- The Partner app's bundled rules and the Firebase review-branch rules still need an authoritative source-of-truth decision before syncing.

## Next action

Update the review-branch CI workflow so it runs both the repository-root Firestore Rules unit suite and the Functions tests under the Firestore Emulator, then verify the new Actions run and its exact commit. Keep this on the review branch; do not merge or deploy without approval.

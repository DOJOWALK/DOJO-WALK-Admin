# DOJO WALK — Step 146: CI and Test-First Readiness Check

Date: 2026-10-18
Admin PR: #7 — `step-119-boundary-geometry`
Firebase PR: #5 — `step-138-partner-submission-negative-tests`
Status: repository/CI inspection only; no code or schema changes.

## PR state checked
- Admin PR #7 is open, Draft, and unmerged. GitHub currently reports `mergeable: false`; do not merge.
- Firebase PR #5 is open, Draft, and unmerged. GitHub reports `mergeable: true`, but that alone is not approval to merge.
- Both PRs have outstanding product/schema and release gates. They are not a coordinated District-schema implementation yet.

## Current checks inspected
- Firebase trusted location geometry/callable workflow run #139: completed, success.
  https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39070246869
- Firebase Firestore Rules workflow run #150: completed, success.
  https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39070246822
- Admin PR body records a previous full-project Flutter analyze, test and no-deploy web build success at commit `2366912dde77e98b94abad75f134f1c5fda604ba`, and a focused geometry/parser/reference-data success at run #39049452059. These are earlier validation points, not proof that a District schema change has been tested.
- No workflow run was returned for the latest Admin documentation-only commit `36815c209a6d72c23ec0eec98e4ae5b18ddadf04`. The combined commit status query also returned no status entries; this is not a test failure, but means this commit itself has no reported checks through the inspected endpoint.

## Confirmed commands
Admin `pubspec.yaml` is a Flutter project. PR #7's no-deploy build workflow is intended to run:
1. `flutter pub get`
2. `flutter analyze`
3. `flutter test`
4. `flutter build web --release`

Firebase `functions/package.json` defines:
1. `npm run build` (TypeScript compile)
2. `node --test test/*.test.cjs` via `npm test`
3. Firestore Rules emulator tests are run by the separate repository workflow.

## Safe next implementation slice
The next code change should not introduce District fields yet. First:
1. Read the exact current Admin ServiceLocation models and Add Location save paths.
2. Add/confirm focused tests for current City/District labels, parent selection and CSV preview mapping without changing persisted schema.
3. Add a contract test/documented fixture proving source columns State, District, City and Area are not silently collapsed into a single entity.
4. Once product meaning is approved, add District support jointly to Admin + Firebase and extend emulator tests before using the new field.

## Blockers
- District versus Service City meaning and one-to-one/one-to-many parent rules are not approved.
- Admin PR #7 reports `mergeable: false` and remains Draft.
- Official current LGD source bytes and UP/NCR boundary-source reconciliation remain pending as stated in PR #7.
- No production deployment/import/activation or merge was performed.

## Next step
Step 147: inspect current Add Location and CSV preview parser tests, then add a focused non-breaking contract test for the four distinct source columns. Do not change production schema or import behavior.

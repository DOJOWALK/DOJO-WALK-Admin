# Step 131 — Partner Onboarding Emulator Regression Tests

Date: 2026-10-18  
Status: **Implemented on a draft Firebase review PR; both relevant GitHub Actions workflows passed.**

## Changes

Firebase repository: `dojoplatform2026/DOJO-WALK-Firebase`  
Branch: `step-131-partner-onboarding-emulator-tests`  
Draft PR: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/pull/4

Commits:
- Tests: `92faa344b93c05789caae2771a85424f95286080`
- Rules guard: `e91d7370c28a1eaea77f3906af19b98e294e1e3f`

### Emulator tests added

Updated `test/firestore.rules.test.mjs` with tests for:
1. Owner creates the exact initial Partner onboarding draft payload (including current city/state/area/legacy zones/travelMode fields).
2. Owner cannot create a walker document under another UID.
3. Owner can update location fields on an existing `in_progress` draft.
4. Owner cannot change `isApproved` or `status` through ordinary draft editing.
5. Owner cannot set `applicationSubmitted=true` through an ordinary draft update.
6. The explicit `in_progress` → `under_review` submission transition is allowed with submission timestamps.

### Rules correction

In the ordinary owner-update path for `walkers/{walkerUid}`, the Rules now require `applicationSubmitted` to remain equal to the stored value. This prevents a draft edit from bypassing the dedicated submission transition. The separate explicit submission transition remains responsible for changing the status to `under_review`.

The change is narrowly scoped; it does not grant Partner control over approval fields.

## CI status at report creation

GitHub Actions runs were started for head commit `e91d7370c28a1eaea77f3906af19b98e294e1e3f`:
- Test Firestore Security Rules — run `39067829446`: **success**. Both workflow YAML validation and the Firestore Rules Emulator test job completed successfully; job step `Run Firestore Emulator tests` passed.
- Trusted Location Geometry and Callable Tests — run `39067829625`: **success**. The geometry/callable integration job completed successfully.

These results validate the checked-in review branch at head `e91d7370c28a1eaea77f3906af19b98e294e1e3f`. They do not prove that deployed production Rules match this branch.

## Not done

- No local Emulator execution from this chat environment.
- No verification that deployed production Rules match this branch.
- No merge or deployment. PR #4 is draft and targets `feature/trusted-location-activation`.
- The current Partner app remains on its existing branch; this PR tests its observed payload shape against the Firebase review Rules, not an app release.

## Next checks

- [x] Read final CI conclusions and job steps for both runs — both succeeded.
- [x] No CI failure was reported in these runs.
- [ ] Confirm the explicit application submission UI writes the expected fields and status transition.
- [ ] Review Partner app and Firebase PR together before any merge/deploy.

# Step 130 — Firebase Emulator Test Readiness for Partner Onboarding

Date: 2026-10-18  
Status: **Test harness inspected; Partner-specific test cases are designed but not executed or added.**

## Existing Firebase Rules test harness

Inspected on Firebase repository `main`:

- `package.json` blob: `bf603e9a9a6ab4cddd6f5be1a0c2862356043127`
- `test/firestore.rules.test.mjs` blob: `3b66a1e1b64d046861b841c1694254c07e67e930`
- `firebase.json` blob: `0207c3fc808f51c418117f7e1facf13cf1a32b71`

The Firebase Rules workspace uses Node's built-in test runner, `@firebase/rules-unit-testing`, Firebase SDK, and Firebase CLI. Its configured script is `npm test` → `node --test test/firestore.rules.test.mjs`. The test initializes a Rules test environment using the repository's checked-in `firestore.rules`; `firebase.json` configures that Rules file. The inspected config does not itself establish that the Emulator is running or that deployed Rules match this source.

Existing tests cover Service Location access, active Super Admin authorization, boundary references, and other service-location rules. In the inspected file, no Partner walker-create or onboarding-draft update test was found.

## Exact Partner test scenarios required

Test against the exact payload shape from Partner source, not a simplified guessed payload:

1. **Create valid initial walker profile**
   - Authenticated owner creates `walkers/{uid}` with the current Personal Details payload.
   - Current source comparison predicts denial because create payload includes location/workflow fields not in the create allowlist.
2. **Reject another user's walker profile**
   - Owner must not create/update `walkers/{otherUid}`.
3. **Existing `in_progress` draft: location update**
   - Start with a valid existing draft fixture.
   - Submit exact Work Location changes: `city`, `state`, `area`, `zoneName`, `zoneNames`, `zones`, `travelMode`, `updatedAt`.
   - Current source comparison predicts denial if any excluded affected key changes.
4. **Existing draft: Personal Details update**
   - Test personal-only fields separately from the optional location fields.
   - Verify a profile-only update does not needlessly change location fields.
5. **Privilege protection**
   - Owner cannot change `isApproved`, `isActive`, privileged status, or review/approval fields.
6. **Application state guard**
   - Submitted or non-`in_progress` applications cannot be restarted through the ordinary onboarding path.
7. **Field types and invariants**
   - Invalid type, missing required field, invalid DOB/timestamp, or inconsistent `userId` is rejected.
8. **Regression across the approved contract**
   - Approved create and draft-update payloads succeed; prohibited privilege changes still fail.

## Least-privilege contract decision needed

Before implementation, choose and document one of these approaches:

- **Client-first:** have Partner send only fields permitted by the agreed create/update Rules, if workflow semantics allow it; or
- **Rules contract update:** allow only the required onboarding fields and validate their types and safe state transitions, while preserving admin-only approval controls.

Do not blindly append every client field to the allowlist. In particular, `applicationSubmitted`, `status`, `isActive`, and `isApproved` need deliberate create/update semantics and privilege protection.

## Step 130 checklist

- [x] Confirmed a Rules unit-test harness exists in Firebase repository source.
- [x] Confirmed current npm test script and Rules file path.
- [x] Designed exact create/update and privilege test cases.
- [ ] Add Partner-specific fixtures/tests to the appropriate Firebase review branch.
- [ ] Run Firebase Emulator suite and retain logs/results.
- [ ] Verify deployed Rules revision through authorized release process.
- [ ] Implement approved least-privilege fix.
- [ ] Run Partner app tests and cross-repo CI.

**Safety:** This step is documentation/test planning only. No test suite was executed, no source code or Rules were modified, and no production writes, deployment, activation, or merge occurred.

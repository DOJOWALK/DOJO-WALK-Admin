# Step 234 — Name Index Client-Write Denial Patch

Date: 2026-10-18

## Repositories and refs

- Firebase repository: `dojoplatform2026/DOJO-WALK-Firebase`
- Firebase branch / open Draft PR #6: `fix/location-index-import-rules`
- Admin documentation branch: `step-119-boundary-geometry`

## Change made

### Firestore Rules

Updated `firestore.rules` so `service_location_name_indexes` remains readable by active admins under the existing `isAdmin()` helper, but denies all client SDK create/update/delete operations. The client-side index shape helper was removed from this match because it no longer authorizes any client write.

Rationale: the trusted `saveServiceLocationWithNameIndex` callable uses the Admin SDK and is responsible for atomically creating/updating the location document and its name-index document. Firestore client Rules do not apply to Admin SDK writes.

### Emulator tests

Updated `test/firestore.rules.test.mjs` to verify:
- active `super_admin` cannot create an index directly;
- active `admin`, `support`, and inactive `super_admin` cannot create an index;
- even active `super_admin` cannot directly update or delete an existing index.

Existing import audit and service-location Rules tests were retained.

## Git commits and verification

- Rules commit: `b508995a9d41dd8b2c91d5a11a3e2a09e58e2aae`
- Emulator-test commit: `edad8502e590f1cedb3c105130dae9792bcf63a9`
- Fetched both changed files back from the Firebase branch and verified the expected denial Rules and test assertions.
- Firestore Rules Emulator Tests run: [GitHub Actions](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39141863343)
- Trusted Location Geometry and Callable Tests run: [GitHub Actions](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39141863422)

At the time this report was written, both latest workflows were **in progress**. No passing result is claimed until GitHub reports completed success.

## Safety boundary

- Firebase Rules were changed on the feature branch only.
- No production deployment was performed.
- Draft PR #6 was not merged.
- No production location or name-index records were changed.

## Next action

Wait for both current workflow runs to complete. If either fails, inspect logs and fix the issue on the same feature branch. Only after both pass should the change be considered ready for review; do not merge or deploy without explicit approval.

# DOJO WALK Location Master — Step 46 Report

Date: 2026-10-17  
Related repository: `dojoplatform2026/dojo-firebase`

## Work completed: Emulator test harness added (user-confirmed CI PASS)

Added a test harness to the central Firebase repository:
- `package.json` with Node test script and Firebase Emulator test dependencies.
- `test/firestore.rules.test.mjs` covering unauthenticated access, active super-admin access, inactive admin and support-role denial, city activation without a verified boundary, matching verified-boundary activation, mismatched-boundary rejection, and verified-boundary immutability.
- `.github/workflows/test-firestore-rules.yml` to run tests against the Firestore Emulator on relevant pushes/PRs and manual dispatch.

Files:
- [Test workflow](https://github.com/dojoplatform2026/dojo-firebase/blob/main/.github/workflows/test-firestore-rules.yml)
- [Rules tests](https://github.com/dojoplatform2026/dojo-firebase/blob/main/test/firestore.rules.test.mjs)
- [Package setup](https://github.com/dojoplatform2026/dojo-firebase/blob/main/package.json)

## Important validation status

The user confirmed that the GitHub Actions workflow result is PASS. The exact run ID/link was not captured in this chat, so record it in a follow-up for audit traceability. This report records the user's confirmation and does not claim an independently retrieved run log. No Firebase production deployment was triggered by this work: the existing deployment workflow watches `firestore.rules`, `firebase.json`, `.firebaserc`, and its own deployment workflow; this change added separate test files/workflow.

## Security findings still open

1. Central Firestore Rules require active `super_admin`, while the Admin UI gate checks only `isActive`. Align client-side route access with the rules' role requirement.
2. Firestore Rules check boundary metadata and verified references but do not compute polygon parent-containment geometry. Do not treat Rules as enforcing polygon containment.
3. The checked-in deployment workflow indicates how rules would be deployed, but is not evidence of which rules revision is currently active in production.
4. These tests are initial coverage, not a full collection-by-collection authorization matrix. Additional tests for Area activation, boundary verification/rejection transitions, name indexes, import audit, and all client collection access patterns are needed.

No production rules/data were changed; no deployment, location import, or activation was performed. Keep PR #6 open.

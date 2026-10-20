# Step 217 — Firestore Rules Emulator Test and CI Review

Date: 2026-10-18

## Scope
Read-only review of the trusted-location feature branch's test suite and CI evidence. No test was launched from this chat, no files were changed in Firebase, and no merge/deployment was performed.

## Exact source revisions
- Firebase feature branch head under review: `80b9df5602d85fbbeb063071711743d7dfb37b6c`
- `test/firestore.rules.test.mjs` blob: `bb4a08093ca0d6ea3d87fff697ef224d6db33f41`
- `package.json` blob: `29ef05ba7aa3fd8ee9dd5b29b639f213fb87d966`
- `.github/workflows/test-firestore-rules.yml` blob: `2ede2ddb76ea4effb28c34e9a7328015062eb547`
- `firestore.rules` blob: `5d179e99def9c66e402596e54bd9d667e654131b`

## CI evidence
GitHub's commit-associated workflow-runs endpoint returned these completed successful runs for the reviewed feature-branch commit:
- **Test Firestore Security Rules** — run #144, conclusion `success`
- **Trusted Location Geometry and Callable Tests** — run #134, conclusion `success`

The Firestore test workflow uses Node.js 22, installs the package dependencies, and runs:
`npx firebase emulators:exec --only firestore --project demo-dojo-rules-tests "npm test"`

This is GitHub-reported CI evidence associated with the commit; this review did not independently rerun the suite in a local emulator.

## Coverage observed in the Rules test file
Positive/negative cases include:
- unauthenticated reads/writes denied;
- inactive super-admin, support, and non-admin writes denied;
- new hierarchy records require existing and correctly linked ancestors;
- City/Area activation blocked without a matching verified boundary;
- direct City/Area activation and status changes denied;
- parent inactivity and parent/identity/boundary-reference mismatch rejected;
- clients cannot verify/reject boundaries or edit/delete verified boundaries;
- name-index and import-record writes restricted to active super-admin;
- import actor spoofing and import record updates denied;
- activation-audit record forgery/update/delete denied;
- transaction attempting to verify a boundary and bind it to a City is rejected.

## Important gaps still visible
1. **Name-index schema/tampering:** current test checks role authorization, but does not appear to assert that malformed index fields, mismatched document IDs/targets, or arbitrary index edits/deletes are rejected. Current Rules permit active admins broad writes to this collection.
2. **Import enum/length validation:** tests cover active super-admin and matching actor, spoofing, and immutability, but do not test invalid `status`/`verificationStatus` values or oversized source/fileName strings. Current Rules check strings rather than a strict enum/length schema.
3. **Callable negative cases:** this Rules test file cannot itself establish callable authorization/transaction behavior. Keep the separate trusted-location geometry/callable workflow passing as an independent release gate and verify its exact run/commit before release.
4. **Production parity:** CI only proves the checked-in feature-branch code tested by that run. It does not prove production Firebase Rules currently match this branch.

## Conclusion
The available commit-associated CI evidence is green, and the suite already covers important role, hierarchy, boundary, and direct-status-write protections. **The index schema and import validation gaps remain open** and should be addressed with focused negative tests and Rules hardening before release approval. Do not deploy or merge based solely on this audit.

## Next step
Prepare a minimal proposed Rules/test patch for `service_location_name_indexes` and `service_location_imports`, including allowed field sets, target/index consistency, allowed enum values, and string limits. Review it in a feature branch, run emulator CI, and leave deployment for explicit approval.

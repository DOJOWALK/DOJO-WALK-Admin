# Step 218 — Proposed Location Index and Import Rules Hardening

Date: 2026-10-18

## Changes prepared
Firebase repository: `dojoplatform2026/DOJO-WALK-Firebase`
Draft PR: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/pull/6
Head branch: `fix/location-index-import-rules`
Base branch: `feature/trusted-location-activation`

Files changed:
- `firestore.rules` — schema allowlist for location-name indexes; collection path allowlist; bounded document ID/name; parent ID list size cap; update identity immutability; import field allowlist and non-empty bounded strings.
- `test/firestore.rules.test.mjs` — tests for unexpected index fields, unsupported collection paths, empty names, too many parent IDs, empty/oversized import metadata, actor spoofing, and import immutability.

## Current GitHub revision
- Rules blob SHA: `cb01b4b15f02139cce3229e6309a46f915ff513b`
- Test blob SHA: `b1c80a31be20b4c6cb3de946c6055d689fe6ad4b`
- PR head commit: `7949497341d9f9c6d3667a871da39daf56667c6f`

## CI status at audit time
GitHub reported the following for the PR head:
- Test Firestore Security Rules — run #152, **queued**
- Trusted Location Geometry and Callable Tests — run #141, **in progress**

These are not yet passing results. Check the exact PR head and both workflows again before treating the patch as validated. No local emulator execution was performed in this chat.

## Deliberate limits / review points
1. Import `status` and `verificationStatus` are bounded non-empty strings, not strict enums. The Admin model currently types them as plain strings and does not provide an authoritative enum set; inventing enum values could break legitimate records. Define and share enums across Admin and Rules before enforcing them.
2. Firestore Rules cannot recompute the Admin client's SHA-256 index document ID from the JSON-encoded tuple. The proposed Rules check the index payload shape and immutable identity fields, but do not prove that the document ID cryptographically matches the tuple. Stronger uniqueness integrity may require a trusted callable/server write path.
3. Name index delete remains available to active admins when the stored index shape is valid, because the Admin transaction legitimately deletes an old index on rename. Review operational risk before approval.
4. This is a draft PR against the trusted-location feature branch; it is not merged and no production deployment occurred.

## Next step
Check the completed emulator and callable workflow runs, correct any failures, then review Admin/index consistency and decide whether index writes should move to a trusted callable. Do not merge or deploy without explicit approval.

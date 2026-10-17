# Step 101 — Malformed Snapshot Metadata List Hardening

Date: 2026-10-17

## Change
The offline integrity audit previously converted non-array `collectionsIncluded` and `completeCollections` metadata into empty arrays before checking their validity. That could hide malformed metadata. The audit now preserves whether each input was actually an array and sets `malformedCollectionLists: true` if either list is not an array or contains invalid collection names. Such metadata cannot produce `DECLARED_COMPLETE`.

Added regression coverage for an object supplied as `collectionsIncluded` and a string supplied as `completeCollections`.

## Commits
- Core: `3b68cca15cf56699f5405ff92f3c67d660836109`
- Tests: `b8b0918abfac44b232478165702287b24bdb84eb`

## CI
- Step 100 Rules [39028867035](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39028867035) — PASS.
- Step 100 callable/geometry [39028867024](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39028867024) — PASS.
- Step 101 Rules [39029040141](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39029040141) — PASS.
- Step 101 callable/geometry [39029039892](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39029039892) — PASS.

## Safety / limitations
This is offline snapshot validation only. No production export, live Firestore scan, write, import, activation, or deployment was performed. Declared metadata is not proof of export authenticity/completeness. Fresh official LGD row-level reconciliation and authoritative polygon validity/containment remain release gates.

## Next
Step 101 complete: both CI workflows passed. Next: validate snapshot metadata recordCounts structure and reject unknown count keys.
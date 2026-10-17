# Step 103 — Duplicate Snapshot Collection Metadata

Date: 2026-10-17

## Changes
- Duplicate names in `collectionsIncluded` and `completeCollections` now mark the scope metadata malformed.
- Report field `duplicateCollectionEntries` identifies duplicate list and collection name, sorted deterministically.
- Duplicate declarations force `INCOMPLETE_OR_UNVERIFIED`, even if all required collections appear at least once.
- Added regression coverage for duplicates in both arrays and documented the contract.

## Commits
- Core: `27f04b84d0e3eb3815c6f497cb33b5724ed65d7e`
- Tests: `db8aeda6d4876d18488d907c8155e20c092db18a`
- Audit documentation: `a6ef30b39ace212b5e93f163da8391c405a75af4`

## CI — PASS
- Rules and callable/geometry on code commit `27f04b84d0e3eb3815c6f497cb33b5724ed65d7e`: [Rules 39029341173](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39029341173) — PASS; [callable/geometry 39029341055](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39029341055) — PASS.
- Rules and callable/geometry on test commit `db8aeda6d4876d18488d907c8155e20c092db18a`: [Rules 39029346477](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39029346477) — PASS; [callable/geometry 39029346474](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39029346474) — PASS.
- Fresh runs on documentation commit `a6ef30b39ace212b5e93f163da8391c405a75af4`: [Rules 39029364150](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39029364150) — PASS; [callable/geometry 39029364139](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39029364139) — PASS.

## Safety / limitations
Offline snapshot validation only. No production export, live Firestore scan, source write, import, activation, or deployment was performed. Metadata declarations cannot authenticate an export or prove authoritative completeness. Official current LGD reconciliation and authoritative polygon geometry/containment remain release gates.

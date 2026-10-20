# Step 247 — Canonical Ancestor-Field Regression Test

Date: 2026-10-19

## Change
Added a focused regression test for the Admin's trusted name-index payload contract:
- Country has no parent fields.
- State includes `countryId`.
- District includes `countryId` and `stateId`.

This complements existing City legacy/District-linked compatibility tests and Area/Locality legacy-payload tests.

## Validation
The commit triggers Admin Web Build Check (No Deploy) and Service Location Geometry Tests. CI status must be verified before calling this step passed.

## Release status
- Admin PR #7 remains Draft/open/unmerged.
- Branch comparison against `main` currently reports 519 commits ahead, 1 behind, and 221 changed files. This is a substantial scope/divergence risk that must be reconciled before merge; do not merge blindly.
- CSV import remains preview-only; real GIS boundary/source reconciliation and production release checks remain open.
- Partner and Customer remain untouched until Admin is complete and explicitly approved.

No production scan, Firestore mutation, import, activation, migration, deployment, or merge was performed.

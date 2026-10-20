# Step 245 — Align District-First Hierarchy Comments

Date: 2026-10-19

## Change
Updated the hierarchy comments in the Service Location model and service to reflect the implemented contract:
`Country → State → District → Service City → Service Area → optional Locality`.

The comments now explicitly preserve compatibility for legacy City documents that do not yet have `districtId`.

## Scope and safety
- Comment-only change; no runtime behavior or Firestore payload changed.
- CSV import remains preview-only; no records were imported.
- No production deployment, merge, activation, or Partner/Customer migration performed.
- Fresh Admin CI runs are required for the current branch head.

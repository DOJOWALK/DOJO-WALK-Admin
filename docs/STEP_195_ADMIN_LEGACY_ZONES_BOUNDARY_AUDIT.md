# Step 195 — Admin Legacy Zones Boundary Audit

Date: 2026-10-19
Branch: `step-119-boundary-geometry`

## Scope
Read-only audit to keep the agreed order: finish Admin Service Locations first; do not modify Partner or Customer until Admin schema and merge gates are resolved.

## Findings
- `lib/features/service_location/screens/service_location_screen.dart` explicitly documents that the new Service Locations workflow does not modify legacy Zones.
- The Admin Service Locations UI currently presents Countries, States, Districts, Cities, Areas/Sub-districts, Localities/Villages, and Import History. It is a separate service-location hierarchy, not a silent conversion of legacy zone documents.
- The reviewed Admin walker-details UI displays profile data and zone-related identifiers; that alone does not establish a safe zone migration or replacement mapping.
- Prior cross-repository audits document that Partner onboarding still reads active legacy `zones` and saves location labels/zone IDs. Therefore, replacing that path is a separate compatibility migration and must not be bundled into Admin completion.
- Customer saved addresses are free-text address records in the reviewed contract; do not rewrite or backfill them based only on matching area names.

## Required safety decision
Preserve legacy Zones and existing walker zone IDs. Do not migrate by name alone. Before any future Partner cutover, require a documented stable mapping strategy, explicit missing/ambiguous-match handling, and tests for old walker records and zone deactivation.

## Status
- This step is an Admin-side, read-only compatibility audit; no Partner or Customer files were changed.
- No Firestore scan/write, import, activation, merge, or deployment was performed.
- PR #7 remains Draft. The latest checked Admin Web Build Check (No Deploy) and Service Location Geometry Tests passed on the pre-report head `bbda9e2d`; the new report commit must receive its own CI verification before being called green.

## Next
Continue Admin release gates: review schema and trusted Firebase contract together, keep CSV import preview-only until a transactional importer and rollback tests exist, and integrate overlapping Admin UI PRs only after the source-of-truth Service Locations behavior is stable.

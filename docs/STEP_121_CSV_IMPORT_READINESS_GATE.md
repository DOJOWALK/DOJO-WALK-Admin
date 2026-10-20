# Step 121 — CSV Import Readiness Gate

Date: 2026-10-19  
Status: **Readiness audit only; no production import writes**

## Confirmed blockers

1. The existing hierarchy is Country → State → City/District → Area/Sub-district. Source data has distinct State, District, City and Area columns. Silently mapping District into City would lose meaning and create incorrect parent relationships.
2. The Admin service layer sends constrained payloads to trusted callables. Adding districtId or lgdCode only in the UI would not be sufficient; callable validation, Firestore Rules, tests and dependent clients must agree.
3. A valid administrative name/code does not establish a DOJO WALK service-city record or service-area polygon.
4. Import preview must remain read-only until mapping and schema are approved.

## Import implementation acceptance checklist

- [ ] Approve hierarchy: Country → State → District → Service City → Service Area.
- [ ] Specify migration/compatibility rules for existing service_cities documents without districtId.
- [ ] Define exact State/District/City/Area CSV column mapping and which columns are official LGD data versus DOJO WALK service configuration.
- [ ] Update Admin models, forms, filters, and trusted-callable payloads together.
- [ ] Update Firebase Rules/callables with strict allowlists and parent ownership validation.
- [ ] Add emulator tests for valid parent chain, wrong-state district, duplicate IDs/names, missing parents, unauthorized fields, retry/idempotency and failed/partial import.
- [ ] Stage imports with file hash, source/snapshot date, actor, row counts, validation errors and explicit commit state.
- [ ] Ensure invalid rows cannot partially create active service locations; imported cities/areas remain inactive until boundary verification.
- [ ] Test Customer and Partner compatibility; keep legacy Partner zones unchanged until its separate migration is tested.
- [ ] Reconcile the current official LGD data and review each service-area polygon before production use.

## Decision / safety

Do not implement database-writing import logic until the hierarchy and cross-repository callable/Rules contract are approved. Do not deploy, activate locations, or write production records as part of this audit.

## Previous step verification
Step 120 commit 89d2fcf9e2fdb8aa51e60617505c93463ab250ed:
- Service Location Geometry Tests — PASS, run 39159118933.
- Admin Web Build Check (No Deploy) — PASS, run 39159118936.

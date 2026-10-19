# Step 196 — Admin/Firebase Location Index Contract Audit

## Scope
Read-only cross-repository comparison of Admin's index-parent field contract with the trusted Firebase callable on 2026-10-19. No Partner or Customer app code was changed.

## Verified alignment
- Admin City contract sends `countryId` and `stateId`, adding `districtId` only when a non-blank District ID is present.
- Admin preserves legacy City compatibility when `districtId` is absent or blank.
- Admin Area contract sends `countryId`, `stateId`, and `cityId`; Locality sends those fields plus `areaId`.
- Firebase derives District ancestry for District-linked Area/Locality records from the trusted City document; clients do not supply a District parent tuple for Area/Locality.
- Firebase validates City District ownership against the selected Country and State and maintains legacy and District-aware index tuples for linked Area/Locality records.
- Admin blocks changing a City's District association in place; adding/removing the association requires a separate migration.

## Release status
This confirms source-level contract alignment for the inspected paths only. It does not prove deployed callable/rules compatibility or production data readiness.

Still open:
1. Final cross-repository review of the Firebase callable and Firestore Rules.
2. Emulator/integration evidence for all index conflict and legacy-record scenarios on the final candidate commits.
3. Current official LGD data reconciliation and real service-area GIS boundary review.
4. CSV import remains preview/validation only; transactional import and rollback are not enabled.
5. Hosting/production Environment safeguards and reviewer configuration need verification.
6. Final branch/base recheck and explicit release approval.

## CI evidence
Admin branch `step-119-boundary-geometry`, head `d0bc85aca3`:
- Admin Web Build Check (No Deploy): PASS, run 39190538883.
- Service Location Geometry Tests: PASS, run 39190538872.

The Firebase branch's latest callable and Firestore Rules checks also passed on commit `2e4643f937` (runs 39188125694 and 39188125666).

## Safety
No merge, deployment, production import, activation, or migration was performed. PR #7 remains Draft/open. Partner and Customer implementation remains deferred until Admin is completed and merged.

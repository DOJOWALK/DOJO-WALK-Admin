# Step 146 — Area/Firebase contract compatibility checkpoint

## Findings
- Admin `ServiceArea` currently stores `countryId`, `stateId`, and `cityId`; it does not persist `districtId`.
- Admin Area save/activation validates the City parent and checks that a verified Area polygon is contained by its City polygon.
- Firebase's legacy callable payload allowlist for Area accepts the legacy three-parent fields (Country, State, City) and rejects an Area `districtId`.
- Firebase has District-aware schema and index helper contracts with the intended tuple Country → State → District → City → Area, but their own source comments explicitly say they are not wired into production callables.
- The two contracts must not be mixed: adding `districtId` to Admin Area writes before coordinated callable/index migration would currently be rejected by the trusted backend or could make name uniqueness inconsistent.

## Work completed
- Added a Firebase regression test that confirms legacy Area payloads remain accepted and District-aware Area payloads remain rejected by the legacy validator until the coordinated migration is ready.
- Kept all production callable behavior unchanged.
- No production export/import, data migration, deployment, or PR merge was performed.

## Required before District-aware Area rollout
1. Design a legacy-compatible migration for existing Area and Locality records.
2. Update trusted callable payload validation, transactional parent-document checks, activation rules, and duplicate-name index writes together.
3. Add emulator integration tests for wrong District, wrong City ancestry, duplicate names under different parent chains, immutable parents, and active-child restrictions.
4. Update Admin models and service only after the callable contract and tests are ready.
5. Run all Firebase and Admin CI checks before considering import readiness.

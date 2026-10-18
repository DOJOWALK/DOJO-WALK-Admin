# Step 144 — City/Area ancestry audit

## Findings
- City records can optionally store `districtId`; legacy City records without it are intentionally supported.
- The City list already resolves District names and labels unlinked legacy Cities.
- Area records currently persist `countryId`, `stateId`, and `cityId`; the Area model does not yet persist `districtId`.
- Area save/activation validates its City parent and verifies that the Area polygon is contained by the City polygon.
- The Firebase repository's District-aware schema/name-index helpers explicitly state that they are not wired into production callables yet. Therefore, changing Admin Area ancestry/index writes before a compatible trusted-backend migration would risk breaking name uniqueness and legacy records.
- The Area list still needs a readable District label, but the underlying schema/callable compatibility should be addressed before any Area parent migration.

## Safe next actions
1. Add a display-only District label to the Area list using its parent City's optional `districtId`.
2. Add compatibility tests for legacy Cities and District-linked Cities.
3. Plan a coordinated Firebase callable/index migration for Area ancestry before changing Area persistence.
4. Keep imports preview-only until the migration and integration tests pass.

No production data, callable contract, Customer/Partner repo, deployment, or merge was changed in this audit.

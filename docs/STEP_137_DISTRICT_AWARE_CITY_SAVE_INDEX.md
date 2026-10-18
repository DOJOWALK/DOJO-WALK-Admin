# Step 137 — District-aware City save/index support

## Scope
This is a backend compatibility step only. It permits *new* City records to be created with an explicit `districtId`, validates that the selected District belongs to the supplied Country and State, and scopes the canonical City name index by `[countryId, stateId, districtId]`.

## Changes
- Firebase helper now accepts City index tuples with either 2 parents (legacy City) or 3 parents (District-aware City).
- City payload allow-list and validation accept `districtId` only when it is a valid parent ID.
- Save callable reads the District document when `districtId` is supplied and rejects Country/State ancestry mismatch.
- Existing City records cannot silently add or remove `districtId` through an ordinary save. That transition needs a separate, explicit migration.
- Unit coverage checks District-aware City payload validation, malformed IDs and the three-parent canonical index tuple.

## Compatibility and limitations
- Legacy City records and their two-parent indexes remain supported.
- This step does **not** migrate existing City records, change Area/Locality ancestry, implement Admin District UI, or enforce District activation as part of City activation. Those are separate steps.
- No production data was imported and no deployment or PR merge was performed.

## CI
A first CI attempt failed because the City index helper and allowed-payload schema had not both landed in the tested branch state. The source was corrected and the tests were rerun. Latest commit: `7d2e4910c40b8b212c6b9e45ef112567c645821d`.
- Security Rules run: [39166053879](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39166053879) — **PASS**.
- Trusted Location Geometry and Callable Tests run: [39166053885](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39166053885) — in progress at last check.

Both latest CI runs completed successfully for the source commit. City District activation enforcement and Area/Locality ancestry migration remain separate pending steps.

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
At report creation, Firebase CI is running for commit `8ae4dbd9f111dfb79a5f5fdfc1f9318585f01666`:
- Security Rules run: [39165756237](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39165756237)
- Trusted Location Geometry and Callable Tests run: [39165756183](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39165756183)

Update the status only after both runs finish.

# Step 138 — District Guard During City Activation

## Scope
Firebase branch: `fix/location-index-import-rules`

This step updates the trusted `activateServiceLocation` callable so a City that includes `districtId` can only be activated when its District exists, is active, and matches the City's `countryId` and `stateId`. The District is re-read inside the same Firestore transaction and receives an `activationGuardAt` write, so a concurrent District deactivation conflicts and is retried against current ancestry.

## Compatibility
- Legacy Cities without `districtId` keep their existing Country/State activation checks.
- City/Area geometry verification remains required; no boundary rules were bypassed.
- No data migration, production import, deployment, or PR merge was performed.

## Tests added
The emulator integration suite now checks:
- inactive District blocks City activation;
- District with mismatched Country/State ancestry blocks activation;
- active matching District allows activation and receives the transaction guard write;
- missing District blocks activation;
- City remains inactive on failed activation.

## CI
Firebase commit: `0775875a59a931024701ad648a0eb28cac8e7215`

- Trusted Location Geometry and Callable Tests: run [39166935906](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39166935906)
- Test Firestore Security Rules: run [39166935871](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39166935871)

CI was in progress when this report was written; final results must be verified before marking this step fully validated.

# Step 140 — District-Aware City Lifecycle Audit

## Audit scope
Reviewed the trusted Firebase workflows for District-aware City creation/save, activation, deactivation and legacy City compatibility.

## Regression tests added
- A District-aware City can be saved with Country/State/District ancestry and a scoped canonical name index.
- Ordinary City save cannot silently remove or change an existing `districtId`; such changes require a separate migration.
- The generic status callable cannot activate City directly; activation must go through the geometry-validated `activateServiceLocation` callable.
- District-aware City activation remains guarded by active, matching District ancestry and a transactional District guard write.
- Existing legacy City activation without `districtId` retains its Country/State path.

## Firebase changes
Branch: `fix/location-index-import-rules`
Latest test commit: `11ab0a83cb7572d39917c71156652a16816dda7c0`
Changed test files:
- `functions/test/district_status.integration.test.cjs`
- `functions/test/activate_service_location.integration.test.cjs`

## CI
- Trusted Location Geometry and Callable Tests: [run 39168022015](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39168022015)
- Test Firestore Security Rules: [run 39168022367](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39168022367)

CI was still running at report creation; verify the final conclusions before marking this audit validated.

## Safety boundary
No Customer/Partner repo changes, PR merge, production deployment, or production data import.

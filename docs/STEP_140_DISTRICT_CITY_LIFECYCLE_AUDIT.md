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
Latest test commit: `1c6342e644821a381d568e7cfdac8f978ed6e844`
Changed test files:
- `functions/test/district_status.integration.test.cjs`
- `functions/test/activate_service_location.integration.test.cjs`

## CI
- Trusted Location Geometry and Callable Tests: [run 39168174566](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39168174566) — **PASS**
- Test Firestore Security Rules: [run 39168174564](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39168174564) — **PASS**

The first CI attempt exposed a test-fixture issue (the callable correctly requires an existing location when a locationId is supplied). The fixture was corrected to create the City through the callable, and both workflows on the latest commit completed successfully.

## Safety boundary
No Customer/Partner repo changes, PR merge, production deployment, or production data import.

# DOJO WALK Location Master — Step 89
## Server-Enforced Service Status Changes
Date: 2026-10-17

### Implemented
- Added Firebase callable `setServiceLocationStatus` in `functions/src/index.ts` for Country, State, City, and Area status changes.
- Callable requires a signed-in, active `super_admin`; validates target and parent documents; refuses deactivation when an active direct child is found and checks for malformed active descendants under Country/State.
- City/Area activation remains restricted to `activateServiceLocation`, which validates verified polygon geometry and parent containment.
- Added status audit writes in `service_location_status_audit`.
- Tightened Firestore Rules so clients cannot directly flip Country/State `isActive` or City/Area `isServiceActive`; Country/State cannot be created active directly.
- Added Rules Emulator regression tests for direct deactivation attempts across all four hierarchy levels and direct active Country/State creation.
- Updated Admin `ServiceLocationService` to route status changes through the callable; City/Area activation continues through the geometry-validation callable.

### Validation status
- [x] Firebase TypeScript build and existing geometry/callable integration suite passed on commit `3557c8ed121959f9bdb9636cef2ffce74e089402` (run [39025247312](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39025247312)).
- [x] Firestore Rules Emulator suite passed on commit `3557c8ed121959f9bdb9636cef2ffce74e089402` (run [39025247269](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39025247269)).
- [x] Added dedicated callable tests in `functions/test/service_location_status.integration.test.cjs` for authorization, active-child deactivation guards, and State activation parent checks.
- [ ] CI for the dedicated callable tests is pending on commit `fdfb4f27b1cfbb07208baf4246e1050437e4eefe` (runs [39025322676](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39025322676) and [39025322677](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39025322677)).
- [ ] Firestore Rules Emulator tests: pending.
- [ ] Admin Flutter analyze/tests/Web build after callable wiring: pending.
- [ ] Race regression test with concurrent parent deactivation and child activation: not yet added.
- [ ] Full transaction/lock protocol review remains necessary before calling the race condition fully closed.

### Important limitation
The server callable and rules enforcement have been committed, but CI was still running when this report was written. This is **implementation in progress, not PASS**. No Firebase deployment, merge, production status change, or real location activation was performed.

Firebase branch: `feature/trusted-location-activation`
Admin branch: `restore/india-location-reference-data`

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
- [x] Dedicated callable tests initially exposed a test-fixture issue: State was already active, so the callable correctly treated activation as a no-op. The fixture was corrected in commit `7c3eaef3bce1b58a77fd7d30caac527be3b186b0`.
- [x] Firestore Rules Emulator suite passed on the dedicated-test commit `fdfb4f27b1cfbb07208baf4246e1050437e4eefe` (run [39025322676](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39025322676)).
- [ ] Firebase callable integration rerun after fixture correction is pending (run [39025447018](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39025447018)); the previous run [39025322677](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39025322677) failed only at that test assertion, while the other callable and geometry subtests passed.
- [x] Admin Flutter analyze initially failed due to the now-obsolete client-side `_hasActiveChild`/`_ensureNoActiveChildren` helpers; removed in commit `f0731f1cb1ebed91cba526febba13589d7435ccb`.
- [ ] Admin Flutter validation after cleanup is pending (run [39025473065](https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39025473065)).
- [ ] Firestore Rules Emulator tests: pending.
- [ ] Admin Flutter analyze/tests/Web build after callable wiring: pending.
- [ ] Race regression test with concurrent parent deactivation and child activation: not yet added.
- [ ] Full transaction/lock protocol review remains necessary before calling the race condition fully closed.

### Important limitation
The server callable and rules enforcement have been committed, but CI was still running when this report was written. This is **implementation in progress, not PASS**. No Firebase deployment, merge, production status change, or real location activation was performed.

Firebase branch: `feature/trusted-location-activation`
Admin branch: `restore/india-location-reference-data`

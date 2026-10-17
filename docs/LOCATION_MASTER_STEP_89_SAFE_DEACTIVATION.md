# DOJO WALK Location Master — Step 89
## Server-Enforced Service Status Changes
Date: 2026-10-17

### Implemented
- Added Firebase callable `setServiceLocationStatus` for Country, State, City, and Area status changes.
- Callable requires a signed-in, active `super_admin`; checks active descendants before deactivation and records audit events.
- City/Area activation remains restricted to `activateServiceLocation`, which validates verified polygon geometry, active ancestors, and parent containment.
- Firestore Rules block direct client status flips; Country/State direct creation must start inactive.
- Added Firebase Emulator regression tests for authorization, descendant guards, ancestor checks, and concurrent Country deactivation vs State activation.
- Updated Admin `ServiceLocationService` to route status transitions through the callable. Migrated obsolete client-side guard tests to verify backend delegation.

### Validation — PASS
- [x] Firebase callable/geometry CI passed: [run 39025527213](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39025527213).
- [x] Firebase Firestore Rules CI passed: [run 39025527220](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39025527220).
- [x] Dedicated callable integration test run passed: [run 39025447018](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39025447018).
- [x] Admin Flutter validation passed on commit `9c0d8448cf4202a6b0d1481325ecbd855faf43e8`: [run 39025598444](https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39025598444).
- [x] Admin workflow steps confirmed successful: Python LGD CSV tests, Flutter dependency install, Dart/Flutter analysis, unit tests, Firestore Emulator persistence smoke test, and Flutter Web release build.
- [x] Concurrency regression test passed in the Firebase callable/geometry suite; parent/child invariant was preserved under competing operations.

### Limitations / remaining release gates
- CI PASS validates the tested commits and emulator/build workflows; it is not a production deployment or a live production Firestore test.
- Current official LGD row-level reconciliation is still pending; saved 2024 snapshot must not be labelled current official data without fresh export reconciliation.
- Authoritative contiguous polygon sourcing/verification, PR review/merge, and deployment approval remain pending.
- No production deployment, merge, production import, or real service-location activation was performed.

Firebase branch: `feature/trusted-location-activation`
Admin branch: `restore/india-location-reference-data`

Next: Step 90 — audit the status callable's transaction semantics and authorization/rule boundaries, then review remaining release gates without deploying.

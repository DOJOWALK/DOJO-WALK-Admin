# DOJO WALK Location Master — Step 87
## Backend Activation Ancestor Validation
Date: 2026-10-17

### Implemented
The Firebase callable `activateServiceLocation` now requires Country and State IDs for both City and Area activation. It checks that the Country exists and is active, and that the State exists, is active, and belongs to that Country. Area activation also checks its Country/State match the parent City. The Firestore transaction re-reads the Country, State, location, and boundary; for Areas it also re-reads the parent City and parent boundary before activation and audit writes.

### Regression tests
The callable integration suite now uses complete active Country/State fixtures for successful City and Area activation. It includes negative cases for a missing State reference, an inactive State, and a State linked to a different Country.

### CI checkpoint — PASS
- Earlier integration fixture commit `e15601baa9fa44585fac842d93987c31f60d10ef`: geometry/callable CI passed.
- Latest regression test commit `780737b51c4dda419ade4314811f71adb79c8743`:
  - [Geometry and Callable Tests — run 39021142915](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39021142915): **completed / success**.
  - [Firestore Rules Tests — run 39021142926](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39021142926): **completed / success**.

Both latest workflows completed successfully on commit `780737b51c4dda419ade4314811f71adb79c8743`. Step 87 CI validation is complete for these Firebase-side suites. This does not prove deployment, production activation, or Admin-to-Firebase end-to-end behavior.

### Still pending
Official current LGD row-level reconciliation, authoritative contiguous polygon validation, review/merge, and deployment approval. No production activation or deployment is claimed.

Next: Step 88 — confirm CI results and continue the activation/deactivation race audit.

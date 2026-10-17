# DOJO WALK Location Master — Step 82: Boundary Workflow and Rules Audit

Date: 2026-10-17

## Findings
- The Admin boundary management screen loads boundaries for the target location and uses the selected boundary document ID for verification.
- Verification reloads the latest boundary document and checks that its status is still pending before calling `markVerified`.
- Draft saving writes `locationId` and `locationType`, returns the boundary ID, and creates/updates a pending draft.
- The screen's current flow does not rely on the return value directly; the next management view reloads the saved boundary list and uses its stored ID.
- After verification, the UI explicitly says service activation is a separate action.
- Firebase Firestore Rules allow an inactive City/Area record to receive its verified boundary reference, but active City/Area identity and boundary reference remain protected from client rebinds.

## Regression tests added
On Firebase branch `feature/trusted-location-activation`, added tests for:
1. Active super-admin can bind a verified boundary reference to an inactive City.
2. Active super-admin can bind a verified boundary reference to an inactive Area whose parent City is active.
3. A client cannot rebind the verified boundary reference of an already active City.

These tests are currently being checked by Firebase GitHub Actions. Results have not yet been marked PASS.

## Current status
- Admin CI for Step 80: PASS.
- Firebase callable/geometry and Rules CI from the prior Firebase commit: PASS.
- New Firebase Rules regression CI: pending.
- No production deployment, import, or activation performed.

Next: Step 83 — inspect the new Firebase CI result and document the final compatibility checkpoint.

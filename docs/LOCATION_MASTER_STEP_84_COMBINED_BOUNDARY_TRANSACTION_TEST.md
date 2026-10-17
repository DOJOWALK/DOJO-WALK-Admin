# DOJO WALK Location Master — Step 84: Combined Boundary Transaction Regression Test

Date: 2026-10-17

## Audit findings

The Admin `ServiceLocationBoundaryService.markVerified()` reads the pending boundary and its owning location in a Firestore transaction. For an Area or Locality it also reads the parent location and its referenced verified boundary, then validates containment. It writes the boundary verification fields and, for City/Area, binds the exact boundary ID to the owning location in the same transaction.

The Admin Flutter regression tests use `FakeFirebaseFirestore`. They exercise service-layer logic but do not enforce Firebase Security Rules. Existing Firebase Rules Emulator tests had tested owner binding and boundary verification as separate operations, so a combined transaction under Rules was a missing regression case.

## Change made

Added a Rules Emulator test to `test/firestore.rules.test.mjs` on Firebase branch `feature/trusted-location-activation`:

- Seeds an inactive City and its pending boundary.
- Runs a single client transaction that marks the boundary verified and writes the same boundary ID to the City.
- Requires both writes to succeed under Firestore Rules.
- Reads both documents back and asserts the boundary is verified, the City points to that exact boundary, and the City remains inactive.

Commit: `8f895ab6e48e6aee0a50eccb95db4254921b5f5d`.

## CI state at report time

The commit triggered:
- [Firestore Rules Emulator workflow 39020560454](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39020560454) — queued at report time.
- [Geometry/callable workflow 39020560479](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39020560479) — queued at report time.

Do not mark this new test PASS until the Rules workflow completes successfully. The geometry/callable workflow is a parallel regression check.

## Scope and remaining gates

This new test runs the equivalent Firestore client transaction under the Rules Emulator; it does not execute Flutter/Dart code inside the Node.js runner. The Admin service implementation remains separately covered by Flutter tests. A true Flutter-to-Rules-Emulator integration harness would require a dedicated test arrangement and should not be implied by this result.

Fresh official LGD row-level reconciliation and authoritative contiguous polygon verification remain pending. No production import, real service activation, merge, or deployment was performed.

## Next step

Step 85 — inspect both CI runs. If Rules CI fails, fix the rule/test mismatch before proceeding; if it passes, record the checkpoint and continue with the remaining City/Area activation integration audit.

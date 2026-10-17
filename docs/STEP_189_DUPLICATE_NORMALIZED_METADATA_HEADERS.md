# Step 189 — Duplicate Normalized Optional Header Test

Date: 2026-10-18
Branch: `step-119-boundary-geometry`

## Change
Added a CSV parser regression test proving optional metadata headers that normalize to the same name (for example, `State LGD Code` and `state_lgd-code`) are rejected as duplicate headers rather than silently overwriting one another in the source metadata map.

The test fixture newline was corrected to a real Dart newline escape before recording this step.

Test fix commit: `f34292a36b8745fc6784d881865ac0db0ecbd6aa`.

## Verification
Step 188's `geometry-unit-tests` and `build-web` both passed.
CI for the new Step 189 head must complete before this test is marked PASS.

## Safety
Test-only change. No schema changes, Firebase writes, production imports, activation/deactivation, deployment, or Partner/Customer migration. Admin PR #7 remains Draft.

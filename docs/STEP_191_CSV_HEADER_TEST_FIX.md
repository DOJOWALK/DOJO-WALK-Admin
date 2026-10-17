# Step 191 — Correct CSV Header Normalization Fixture

Date: 2026-10-18
Branch: `step-119-boundary-geometry`

## CI finding
The Step 190 CI correctly caught a bad test assumption: the parser removes spaces, underscores, and hyphens, but does not remove the word suffix `name`. Thus `district_name` and `City-Name` are not aliases for the required `district` and `city` headers.

## Fix
Updated the test fixture to use ` STATE `, `dis_trict`, `Ci-ty`, and `Area`, which specifically tests case, surrounding spaces, underscore, and hyphen behavior that the parser actually implements.

Commit: `a631b047fc57baa6b9851d4804fd8bb5531732b0`.

## Verification
The Step 190 Geometry Unit Tests and Web Build both failed because this new test expected unsupported `_name` / `-Name` suffix removal. The corrected commit has new CI runs; do not mark it PASS until they complete.

## Safety
Test-only correction. No schema changes, Firebase writes, imports, activation/deactivation, deployment, or migration. Admin PR #7 remains Draft.

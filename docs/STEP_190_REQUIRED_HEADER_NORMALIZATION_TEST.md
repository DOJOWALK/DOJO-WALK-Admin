# Step 190 — Required CSV Header Normalization Test

Date: 2026-10-18
Branch: `step-119-boundary-geometry`

## Change
Added a parser regression test proving required headers are recognized when case, surrounding spaces, underscores, or hyphens vary (for example, ` STATE `, `district_name`, and `City-Name`). The fixture uses a real Dart newline escape.

Test commit: `269a95ba0e143e2b50a9544e5dd57cf38290689c`.

## Verification
Step 189 Geometry Unit Tests passed. Its Web Build was still running at the last poll.
CI for this Step 190 head must complete before the new test is marked PASS.

## Safety
Test-only change. No schema changes, Firebase writes, production imports, activation/deactivation, deployment, or Partner/Customer migration. Admin PR #7 remains Draft.

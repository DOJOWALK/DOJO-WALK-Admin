# Step 191 — CSV Header Test Fixture Correction

Date: 2026-10-18
Branch: `step-119-boundary-geometry`

## CI finding
The Step 190 GitHub checks failed. The test correctly exposed that the test fixture expected suffixes such as `district_name` and `City-Name` to be aliases for required names, but the parser only removes spaces, underscores, and hyphens; it does not remove the word `name`. The implementation behaved as written; the new test expectation was incorrect.

## Correction
Changed the fixture to use ` STATE `, `dis trict`, `ci-ty`, and `Area`, which specifically tests the parser's documented normalization (case, surrounding whitespace, spaces, underscores, hyphens) without assuming unsupported aliases.

Commit: `9d2b4aac0d371ca21ad9b08e56f4e27013e1465e`.

## Verification status
The failed Step 190 run reported 48 tests passed / 1 failed in geometry tests, and 67 passed / 1 failed in web build's test phase. New CI for the corrected head must pass before marking this step complete.

## Safety
Test-only change. No schema changes, Firebase writes, production imports, activation/deactivation, deployment, or Partner/Customer migration. Admin PR #7 remains Draft.

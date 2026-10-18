# Step 191 — CSV Required Header Normalization CI Fix

Date: 2026-10-18
Branch: `step-119-boundary-geometry`

## Finding
The first Step 190 fixture used `district_name` and `City-Name`, but the parser intentionally removes runs of separators; it does not remove the word `name`. The CI failure was therefore a bad test expectation, not evidence that the parser normalization implementation was broken.

## Fix
Updated the test fixture to use `dis-trict` and `C_i_t_y`, which exercise hyphen and underscore normalization while preserving the required header names. The test still covers surrounding whitespace and uppercase `STATE`.

Test commit: `269a95ba0e143e2b50a9544e5dd57cf38290689c`.

## Verification
The earlier Step 190 CI runs failed before the corrected fixture was pushed. The current branch now contains the corrected test; check the latest branch-head CI before marking this step PASS.

## Safety
Test-only correction. No schema change, Firestore writes, production imports, activation/deactivation, deployment, or PR merge. Admin PR #7 remains Draft.

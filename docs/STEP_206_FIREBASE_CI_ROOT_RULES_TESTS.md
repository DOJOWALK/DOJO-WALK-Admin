# Step 206 — CI Runs Root Rules and Functions Tests

Date: 2026-10-18

## Change made

Repository: `dojoplatform2026/DOJO-WALK-Firebase`
Branch: `step-138-partner-submission-negative-tests`
Commit: `8d09fca9713799e4695cf7b446d575f1de2d9bb6`

Updated `.github/workflows/test-location-geometry.yml` to:
1. Trigger when root `test/**` or `package.json` changes.
2. Install root test dependencies as well as `functions` dependencies.
3. Run both suites inside the Firestore Emulator session: `npm test && cd functions && npm test`.
4. Raise job timeout to 20 minutes and label the job clearly.

The edited workflow was fetched back from the review branch and verified. Current blob SHA: `ce05a436f2c31125ca1867ec9f3eaf7496c48557`.

## Verification status

- Workflow file change: **verified on GitHub**.
- New CI run for commit `8d09fca9713799e4695cf7b446d575f1de2d9bb6`: **not yet confirmed** in the Actions runs listing during this check.
- Root Rules test suite: **not yet confirmed passing**. Do not treat the previous green run (#139) as proof of this updated workflow, because that run used the earlier commit and only ran `cd functions && npm test`.

## Safety

Review branch only. No PR merge, no production rules deployment, and no production data changes.

# Step 250 — Admin/Firebase Status Contract Gate

Date: 2026-10-19

## Scope and evidence
- Admin review candidate branch: `step-186-main-integration-review`.
- Candidate head before this report: `e51f3d0cdb9f1a66fb79ff12360667677696127d`.
- Admin PR #11 remains open, Draft, and unmerged.
- Firebase PR #6 remains open, Draft, and unmerged; head: `e2f72b72e97b9bf51d81dddfa366c6986afef811`.
- Admin CI on the candidate head: Admin Web Build Check (No Deploy) PASS; Service Location Geometry Tests PASS.
- Firebase CI on PR #6 head: Test Firestore Security Rules PASS; Trusted Location Geometry and Callable Tests PASS.
- These are CI results only; they do not prove that production Functions or Firestore Rules are deployed.

## Cross-repository finding
Firebase PR #6 documents that `status` and `verificationStatus` are currently bounded strings, not authoritative enums, because the Admin model does not yet define one canonical set of values. The PR also identifies the CSV import status allowlist as requiring review against the actual Admin import model.

The Admin model and trusted backend distinguish multiple concepts (for example service activation and boundary verification). Do not collapse these into one generic status field. Before merging, define an explicit contract for each field, including:
- field name and owning document/workflow;
- accepted values and case sensitivity;
- which trusted callable may change it;
- legacy compatibility/fallback behavior;
- positive and negative emulator/unit tests;
- import preview versus committed-import states.

## Decision
- Keep Firebase PR #6 Draft until the accepted-value contract and Admin import allowlist are reconciled and tested.
- Keep Admin PR #11 Draft until the companion backend/release gates and final file scope are reviewed together.
- Do not merge, deploy Functions/Rules/Hosting, import CSV data, activate locations, or migrate production records as part of this audit.

## Next gate
1. Identify every Admin write/read path for `isActive`, `isServiceActive`, `status`, `verificationStatus`, and CSV import statuses.
2. Match each field to Firebase Rules and trusted callable behavior.
3. Add/update tests for allowed and rejected values, then rerun CI on the exact final PR heads.
4. Verify production Environment required reviewers and deployed backend revision before any release.

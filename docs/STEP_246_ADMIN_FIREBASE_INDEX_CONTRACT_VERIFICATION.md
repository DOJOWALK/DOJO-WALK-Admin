# Step 246 — Admin/Firebase District Index Contract Verification

Date: 2026-10-19

## Admin branch and CI evidence
- Repository: `dojoplatform2026/DOJO-WALK-Admin`
- Branch: `step-119-boundary-geometry`
- Exact branch head checked: `82f1a5b62ed2e08bd1e791a16a555b8c09353f2d`
- Admin Web Build Check (No Deploy): PASS, run 39242552971.
- Service Location Geometry Tests: PASS, run 39242553037.

## Contract checked against Firebase review branch
- Admin's `serviceLocationIndexParentFields` sends `[countryId, stateId, districtId]` for District-linked Cities and preserves `[countryId, stateId]` for legacy Cities without a District.
- Admin Area and Locality payloads retain their legacy parent fields; the trusted Firebase backend derives District ancestry from the City record rather than trusting client-provided ancestry.
- Firebase's legacy index contract accepts the documented legacy tuple lengths, while its separate District-aware helper uses District ancestry for Area and Locality.
- Admin's payload normalizer removes a blank optional City `districtId` and rejects a non-string value. Existing unit tests cover these compatibility cases.

## Result
The reviewed source-level index-parent contract is aligned for the paths above. This is not proof that production index documents exist, are consistent, or have been migrated.

## Remaining Admin completion/release blockers
1. PR #7 remains Draft/open/unmerged; no merge or deployment is authorized by this step.
2. CSV import is still preview-only. Do not enable writes before schema and source mapping are approved and backend transaction behavior is tested.
3. Current official LGD State/District source bytes and NCR service-area polygon sources still require reconciliation/review; names alone are not boundary evidence.
4. Firebase companion PR and deployment/release gates must be reviewed together with this Admin branch.
5. Legacy Partner `zones` compatibility must be preserved. Partner and Customer work remains deferred until Admin is completed and merged as instructed.
6. Production Environment required-reviewer configuration and deployed backend revision remain unverified.

## Safety
Read-only source/CI review plus documentation only. No production scan, Firestore write, import, activation, migration, deployment, merge, or Partner/Customer code change was performed.

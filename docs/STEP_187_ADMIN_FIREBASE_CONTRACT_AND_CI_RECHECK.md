# Step 187 — Admin/Firebase Contract and CI Gate Recheck

Date: 2026-10-19  
Admin repository: `dojoplatform2026/DOJO-WALK-Admin`  
Branch: `step-119-boundary-geometry`  
Review PR: [#7](https://github.com/dojoplatform2026/DOJO-WALK-Admin/pull/7)

## Verified Admin CI
The current PR head is `7cb9e3e0e7d2f59fa5e6dec34a1debb70a422081`. Both workflows passed on this exact commit:
- [Admin Web Build Check (No Deploy), run 39233404350](https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39233404350) — SUCCESS.
- [Service Location Geometry Tests, run 39233404310](https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39233404310) — SUCCESS.

These checks validate the branch's automated analysis/tests/build only. They are not a production deployment or an approval to merge.

## Contract source review
- Admin's service location model/service supports `service_districts` and an optional `districtId` on City, preserving legacy City documents that have no District.
- Admin's name-index payload contract sends Country/State/District parents for District-linked Cities; Area and Locality continue sending their legacy parent fields so Firebase can derive District ancestry from the City document.
- Firebase's current review branch `fix/location-index-import-rules` contains the corresponding callable-side District validation and legacy/District-aware index-pair preflight. Its two latest workflows passed on head `b1ff8b6`: [Firestore Rules, run 39227569201](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39227569201) and [Trusted Location Geometry and Callable Tests, run 39227569129](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39227569129).
- This is source/CI compatibility evidence only. The Admin PR still cannot be treated as production-ready while the matching Firebase backend change is in an unmerged draft PR and deployment/configuration is unverified.

## Remaining merge blockers
1. Reconcile and verify current official LGD State/District/Sub-District source bytes; the checked-in Sub-District snapshot is dated 2024-10-07.
2. Approve the exact semantics and source for service City/Area records and authoritative polygon boundaries; LGD administrative names alone do not establish service boundaries.
3. CSV import remains preview-only. Do not add production writes until the schema, staged import plan, idempotency/conflict behavior, and rollback plan are reviewed.
4. Keep Admin and Firebase changes coordinated; Firebase PRs remain Draft/open/unmerged. No production deployment has been verified.
5. Verify Hosting manual-only workflow and production Environment required reviewers before any release.
6. Preserve legacy Partner `zones` and walker records; Partner and Customer remain out of scope until Admin/Firebase are finished.

## Result
**CI green; merge blocked by data provenance, import design, and coordinated Firebase release gates.** No merge, deployment, production import, activation, or Partner/Customer modification was performed.

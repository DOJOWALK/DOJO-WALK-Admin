# Step 145 — Admin PR Overlap and Merge-Order Audit

Date: 2026-10-19

## Current scope
The Service Locations implementation remains the primary Admin completion track. Partner and Customer changes are intentionally deferred until Admin is verified and merged.

## Open Admin pull requests reviewed
- PR #7 — `step-119-boundary-geometry`: service-location boundary/schema work. Latest observed CI runs on commit `47a490d`: **Admin Web Build Check (No Deploy) PASS** and **Service Location Geometry Tests PASS**.
- PR #9 — `feature/admin-3d-service-location-ui`: premium styling changes in `lib/features/service_location/screens/service_location_screen.dart`.
- PR #10 — `feature/admin-operations-3d-cards`: UI styling changes, also touching `lib/features/service_location/screens/service_location_screen.dart`, plus Bookings, Live Operations, Dashboard and Walker widgets.
- PR #6 — `restore/india-location-reference-data`: reference-data restoration; review its base and dependencies before merge.

## Integration risk
PR #9 and PR #10 both modify the same Service Locations screen that is also central to PR #7. Merging either UI PR first or merging all three without a fresh rebase/build can overwrite or conflict with boundary workflow, import validation, map preview, and activation safeguards.

## Safe sequence
1. Keep PR #7 as the source-of-truth implementation branch for Service Locations.
2. Finish reviewing PR #7's schema, boundary verification, import readiness, and CI. Do not deploy production from this audit.
3. Rebase/cherry-pick PR #9's visual-only changes onto the finalized PR #7 screen, manually preserve all existing behavior, then rerun both Admin CI workflows.
4. Rebase/cherry-pick PR #10 separately; check that its shared screen changes do not undo PR #7 or #9 behavior. Rerun Admin CI.
5. Review PR #6 reference data against the importer/schema contract and merge only after compatibility is confirmed.
6. Merge only after explicit user approval. Do not merge or deploy automatically.

## Verified vs not verified
Verified from GitHub Actions at audit time: PR #7 commit `47a490d` has successful geometry tests and Admin web build check.

Not verified by this report: visual browser QA, production Firestore data, a real LGD import, production deployment, or compatibility with live Customer/Partner apps. No production scan, migration, or deployment was performed.

## Next action
Continue the Admin-first contract and boundary review on PR #7. Once that is stable, integrate the two overlapping UI-only PRs in sequence and rerun CI before any merge decision.

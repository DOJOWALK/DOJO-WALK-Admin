# Step 214 — Admin Payload vs Trusted Firebase Callable Contract Audit

Date: 2026-10-18

## Scope
Compared Admin branch `step-119-boundary-geometry` Service Location services with Firebase branch `feature/trusted-location-activation` callable contracts and Rules. Source review only; no file in Firebase was changed, no PR was merged, and no deploy workflow was run.

## Files inspected
- Admin `lib/features/service_location/services/service_location_service.dart` blob `a0d4643fd16198f895c2cce56f0942b4ec1b9041`
- Admin `lib/features/service_location/services/service_location_boundary_service.dart` blob `b3291cf5df8663365bffbc479ab298680fdf2e1f`
- Firebase `functions/src/index.ts` on `feature/trusted-location-activation` blob `ff234380a82be6daa0430702bd5a222f8776c0c7`
- Firebase `firestore.rules` on `feature/trusted-location-activation` blob `5d179e99def9c66e402596e54bd9d667e654131b`
- Firebase PR #1: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/pull/1
- Companion Admin PR #7: https://github.com/dojoplatform2026/DOJO-WALK-Admin/pull/7

## Contract compatibility findings
1. **Boundary review contract matches.** Admin calls `reviewServiceLocationBoundary` in region `asia-south1` with `boundaryId`, `decision` (`verified` or `rejected`), and `notes`. Firebase validates ID format, decision enum, required 1–2000 character notes, active `super_admin`, pending state, owning location, valid polygon/source metadata, and City/Area conditions.
2. **Activation contract matches.** Admin calls `activateServiceLocation` with `locationType` and `locationId`. Firebase accepts only `city` or `area`, checks active super-admin, matching verified boundary, active Country and State, and for Area checks active parent City and containment inside its verified City boundary. It re-reads sensitive documents in a transaction.
3. **Status contract shape matches at the call site.** Admin sends `locationType`, `locationId`, and `isActive` to `setServiceLocationStatus`. Function implementation must remain part of the same rollout as the Rules; this review did not independently validate every line of that function's implementation.
4. **Expected direct-write split.** Admin saves Countries/States/Cities/Areas/Localities, name indexes, and boundary drafts via Firestore transactions. Boundary verification/rejection and location activation/status are routed through trusted callables. The feature Rules explicitly gate administrative writes; review transitions should remain callable-only.
5. **Important sequencing requirement.** Firebase PR #1 is draft/open and unmerged; Admin PR #7 is also draft/open. The stricter Rules cannot safely be cut over ahead of the trusted callables and compatible Admin client. Firebase deployment workflows in the feature branch are manual-only and require exact typed confirmation plus target project, but their jobs check out `main`; the new code must first be integrated into main through reviewed PRs before those workflows can deploy it.
6. **Schema blocker remains.** Admin PR #7 itself notes the CSV uses separate State, District, City and Area concepts while the current Firestore model combines City/District. This is a model decision across Admin, Rules/callables and dependent apps, not something to bypass in security rules.
7. **Tests are not rerun by this report.** PR #1 documents passing geometry/callable and Rules Emulator workflows for its then-current head. Treat that as recorded CI evidence, not as a new test run performed in this audit. Confirm current head statuses before release.

## Recommended next actions
1. Inspect `setServiceLocationStatus` end-to-end against the Admin caller and hierarchy/status invariants.
2. Compare direct-write payloads and Rules allowlists field-by-field for every location collection.
3. Resolve the District/City hierarchy decision before finalizing the production schema.
4. Re-run Firebase Rules Emulator and callable geometry tests on the latest PR head, then coordinate merge/deploy order with Admin PR #7.
5. Verify production Rules version and deployment environment reviewer settings separately; GitHub source does not prove production state.

## Safety
No production changes, deployment, merge, import, or location activation occurred.

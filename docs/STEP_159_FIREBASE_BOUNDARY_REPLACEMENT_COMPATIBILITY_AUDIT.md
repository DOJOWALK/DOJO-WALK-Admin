# Step 159 — Firebase Boundary Replacement Compatibility Audit

Date: 2026-10-18

## Repositories and branch audited

- Firebase: `dojoplatform2026/DOJO-WALK-Firebase`
- Branch: `step-138-partner-submission-negative-tests`
- Admin: `dojoplatform2026/DOJO-WALK-Admin`
- Branch: `step-119-boundary-geometry`

## Firebase callable findings

### `reviewServiceLocationBoundary`

The trusted callable:
- requires a signed-in user and an active `super_admin`;
- validates boundary ID and decision;
- re-reads actor, boundary, and owning location in a transaction;
- accepts only a pending City or Area boundary whose owner IDs/types match;
- validates polygon geometry and required source metadata before approval;
- checks Area polygon containment within the parent City boundary;
- refuses to verify a replacement while its location is active;
- atomically marks the boundary verified and updates the inactive location's `verifiedBoundaryId`;
- writes a review audit record.

Therefore, the backend already supports a replacement workflow for an inactive location: submit a new boundary as pending, review it, and then the trusted callable updates the pointer. The previous boundary record is not deleted by this flow.

### `activateServiceLocation`

Activation independently checks the selected verified boundary, source metadata, timestamps, Country/State status, parent City status and Area containment. It transactionally rechecks the relevant references before setting `isServiceActive: true` and creates an activation audit record.

### Firestore Rules

The audited Rules require valid pending boundary creates/updates and constrain client-side verified-boundary fields. The trusted callable uses Admin SDK writes for review transitions. No Rules change was made.

## Admin UI gap confirmed

In `lib/features/service_location/screens/service_location_screen.dart`, `_manageBoundary()` selects the first verified boundary when one exists. That record is passed to the editor, which is read-only for verified boundaries. The UI does not expose a distinct “create replacement boundary” action for the same location.

This is an Admin UI discoverability/workflow gap, not a reason to bypass the trusted backend.

## Safe implementation plan

1. Add an explicit “Create replacement boundary” action for City/Area locations with an existing verified boundary.
2. Create a separate pending boundary document; never edit or delete the current verified record.
3. Make the pending replacement visible in the review UI without hiding the currently selected verified boundary.
4. Require the location to be inactive before verifying a replacement; show the callable's failure clearly if it is active.
5. After trusted review updates `verifiedBoundaryId`, refresh the location and boundary list; activation remains a separate explicit action.
6. Add regression coverage for:
   - active location replacement verification rejected, with existing pointer unchanged;
   - inactive location replacement verified and pointer updated;
   - previous verified boundary record retained;
   - rejected replacement does not change the verified pointer;
   - replacement geometry/parent containment failures leave the pointer unchanged;
   - concurrent review/state changes cannot silently overwrite the pointer.
7. Run Firebase build/unit/integration/Rules checks and Admin analyze/test/Web release build before considering the workflow ready.

## Scope and safety

This was a read-only audit. No code, Firestore data, Rules, deployments, imports, service activations, schema migrations or PR merge were changed. District schema remains blocked on the product/schema approval gate. Admin PR #7 remains Draft/open.

# Step 193 — Service Location Create/Edit and Boundary Review Audit

Date: 2026-10-18
Admin branch: `step-119-boundary-geometry`
Admin head reviewed before this report: `5dfa06f9cb9ea2b5162626b0a17c156d3bf06d15`
Firebase review branch inspected: `step-138-partner-submission-negative-tests`

## Code paths reviewed

- Admin `service_location_service.dart`
- Admin `service_location_boundary_service.dart`
- Admin `add_location_dialog.dart`
- Firebase Functions `functions/src/index.ts`, callable `reviewServiceLocationBoundary`

## Safeguards observed

1. New City and Area records cannot be created already active; boundary verification is a separate step.
2. City and Area save paths validate that parent documents exist and that parent IDs match the stored hierarchy.
3. Activating a City/Area requires a verified boundary; Area activation also checks polygon containment within its parent City's verified polygon.
4. Boundary drafts reject invalid/self-intersecting polygons and cannot overwrite a verified boundary.
5. Review callable requires authentication and an active `super_admin`, accepts only valid decision values and bounded non-empty notes, and rechecks reviewer/boundary/location inside a transaction.
6. Verification is limited to a pending boundary; it checks source metadata and polygon geometry, validates Area containment against the parent City's verified boundary, atomically binds the verified boundary to its inactive owner, and writes a review audit record.
7. The review callable prevents replacing a verified boundary while its location is active. Rejection and verification metadata are set server-side.

## Remaining gates / limitations

- These code-path checks are not a substitute for running Firebase Emulator integration tests against the exact deployed rules/functions version.
- State polygons are not represented in the current hierarchy, so this audit does not claim City containment within State geometry.
- The District-versus-City schema decision is still unresolved. No schema changes were made.
- Before Admin PR #7 can be merged, resolve the five product/source questions in the project handoff, review the full PR diff, and obtain explicit approval.

## Scope and safety

Audit/report only. No production data writes/imports, service activation/deactivation, deployment, PR merge, or Partner/Customer migration.

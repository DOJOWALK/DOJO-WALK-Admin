# Step 158 — Boundary Verification Lifecycle Audit

Date: 2026-10-18

## CI confirmation

The Step 157 Admin Web Build Check completed successfully:
- Run: https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39072304074
- Commit: `d9b9128a9f5b40a561c2436ea9ca35e0108e3b58`
- Job `build-web`: success
- Confirmed steps: install dependencies, full Admin Flutter analyze, full Admin test suite, Flutter Web release build (no deployment).

## Files audited

- `lib/features/service_location/screens/service_location_screen.dart`
- `lib/features/service_location/services/service_location_boundary_service.dart`
- `lib/features/service_location/models/service_location_boundary.dart`
- `lib/features/service_location/services/service_location_geometry.dart`
- `lib/features/service_location/services/service_location_service.dart`

## Confirmed safeguards

1. New or edited boundary data is saved as `pending`, with verification identity/time/notes cleared.
2. A verified boundary is read-only in the editor.
3. Boundary persistence validates polygon geometry through the shared geometry validator.
4. Verify/reject actions call the trusted `reviewServiceLocationBoundary` backend callable; the Admin UI does not directly write verified status.
5. The UI re-reads a boundary before requesting review/rejection/verification, while the trusted backend remains authoritative for role, status, geometry, metadata and parent-containment checks.
6. The success message explicitly says boundary verification does not automatically activate service.
7. Service activation is handled separately by trusted callables.

## Lifecycle gap found — replacement after verification

`_manageBoundary()` selects the first verified boundary whenever one exists. The editor then becomes read-only, and the screen does not offer a separate “create replacement boundary” action. As a result, an already verified City/Area boundary has no clear Admin UI path to propose a replacement polygon while preserving the current verified boundary until the replacement passes review.

The query may also return multiple boundary records for one location, but the UI exposes only one selected record at a time. This audit did not establish a supported revision/version contract or prove that a verified boundary can be safely superseded without coordinated backend changes.

## Recommended next step

Before changing code, inspect the Firebase callable and Rules behavior for re-verification/replacement, then define a backward-compatible boundary revision flow:
- retain the current verified boundary while a replacement is pending;
- verify the replacement independently;
- switch the location's `verifiedBoundaryId` only through the trusted backend after successful review/activation policy checks;
- keep old boundary records for audit/history;
- prevent two concurrent replacement reviews from unexpectedly overwriting each other.

Do not implement a client-only replacement shortcut. The trusted Firebase function and Rules must agree on the lifecycle.

## Scope and safety

No application or Firebase behavior was changed in Step 158. No production writes, imports, activations, deployment, schema migration, or PR merge occurred. District schema remains blocked on the existing product/schema approval gate. PR #7 remains Draft/open.

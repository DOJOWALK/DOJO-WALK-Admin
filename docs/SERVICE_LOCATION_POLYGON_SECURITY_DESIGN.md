# Service Location Polygon Security Design

Date: 2026-10-17  
Status: Design proposal — not implemented or deployed

## Problem

Firestore Security Rules can validate boundary metadata and verify that an Area references a verified boundary belonging to that Area. They do not provide a reliable native point-in-polygon / polygon-containment operation. A client-side or Flutter service-layer containment check can be bypassed by direct Firestore writes.

## Recommended trust boundary

Use a trusted server-side activation operation (for example, a callable Cloud Function using the Admin SDK) as the only supported path for verifying and activating a City or Area. Keep direct client activation denied by Firestore Rules until this backend exists and is deployed.

The trusted operation must:
1. Require Firebase Authentication and verify the caller against `admin_users/{uid}`; initially require `isActive == true` and `role == "super_admin"` to match the current rules. Do not silently introduce proposed roles.
2. Load the target location and its referenced boundary from Firestore; never trust boundary coordinates, IDs, or verification claims supplied only in the request body.
3. Confirm the boundary's `locationId`, `locationType`, `verificationStatus == "verified"`, source metadata, verification actor/time, and valid coordinate structure.
4. Validate polygon geometry using a maintained server-side geometry library: at least 3 distinct vertices, closed/normalized ring handling, no invalid coordinates, no self-intersections, non-zero area, and supported antimeridian policy.
5. For Area activation, require the referenced parent City to exist, be active, and have its own verified matching boundary.
6. Check that the Area polygon is fully covered by the parent City polygon (not merely that one point or centroid lies inside). Define a documented tolerance policy for boundary-touching and coordinate precision.
7. Perform activation only after all checks pass. Use a transaction or an equivalent version/revision check so the location, parent, and boundary cannot silently change between validation and write. If geometry processing is too large for a transaction, compare immutable boundary IDs and revisions before committing.
8. Write an audit event recording actor UID, target ID/type, boundary ID/revision, validation result, timestamp, and rejection reason. Do not allow clients to forge audit entries.
9. Make repeated requests idempotent and return actionable validation errors without exposing secrets.

## Firestore Rules defense-in-depth

- Continue denying non-super-admin direct writes under the current role model.
- Deny client-side transitions from inactive to active until the trusted activation path is ready.
- Do not treat `boundaryVerified: true` or client-supplied `boundary` arrays as proof of containment.
- Preserve immutable verified-boundary records; corrections should create a new boundary revision/record and require re-verification.
- Review deactivation/reparenting rules so active child Areas cannot be stranded beneath an inactive or different parent City.

## Required emulator / backend tests

- Area outside parent City is rejected.
- Area partly crossing the parent boundary is rejected.
- Area fully covered by parent City is accepted.
- Boundary/location ID or type mismatch is rejected.
- Missing, pending, rejected, malformed, self-intersecting, or zero-area polygons are rejected.
- Inactive or unverified parent City is rejected.
- Parent boundary revision changes during validation cause safe retry/rejection.
- Non-admin, inactive admin, and non-super-admin callers are rejected.
- Client direct activation is rejected when backend-only activation is enforced.
- Audit event is written on success and failure according to the agreed audit policy.
- City activation has its own geometry/source validation requirements.

## Rollout sequence

1. Implement pure geometry validation with unit tests.
2. Implement callable backend and emulator/integration tests.
3. Change Firestore Rules to block direct client activation and add denial tests.
4. Review deployment configuration, secrets, indexes, logging, and rollback plan.
5. Deploy to a non-production Firebase project and run negative/positive tests.
6. Obtain explicit approval before production deployment or enabling any real service locations.

## Current status

- This document is a design only.
- No Cloud Function was added or deployed by this step.
- No production rules were deployed; no location data was imported or activated.
- Current Actions/CI result for the recent emulator-test commit remains unconfirmed; do not mark the suite PASS without inspecting a real run.

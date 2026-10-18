# DOJO WALK — Step 197: Booking and Walker Location Migration Contract

Date: 2026-10-18
Admin branch: `step-119-boundary-geometry`
Firebase review branch: `step-138-partner-submission-negative-tests`
Status: **Planning only. No schema, runtime code, production data, or deployment changes.**

## Evidence checked

- Admin `lib/screens/bookings/bookings_screen.dart` reads `bookings` and displays booking status and walker name/ID; this screen does not perform assignment.
- Admin `lib/features/walkers/services/walker_admin_service.dart` reads bookings by `walkerId`; it is a walker-management read path, not an assignment algorithm.
- Firebase `firestore.rules` booking create validation requires `walkerId == null`; Admin updates can change `walkerId` and status under the existing allowlist.
- Current booking allowlist does not include `serviceCityId`, `serviceAreaId`, or a canonical service-location reference.
- Partner onboarding still reads active legacy `zones` and stores `city`, `state`, `area`, `zoneName`, `zoneNames`, and `zones` IDs in walker profiles.
- Current trusted boundary Functions validate only `service_cities` and `service_areas`; a separate `service_districts` schema is not implemented.
- These observations do not prove that every assignment path has been located. Assignment-related functions and UI must be searched further before migration.

## Compatibility-first contract proposal (not approved)

### Booking fields

For new bookings only, consider optional fields:
- `serviceCityId`: document ID from `service_cities`
- `serviceAreaId`: document ID from `service_areas`
- `locationSchemaVersion`: integer or explicit version string, set only after the contract is approved

Rules for any future implementation:
1. Existing bookings without these fields remain valid and readable.
2. New IDs must resolve to existing, active service locations with matching ancestry.
3. The selected Area must belong to the selected City.
4. A client-supplied text address is not proof that a booking falls inside a service polygon.
5. No automatic assignment may rely only on free-text city/area names or an unverified radius.
6. Do not add a district ID to bookings unless product requirements show it is needed for operational assignment.

### Walker fields

For new or migrated walker profiles, consider optional `serviceCityIds` and `serviceAreaIds` arrays. Keep existing `city`, `state`, `area`, `zoneName`, `zoneNames`, and `zones` fields unchanged during the compatibility window.

Do not assume every legacy zone ID maps to exactly one service Area. Create explicit reviewed mappings first; unresolved or ambiguous zones must remain legacy-only.

### Assignment gate

Before changing assignment behavior, identify the actual assignment writer and document:
- actor/service that assigns `walkerId`
- allowed status transitions
- whether eligibility checks `isActive`, `isApproved`, availability, and service coverage
- how the pickup address is mapped to a verified City/Area polygon
- fallback behavior for legacy bookings and legacy-only walkers
- audit logging and reassignment behavior

If a booking has no trusted service-location mapping, retain the existing safe/manual path; do not silently assign based on a guessed location.

## Required sequence

1. Finish repository-wide search for every `walkerId` writer and booking assignment UI/function.
2. Approve the meaning of the CSV's City column and the City/Area parent relationship.
3. Approve canonical booking and walker fields.
4. Update Admin, Firebase Rules/Functions, and Partner in coordinated changes with legacy compatibility tests.
5. Add emulator tests for valid/invalid parent IDs, inactive locations, cross-city Area IDs, legacy records, and unauthorized assignment.
6. Run all required CI checks and review all affected PRs together.
7. Production migration/deployment requires separate explicit approval.

## Open decisions — no assumptions

- Does the CSV City mean an administrative city or a DOJO-defined service coverage grouping?
- Must every service Area belong to exactly one service City?
- Should address-to-polygon matching be required before assignment, or should unresolvable addresses be routed to manual review?
- Should legacy zones be mapped manually, in a reviewed migration file, or remain indefinitely available as a fallback?

## Step 197 exit result

The compatibility proposal is documented. This is not an implementation, does not modify Firestore data, and does not authorize a merge or deployment.

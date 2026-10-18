# Step 200 — Booking Assignment Security Contract

**Status:** Planning contract only  
**Repository branch:** `step-119-boundary-geometry`  
**Scope:** Define safe requirements before implementing booking assignment. This document does not change runtime code, Firestore rules, data, deployment, or merge state.

## 1. Current evidence and implementation gate

The bounded read-only investigation recorded in [Step 198](STEP_198_WALKER_ASSIGNMENT_PATH_AUDIT.md) and [Step 199](STEP_199_ASSIGNMENT_WRITER_DEEP_SEARCH.md) did not identify an authoritative booking-assignment writer in the inspected/indexed code. Customer booking creation sets `walkerId: null`; partner screens consume assignments and update lifecycle state. An external backend, manual Firestore process, or unindexed code may still exist.

**Gate 0:** Before implementing anything, the project owner must confirm whether a separate backend or manual workflow currently assigns bookings, and whether the desired process is manual, automatic, or both.

## 2. Authorization and trust boundary

- Assignment must be performed by trusted server-side code using a transaction or equivalent atomic conditional write. A customer or partner client must never assign or reassign a booking directly.
- Authenticate the caller and verify an active, explicitly authorized admin role (for example, approved `admin_users/{uid}` role data). Being signed in alone is insufficient. The exact role and active-field contract must match the deployed admin authorization model.
- The Admin UI should call the trusted assignment endpoint; it should not write assignment fields directly.
- Coordinate the endpoint and Firestore Rules changes together. Existing Admin write permissions for booking fields such as `walkerId` and `assignedAt` must be reviewed and narrowed as needed; do not assume current rules already enforce this contract.

## 3. Booking eligibility

The trusted operation should verify, inside its atomic operation, that:

1. The booking exists.
2. It has no assigned walker (`walkerId == null`).
3. Its status is an explicitly allowed pre-assignment status (expected initial candidate: `pending`; confirm the final allowlist against existing workflows).
4. It has not been cancelled, completed, or otherwise moved out of the assignable lifecycle.
5. A concurrent assignment cannot overwrite the winner.

Reject invalid state changes with a stable, non-sensitive error. A repeated request should return a documented idempotent result only when it is the same already-committed operation; it must never silently replace a different assigned walker.

## 4. Walker eligibility

Before assignment, verify the target `walkers/{walkerId}` document exists and is eligible to receive work:

- Approval is explicitly granted.
- Account/work status is active and not suspended, blocked, or disabled.
- Required onboarding/document checks are complete.
- The walker is eligible for the booking's service and schedule.

**Schema gate:** Audit the actual deployed approval, active, suspension, and onboarding field names before coding. Do not guess names or treat a missing field as approval.

## 5. Service-location compatibility

The proposed canonical booking fields `serviceCityId` and `serviceAreaId`, and walker coverage fields such as `serviceCityIds` and `serviceAreaIds`, are **not confirmed as current deployed schema**. They must be approved before implementation.

When canonical IDs are adopted, the assignment operation should verify that:
- the referenced City and Area documents exist and are active;
- the Area's parent City matches the booking City;
- the walker is explicitly eligible for the matching City/Area;
- missing or inconsistent IDs fail safely into a review path.

Do not use fuzzy free-text matching or radius-only checks as a substitute for canonical service-area membership. Do not automatically map legacy `zones` to new Areas. Existing bookings without canonical IDs need an explicitly approved compatibility/manual-review policy.

## 6. Atomic write and audit event

After all validations pass, perform a transaction/atomic conditional update that rechecks the booking's current state and prevents a second assignment from winning. The proposed assignment write includes:

- `walkerId`: selected walker ID;
- `assignedAt`: server-generated timestamp;
- `status`: `assigned`, only if that lifecycle transition is approved;
- assignment actor/source metadata, using an agreed schema.

Write an append-only audit event containing the actor, booking ID, walker ID, timestamp, previous and new status, action source, and reason where applicable. Avoid putting secrets or unnecessary personal data in logs. Final field names and allowed values must be agreed with Firestore Rules and all app consumers before implementation.

## 7. Rules and client responsibilities

- Customer booking creation must continue to create an unassigned booking.
- Customer and partner clients must not set or change `walkerId` or `assignedAt`.
- A partner may only act on a booking already assigned to that partner, under the existing lifecycle allowlist.
- Assignment and reassignment must go through trusted server-side authorization and validation.
- Reassignment, cancellation of an assignment, and recovery from a wrong assignment need separate explicit policies; they must not be implicit side effects.

These are target requirements, not a claim that the current deployed rules already satisfy them.

## 8. Required tests before release

- unauthenticated caller, ordinary user, partner caller, inactive admin, and unauthorized admin role;
- missing booking, missing walker, already-assigned booking, invalid booking status, cancelled booking;
- unapproved, inactive, suspended, or incomplete-onboarding walker;
- missing/inactive City or Area, mismatched Area parent, walker coverage mismatch, missing legacy location IDs;
- two admins attempting different walkers concurrently;
- retry of the same request and retry after a different walker won;
- legacy booking compatibility and manual-review path;
- audit event written only for successful assignment;
- Firestore Rules Emulator tests proving clients cannot assign/reassign;
- endpoint and Admin UI integration tests, plus regression tests for customer/partner booking lifecycle.

## 9. Decisions required before implementation

1. Does an external backend or manual assignment workflow already exist?
2. Should assignment be manual, automatic, or support both?
3. Which exact deployed fields represent admin authorization and walker approval/active/suspension?
4. Are canonical City/Area IDs approved for bookings and walker coverage?
5. How should bookings without canonical IDs be handled?
6. Can one walker cover multiple Areas, and what schedule/capacity conflicts must be checked?
7. Should assignment immediately set `status = assigned`, or is a separate confirmation status required?
8. What are the approved reassignment and assignment-cancellation rules?

## 10. Change boundary

No runtime code, Firestore Rules, schema, production data, imports, activation state, deployment, or merge was changed by this step. This contract is a review gate for a future implementation, not proof that assignment is implemented or production-ready.

**Related evidence:** [Step 198 audit](STEP_198_WALKER_ASSIGNMENT_PATH_AUDIT.md), [Step 199 writer search](STEP_199_ASSIGNMENT_WRITER_DEEP_SEARCH.md), [Step 197 location migration contract](STEP_197_BOOKING_LOCATION_MIGRATION_CONTRACT.md).

# DOJO WALK — Step 49 Cross-App ID & Booking Schema Audit

Date: 2026-10-17  
Status: **Partial audit completed — compatibility gaps found; no code changes**

## Scope and evidence inspected

- Admin: `lib/screens/bookings/bookings_screen.dart` (blob `a047bd9c2fc5ac768da566723b7349a1ea41c764`), `lib/features/walkers/services/walker_admin_service.dart` (blob `d87d248ff8cc7f1b265c0db0c8f5abd52b6a3eb5`).
- Customer: `lib/features/booking/screens/booking_confirmation_screen.dart` (blob `94d45b12c7873fc2d289e164df965c735c0c63cb`).
- Partner: `lib/screens/home/navigation_screen.dart` (blob `28571975921f8e5b075925742691697016b3b6f4`), `lib/features/live_walk/screens/live_walk_screen.dart` (blob `1ca731246d58cc3742606dd3de8e04755d744cf0`), `firestore.rules` (blob `7b02a8bfb4fe80ab04d72f59966e2e09c848ffd0`).
- Firebase central repo rules could not be fetched in this step; no claim is made about its current contents.

## Findings

### 1. Shared booking collection — confirmed

Customer booking creation, Admin booking list, and Partner walk screens all reference the top-level Firestore `bookings` collection. This is a shared collection rather than three separate booking stores.

### 2. Booking ID — partial consistency

Customer creates a Firestore document using an auto-generated document ID and also writes that value into `bookingId`. Partner screens receive a `bookingId` and use it as the document key when reading/updating the booking. This is compatible when callers always pass the Firestore document ID. Still verify all navigation/assignment entry points and legacy records; do not assume every record's embedded `bookingId` is present or matches its document ID.

### 3. Customer booking fields — confirmed sample

Customer creation writes fields including `bookingId`, `customerId` (Firebase Auth UID), `walkType`, `bookingPlan`, `serviceType`, `petName`, `dogId`, `petDetails`, `pickupAddressId`, `pickupAddress`, schedule fields, `status: pending`, `walkerId: null`, `cancelRequest: null`, and `createdAt`. Regular bookings also include `planStatus: pending_confirmation`, `frequency`, `walksPerWeek`, `walksPerDay`, and `dailyWalkTemplate`.

### 4. Booking status vocabulary mismatch — confirmed risk

- Customer creates a booking with `status: pending`.
- Partner's pickup navigation writes `accepted`, `picked_up`, and `walking`.
- Partner's live walk completion writes `completed`.
- Admin's booking filter presents labels such as `Pending`, `Walker Assigned`, `Walker Accepted`, `Walk In Progress`, `Completed`, and `Cancelled`.

The Admin filter compares displayed labels directly against stored status strings after lowercasing. Therefore labels such as `Walker Assigned`, `Walker Accepted`, and `Walk In Progress` may not match Partner's stored values `accepted`, `picked_up`, and `walking`. The precise intended mapping must be agreed before modifying code. A single canonical status enum and transition table is required across all apps.

### 5. Admin privileged walker actions — role guard exists in service

The inspected Admin WalkerAdminService transaction checks that the actor's `admin_users/{uid}` document exists, `isActive == true`, and `role == super_admin` before changing walker state and creating an audit record. This is stronger than the separate login gate's active-only check identified in Step 47; the overall UI/Rules policy still needs alignment.

### 6. Company ID — not established

The inspected booking-creation excerpt does not show a `companyId` field. This limited audit does not prove that no company identifier exists anywhere else in the repositories. Do not add/backfill a company field until a broader search covers models, all write paths, rules, indexes, and any server functions.

### 7. Walker ID / authenticated identity — partial consistency

Partner queries bookings by `walkerId == uid`, and walk completion records `walkerId: user.uid` in the walk record. Customer booking initially writes `walkerId: null`. This is consistent with UID-based identity in the observed paths, but the assignment path and all legacy records must be checked before declaring the contract final.

### 8. Security rules — incomplete end-to-end verification

Partner's repository has a `firestore.rules` file with an active-super-admin helper. This report did not complete a full review of every booking create/update rule or compare deployed rules with repository state. The central Firebase rules file could not be retrieved by the GitHub connector during this step. No rules were changed or deployed.

## Recommended canonical status proposal (not approved or implemented)

| Canonical status | Meaning | Current evidence |
|---|---|---|
| `pending` | Booking created, awaiting assignment | Customer writes this |
| `assigned` | Walker assigned, awaiting response | Admin filter label exists; writer path still to inspect |
| `accepted` | Walker accepted/arrived per current Partner code | Partner currently writes this on arrival, so semantics need clarification |
| `picked_up` | Dog picked up | Partner writes this |
| `walking` | Walk in progress | Partner writes this |
| `completed` | Walk completed | Partner writes this |
| `cancelled` | Booking cancelled | Admin filter label exists; all cancellation writers need audit |
| `reassignment_pending` | Assignment needs replacement | Proposed only; no implementation claim |

Do not adopt this table until “accepted” versus “arrived” semantics and assignment/cancellation paths are confirmed.

## Next actions

1. Inspect every booking write/update path in all apps and any Cloud Functions.
2. Inspect booking-related Firestore rules and indexes; verify deployed rules revision separately.
3. Build a field-by-field contract for booking ID, customer UID, walker UID, company ID, schedule, status, cancellation, and reassignment.
4. Approve canonical statuses and permitted transitions with the product owner.
5. Add tests for Admin filter mappings and Firestore Emulator authorization/state transitions.
6. Only then implement one coordinated change with migration/backward compatibility plan if needed.

## Safety

No application code, Firestore Rules, indexes, production records, or deployments were changed. This is a partial audit, not a full compatibility sign-off.
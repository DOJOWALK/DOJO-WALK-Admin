# DOJO WALK — Admin Role & Booking State Contract Audit
**Date:** 2026-11-02
**Status:** Documentation-only audit; proposal for review, not an approved production contract.

## 1. Purpose and guardrails
This document reconciles the current Admin/Firebase/Customer source with the draft governance and booking policies. It records source evidence and implementation blockers. It does not change application behavior, Firestore Rules, callable functions, or production data.

- Notion POL-021 (Access Control, Admin Roles & Privileged Account Security) is Draft.
- Notion POL-005 (Booking & Walker Assignment) is Draft and describes the Hybrid Offer Model: sequential automatic offers to one Walker at a time, with authorized manual intervention as an exception.
- Notion POL-026 (Walker Availability, Booking Assignment & Replacement) is Draft.
- No timeout, maximum-attempt count, candidate ranking weight, or operational SLA is inferred here.
- No merge, deployment, or device test is authorized by this audit.

## 2. Source evidence

### 2.1 Admin authentication gate
Source: `lib/screens/auth/auth_gate.dart` on Admin main, reviewed 2026-11-02.

The gate reads `admin_users/{uid}` and admits the user when `isActive == true`. It does not check the role or assigned geographic scope before rendering `AdminShell`.

### 2.2 Privileged service and Firestore authorization
Sources:
- `lib/features/walkers/services/walker_admin_service.dart`
- Firebase `firestore.rules`, helper `isAdmin()`

The Walker Admin service checks both `isActive == true` and `role == 'super_admin'`. Firebase Rules' `isAdmin()` helper also requires an active `super_admin`. Service-location callable audits likewise record a server-side active-super-admin check.

**Finding:** UI admission and protected-action authorization are inconsistent. The UI gate is not the security boundary; Firestore Rules/callables must remain authoritative. A non-super-admin may enter the shell and then be denied on protected operations.

### 2.3 Existing role values
The reviewed Firestore Rules allow `admin_users.role` values:
- `super_admin`
- `admin`
- `support`

The same Rules update allowlist permits role and active-state changes only through an `isAdmin()`-authorized update. The source inspected does not establish a complete production role/scope model for Founder, Central Operations, City Manager, Zone Supervisor, Finance, or location preparer/reviewer/verifier.

**Do not silently map** `admin` to Central Operations or City Manager, or `support` to a broader role. Such mappings need explicit approval and negative authorization tests.

### 2.4 Current Admin Booking screen
Source: `lib/screens/bookings/bookings_screen.dart` on Admin main.

The screen streams the `bookings` collection and displays records with filters labelled Pending, Walker Assigned, Walker Accepted, Walk In Progress, Completed, and Cancelled. This is a read/display screen in the inspected file; no offer, accept, decline, expiry, retry, or atomic assignment operation is present there.

### 2.5 Customer booking creation
Source: Customer `lib/features/booking/screens/booking_confirmation_screen.dart`.

The inspected creation path writes `bookings/{bookingId}` with `bookingId`, `customerId`, `status: 'pending'`, `walkerId: null`, and `cancelRequest: null`, then calls `bookingRef.set(bookingData)` from the client.

This documents the current source path only. It does not establish server-side validation, payment authorization, or assignment.

### 2.6 Firestore booking Rules
Source: Firebase `firestore.rules`, `match /bookings/{bookingId}`.

- Customer cancellation-request updates are allowed only when the existing parent status is one of `pending`, `confirmed`, or `assigned`, and only for `cancelRequest` / `updatedAt`.
- Customer review updates are separately allowed for `completed`.
- Active `super_admin` updates may change a list of parent booking fields including `status`, `walkerId`, and `assignedAt`.
- An approved Walker may update a limited set of fields on a booking assigned to their UID.

**Finding:** Rules permit certain field updates; they do not implement sequential offers, timeout processing, candidate eligibility, atomic winner selection, or assignment audit history. Do not treat the admin update allowlist as a trusted assignment service.

### 2.7 Callable Functions inventory
Source: Firebase `functions/src/index.ts` on main, reviewed 2026-11-02.

The inspected file exports five callable functions:
`reviewServiceLocationBoundary`, `activateServiceLocation`, `setServiceLocationStatus`, `saveServiceLocationWithNameIndex`, and `manageServiceLocationImportRun`.

No booking-assignment callable was found in this file. This is a source inventory finding, not a claim that no other backend service exists anywhere in the project.

## 3. Role matrix — policy-aligned target, pending approval and implementation

| Role | Intended responsibility | Scope | Must not be able to do |
|---|---|---|---|
| Founder / CEO | Company oversight; approve major policy, budget, senior appointments, expansion and major risk decisions | Company-wide visibility and approval authority as defined by policy | Routine dispatch; bypass audit or server-side safety checks |
| Super Admin | Privileged technical account/role administration, security configuration and technical audit | Technical administration only | Automatically inherit Central Operations, Finance approval, or dispatch authority |
| Central Head / Central Operations | Cross-city operations, escalation, support coordination, quality and consolidated reporting | Cross-city operational scope | Self-grant Super Admin; bypass backend eligibility or safety controls |
| City Manager | City operations and approved zones beneath that city | Explicitly assigned City and Zone IDs | Read/write other cities or zones without a separate grant |
| Zone Supervisor | Zone-level day-to-day coordination and escalation | Explicitly assigned Zone IDs | Cross-zone/city access or privileged role administration |
| Finance | Approved payment, refund and reconciliation workflows | Finance permissions and any approved scope | Self-approve a transaction where separation of duties is required |
| Support | Customer/Walker support with minimum necessary data | Explicit support permissions and case scope | Assignment, KYC approval, finance approval, or unrestricted private-data access |
| Location preparer / reviewer / verifier | Separate location setup and boundary review duties | Explicit location records and task assignment | Self-review/self-verify where separation of duties applies |

### Required authorization predicate
For each protected read/write, backend authorization should evaluate:
1. authenticated identity;
2. active admin account;
3. approved role;
4. assigned city/zone or explicit record scope;
5. permitted action;
6. current record state and required separation-of-duties checks.

Default must be deny. UI visibility is not authorization. Scope and role changes must be auditable and revocable. Emergency access, if approved, must be time-limited and audited.

**Important:** The matrix is a policy-aligned target derived from draft POL-021, not proof that these roles exist or are enforced in Firebase today.

## 4. Booking lifecycle — source vs proposed contract

### Current source facts
- Customer creation currently writes `pending` and null `walkerId`.
- Admin display labels include Walker Assigned, Walker Accepted and Walk In Progress.
- Rules refer to parent states `pending`, `confirmed`, `assigned`, and `completed`.
- Customer cancellation UI and Rules have a known state-coverage mismatch; do not expand Rules by guess.

### POL-005 proposed lifecycle (not yet canonical/implemented)
`draft` → `submitted` → `validated` → `searching_walker` → `offer_pending` → `assigned` → `in_progress` → `completed`

Additional outcomes proposed in POL-005 include `cancelled`, `needs_operations`, and `failed`.

This list must be reconciled against existing app enums, historical booking records, cancellation/refund policy, and the separate Walk Task / Walk history contract before adoption. Do not create duplicate status fields or perform an unreviewed bulk migration.

### Required transition ownership (target)
| Transition / event | Authorized owner | Required server-side safeguards |
|---|---|---|
| Customer submits request | Customer app requests; trusted backend validates | Authenticated customer ownership, valid pet/service/zone/time, quote and idempotency |
| Request becomes eligible for matching | Trusted backend | Active approved service zone, valid booking, no duplicate request |
| Offer sent to Walker | Trusted assignment service | One open offer per booking; eligible Walker; time-limited unique attempt |
| Walker accepts/declines | Trusted backend validates Walker action | Offer belongs to Walker, open and unexpired; recheck eligibility and conflicts atomically |
| Offer expires / next candidate | Trusted scheduled backend | Server clock; expired offer cannot be revived; no parallel active offers |
| Manual retry/reassignment | Authorized Operations role | Scope check, mandatory reason, audit event, no silent reassignment during active walk |
| Walk starts/completes | Trusted walk lifecycle API | Valid assignment, state transition, idempotency, durable GPS/safety/handover evidence |
| Cancellation/refund | Policy-authorized workflow | Canonical state, cutoff rules, refund approval thresholds, audit trail |

The assignment model remains the POL-005 Hybrid Offer Model: automatic sequential offer to one Walker at a time; manual action is an authorized exception. Timeout, max attempts, ranking weights, retry pause, and candidate-widening behavior remain approval blockers.

## 5. Contract and implementation blockers

1. Approve the exact role names and map legacy `admin` / `support` values without assuming equivalence.
2. Define canonical `admin_users` fields for role, active state, city scope, zone scope, and any delegated permissions.
3. Define how Founder approval is represented separately from Super Admin technical access.
4. Approve the canonical booking state list and transition table across Customer, Admin, Partner, Rules, and backend.
5. Reconcile Customer cancellation UI states with Rules and POL-010/POL-012 before changing permissions.
6. Implement assignment as trusted server workflow; do not rely on Admin client writes to `walkerId` or Walker client writes to parent booking status.
7. Define offer timeout, attempt cap, ranking and scheduling buffer through policy approval/configuration.
8. Add transaction/idempotency/concurrency tests, role-scope negative tests, privacy tests, and audit verification.
9. Confirm the deployed Rules/functions revision before any production rollout; repository source alone does not prove deployment state.

## 6. Acceptance tests required before rollout

### Authorization
- Inactive admin denied at shell and backend.
- Active `support` cannot access super-admin or finance actions.
- City Manager can access assigned city/zone only; another city's record is denied.
- Zone Supervisor cannot cross assigned zone.
- Super Admin technical access does not automatically grant finance or operational approvals.
- Founder approval and Super Admin technical administration remain separate.
- Revoked role/scope takes effect on the next protected backend operation.
- Unauthorized users cannot enumerate admin, customer, Walker, or booking private data.

### Booking and assignment
- Duplicate Customer submit with same idempotency key creates one logical booking.
- No offer is sent before booking validation and service-zone eligibility.
- At most one active offer exists per booking.
- Declined/expired offers cannot later be accepted.
- Two concurrent accept attempts produce exactly one assigned Walker.
- Eligibility and overlap are rechecked atomically at acceptance.
- Exhausted candidates move to an Operations exception state without false assignment.
- Manual override requires authorized scope, reason and audit record.
- Cancellation UI cannot offer an action that Rules/backend will reject.
- Active-walk replacement requires safe handover; no silent reassignment.
- Duplicate/retried backend events do not duplicate offers, assignments, walks or audit outcomes.

## 7. Decision requested from policy owners
This audit does not approve policy. The policy owners should review:
- role matrix and separation of duties;
- canonical booking states and permitted transitions;
- timeout / max attempts / ranking / retry pause;
- operational escalation ownership and customer-facing statuses.

## 8. Evidence links
- Admin AuthGate: https://github.com/DOJOWALK/DOJO-WALK-Admin/blob/main/lib/screens/auth/auth_gate.dart
- Admin Booking screen: https://github.com/DOJOWALK/DOJO-WALK-Admin/blob/main/lib/screens/bookings/bookings_screen.dart
- Admin Walker Admin service: https://github.com/DOJOWALK/DOJO-WALK-Admin/blob/main/lib/features/walkers/services/walker_admin_service.dart
- Firebase Rules: https://github.com/DOJOWALK/DOJO-WALK-Firebase/blob/main/firestore.rules
- Firebase callable inventory: https://github.com/DOJOWALK/DOJO-WALK-Firebase/blob/main/functions/src/index.ts
- Customer booking creation: https://github.com/DOJOWALK/DOJO-WALK-Customer/blob/main/lib/features/booking/screens/booking_confirmation_screen.dart
- Customer cancellation path: https://github.com/DOJOWALK/DOJO-WALK-Customer/blob/main/lib/features/booking/screens/my_bookings_screen.dart
- Admin UI PR (draft; no merge/deploy): https://github.com/DOJOWALK/DOJO-WALK-Admin/pull/51

---
**Audit result:** Source-level findings documented. No application code, Rules, backend functions, production data, or device state changed. This document itself is not a Founder-approved policy or implementation PASS.

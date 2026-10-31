# Admin Booking Operations UI & Contract Requirements — Draft
Date: 2026-11-01
Team: 02 — Admin App
Backlog item: ADM-P1-02
Status: **DRAFT / POLICY-DEPENDENT / NOT APPROVED / NOT IMPLEMENTED / NOT TESTED**
Notion sources reviewed (all fetched policies/contracts are Draft or working draft; not approved for production):
- POL-005 — Booking & Walker Assignment Policy (Founder approval required)
- POL-026 — Walker Availability, Booking Assignment & Replacement Policy
- POL-029 — Booking Cancellation, Rescheduling, No-Show & Refund Policy
- POL-006 — Customer Booking & Eligibility Policy
- DOJO WALK — Booking API Contract & Callable Implementation Gate (working draft, production gate blocked)
Related: POL-010, POL-012, POL-016, POL-024, POL-027, POL-031, POL-034, POL-035; Team 01 D01/D03 role/scope decisions.
Tracking PR: #51 (Draft, unmerged)

## 1. Purpose and evidence boundary
Define the Admin-side Booking Operations requirements and the cross-app contract questions that must be resolved before adding privileged booking actions.

Existing Team 02 source audit:
- `BookingsScreen` reads booking snapshots through `FirestoreBookingsDataSource.watchBookings()`.
- The inspected data-source interface exposes `watchBookings()` only; the screen is read-only.
- The screen supports search/status filtering and displays customer, Walker, dog, service, preferred time, created time, walk time, amount and cancellation-request metadata.
- Cancellation display reads `cancelRequest.status`, `requestedBy`, and `requestedAt`; no approve/reject/cancel write action was found in the inspected screen.
- The Admin dashboard's paid amount is gross paid-payment amount, not net revenue or settlement.
These findings are limited to inspected Admin paths and do not establish the absence of a separate backend workflow.

Notion POL-005/POL-026/POL-029 and the Booking API gate are not approvals or proof of implementation. This document is a Team 02 UI/contract proposal only.

## 2. Non-negotiable product and operational rules
1. A booking request, payment, assignment, walk task and actual walk are separate facts; do not collapse them into one status.
2. “Request received” does not mean availability confirmed, payment captured, booking confirmed, or Walker assigned.
3. Display “Walker assigned” only after the backend confirms one eligible Walker accepted and the assignment is committed.
4. One active offer at a time under the currently drafted hybrid offer model; do not show multiple simultaneous active offers unless policy is changed and approved.
5. Do not invent a Walker, manually assign an ineligible Walker, or silently override safety/eligibility restrictions.
6. Assignment acceptance must be atomic and protected from concurrent accepts, duplicate taps, stale events and retries.
7. Cancellation requested is not cancellation confirmed. Refund initiated is not refund completed.
8. Reassignment before a walk starts is different from a change during an active walk. An active walk must follow POL-016 safe-handover rules; never silently reassign or abandon a dog.
9. A booking must not be marked completed unless the approved walk completion and handover requirements are satisfied.
10. Do not invent cancellation fees, time cutoffs, no-show grace periods, offer timeouts, maximum assignment attempts, ranking weights or refund processing estimates.

## 3. Proposed Admin navigation and queue
Proposed destination: **Bookings / Booking Operations**. Keep the existing Booking list as the entry point; detail view may be a separate route or side panel after UX approval.

### List columns
- Booking reference
- Customer (minimum necessary display)
- Dog (minimum necessary display)
- Service / duration
- Requested local date and time (timezone explicit)
- City / Zone (authoritative and authorized scope only)
- Parent booking state
- Payment state (separate column)
- Assignment state / assigned Walker (only if confirmed)
- Next scheduled walk/task (where applicable)
- Cancellation/support/incident indicator
- Created time and last-updated time

### Filters and search
- Parent booking state
- Payment state
- Assignment state
- Service date/time window
- Unassigned age / time-to-service (only if timestamp semantics are approved)
- City/Zone within viewer's authorized scope
- Cancellation, reschedule, no-show, incident and refund exception
- Assigned Walker
- Search by booking ID and approved reference identifiers

Do not leak out-of-scope customer or booking existence through result counts, autocomplete, search errors, export, pagination or filters.

## 4. Booking detail — separate lifecycle panels
### A. Parent booking
Show the authoritative parent state, customer request, service/plan, schedule, dog reference, pickup/handover summary, quote/policy version and state history. Do not infer a parent state from one walk task.

### B. Payment
Show only trusted payment-provider/backend state and transaction references permitted to the viewer. Keep payment separate from booking and assignment. Never trust a client screenshot or client-provided `status`/amount as proof.

Suggested display vocabulary (must map to approved canonical backend values):
- Pending
- Processing
- Paid
- Failed
- Refund pending / processing
- Partially refunded
- Refunded
- Under review

Do not label refund as completed until trusted provider/backend evidence confirms success. Do not display raw payment credentials, secrets or authentication material.

### C. Walk tasks / occurrences
For one-time and recurring bookings, show each occurrence separately:
- Task/occurrence reference
- Scheduled local time and duration
- Task state
- Assignment state
- Assigned Walker only after confirmed assignment
- Start/arrival/pickup/in-progress/completion events where supported
- Cancellation/no-show/interruption exception
- Route/GPS evidence link only for authorized roles and exact walk session

A parent booking may have multiple future occurrences. One occurrence cancellation must not silently cancel the whole series or corrupt remaining entitlements.

### D. Assignment history
Show immutable attempt history:
- Assignment attempt ID
- Candidate/Walker reference only where viewer is permitted to see it
- Eligibility outcome/reason at time of attempt
- Offer ID, created/expiry time and status
- Notification attempt/delivery status where available
- Walker response: accepted / declined / expired / unknown
- Atomic acceptance result
- Current confirmed assignment
- Reassignment initiator, reason, timestamp, previous assignment and next action
- Manual intervention actor, reason and audit reference

A notification sent is not an offer accepted. An offer accepted by a client is not a confirmed assignment until backend atomic confirmation succeeds.

### E. Cancellation / reschedule / no-show
Show request and final outcome separately:
- Requested by and timestamp
- Reason category and explanation
- Applicable policy version
- Booking/task state when requested
- Fee/refund calculation inputs and server result (only after approved policy)
- Review/approval state
- Confirmed final state and customer communication status
- Support/dispute reference where relevant

### F. Operations exception panel
Show explicit states for:
- No eligible Walker
- Candidate attempts exhausted
- Offer expired / notification failed
- Assignment race lost
- Walker withdrew before start
- Replacement pending / confirmed / failed
- Customer change requested
- Pickup/service-area validation issue
- No-show under review
- Active-walk incident / safe handover
- Payment/refund reconciliation issue

Do not use a single generic “Pending” label for materially different blockers.

## 5. Proposed state model — mapping required before implementation
Do not create a new set of duplicate Firestore status fields from this draft. Team 01 and app owners must provide a canonical mapping and legacy adapter.

### Parent booking state candidates
The Booking API working draft lists candidate parent states such as:
- pending_confirmation
- confirmed
- active
- completed
- cancellation_requested
- cancelled
- partially_completed
- payment_review
- support_review

### Payment state candidates
The working draft lists:
- pending
- processing
- paid
- failed
- refund_pending
- partially_refunded
- refunded
- under_review

### Walk task state direction
The working draft describes a task progression such as:
- pending_confirmation
- ready_for_assignment
- assigned
- accepted
- arrived
- picked_up
- in_progress
- completed
with explicit exception outcomes for cancellation, no-show, failure and emergency hold.

### Assignment state candidates
The working draft lists:
- pending
- searching
- offered
- accepted
- reassigning
- manually_assigned
- failed

These are **draft candidates/directions**, not approved enums. The exact mapping to existing legacy `bookings.status`, `walkerId`, `cancelRequest`, nested schedules and Partner task states must be documented before Admin displays canonical labels or filters.

## 6. Assignment and reassignment controls
Potential Admin actions (all disabled until policy, role/scope and trusted API contracts are approved):
- View assignment attempts/history
- Retry an assignment attempt
- Request Central Operations intervention
- Initiate authorized manual reassignment
- Confirm/review an exception
- Contact customer/walker through approved channel
- Request replacement
- Record operational resolution

Every mutation must:
- Require active membership, canonical capability and authoritative City/Zone/case scope on the trusted backend.
- Verify current booking/task state, Walker eligibility, schedule conflict, service area, availability, leave and safety restrictions at action time.
- Require reason category and explanation where approved.
- Use idempotency/request IDs and concurrency protection.
- Preserve prior assignment and offer history.
- Return an authoritative result and stable error outcome.
- Write audit data with actor/service identity, timestamp, before/after state, reason, scope, correlation/request ID and result.
- Never bypass a safety restriction, expired/revoked approval or active-walk handover.

No Team 02 UI-only permission check is a security boundary. Team 01 D01/D03 and backend evidence are prerequisites.

## 7. Cancellation and rescheduling workflow
The UI must distinguish:
1. Cancellation requested
2. Eligibility/policy review pending
3. Cancellation approved/confirmed or rejected
4. Refund decision pending / approved / rejected
5. Refund initiated / processing / succeeded / failed / reconciled

For rescheduling:
- Show available times from an authoritative availability source.
- Revalidate service area, duration, dog/service eligibility, Walker availability, pricing/quote and recurrence constraints.
- Preserve old and new schedule, requester, reason, policy version and assignment history.
- Do not silently move a confirmed booking or assume the existing Walker can attend the new time.
- A change after assignment may require a new assignment; backend must confirm it.

For customer cancellation before assignment, approved backend logic should stop matching and invalidate open offers. If cancellation races with offer acceptance, server-side state rules must produce one authoritative final outcome. For an active walk, route to Support/Live Operations and POL-016 safety flow, not ordinary cancellation.

No fee, cutoff, grace period or refund amount is defined by this Admin draft.

## 8. No-show and service interruption review
Admin should show evidence and context, not automatically adjudicate misconduct:
- Confirmed assignment and offer acceptance history
- Approved check-in/arrival/start events
- Contact attempts and delivery outcomes
- GPS observation time/accuracy/freshness where lawfully authorized
- Customer or Walker explanation
- App/network/notification failure context
- Safety/incident references
- Reviewer, decision reason and appeal/support path

GPS alone must not prove a no-show or misconduct. A single ambiguous no-show or technical failure must not automatically trigger discipline. Thresholds, grace periods, evidence sufficiency and decision authority require policy approval.

## 9. Refund and financial separation
- Refund decision and payment-provider refund transaction are separate events.
- Show refund requested, reviewed, approved, initiated, processing, succeeded, failed and reconciled only when backed by authoritative records.
- Use provider transaction references and idempotency to prevent duplicate refunds.
- Failed/pending refunds should create a visible Support follow-up.
- Do not calculate net revenue, payout, tax or settlement from the booking amount alone.
- Finance permissions and refund thresholds require approved POL-024/POL-013 and role/scope contract.
- Do not permit Booking Operations staff to edit payment records directly or mark a refund successful manually without a trusted workflow.

## 10. Privacy and scope
- Customer/Walker contact details remain masked unless an approved purpose and permission allow reveal.
- Walker sees only minimum necessary details at the approved offer/assignment stage.
- Admin queue and detail must enforce server-side role, geographic scope and field-level access.
- Support sees assigned case fields; Finance sees finance-related fields; neither inherits unrestricted booking/dog/location access.
- Precise pickup address, live GPS, dog health/safety notes, identity evidence and payment references require separate permissions.
- Export/download is separate from ordinary read and requires explicit scope, purpose and audit.
- Do not place sensitive data in notifications, logs, analytics, URLs or error messages.

## 11. Loading, stale, failure and race states
The UI must distinguish:
- Loading / live update / stale snapshot / unavailable
- Request received / validation failed / validation unknown
- Searching / offer pending / accepted response / assignment confirmed
- Cancellation requested / confirmed / rejected / outcome unknown
- Reschedule requested / confirmed / rejected / outcome unknown
- Replacement pending / confirmed / failed
- Refund initiated / processing / succeeded / failed / reconciliation pending
- No-show under review / decision recorded / disputed

If a network error occurs after a mutation, retrieve authoritative state before offering a retry. Do not blindly retry non-idempotent operations. Do not optimistically remove a booking, mark cancellation complete, show new Walker assigned, or claim refund success before backend confirmation.

Hard-coded demo records must never appear as live booking data when the data source is unavailable.

## 12. Team 01 / cross-app contract decisions required
Before implementation, obtain exact branch + commit SHA and approved contracts for:
1. Canonical parent booking, payment, walk-task and assignment schemas; field names, enum values and legacy adapter.
2. Booking creation output and idempotency semantics; distinguish request received from confirmation.
3. Authoritative assignment attempt, offer, expiry, acceptance, notification and atomic assignment result.
4. Assignment candidate eligibility checks and version/timestamp captured at decision time.
5. Authorized manual retry/reassignment operations, role/capability, scope, mandatory reason and audit behavior.
6. Cancellation request, approval/confirmation, offer invalidation and race handling.
7. Reschedule request, availability/quote revalidation and recurring occurrence semantics.
8. No-show evidence model, approved thresholds, reviewer authority and appeal route.
9. Refund decision vs provider execution/reconciliation contract, idempotency and stable failure states.
10. Active-walk cancellation/interruption routing into POL-016 safe handover.
11. Notification delivery/acknowledgement status and customer communication semantics.
12. Query/index/pagination and server-side City/Zone scope for list, detail, search, counts and exports.
13. Emulator evidence for allowed/denied roles and scopes, concurrent acceptances, duplicate retries, stale events, cancelled offers, assignment eligibility changes, refund retries, and active-walk safety.

The Notion Booking API Implementation Gate currently says **BLOCKED — contract and product decisions pending**. It explicitly requires coordinated Customer/Admin/Partner/Firebase compatibility review before any production cutover. Team 02 must not independently implement a callable or change the Customer direct-write/legacy Firestore contract.

## 13. Planned acceptance checklist — NOT EXECUTED
- [ ] List/detail use approved canonical status mapping; no duplicate competing state fields.
- [ ] Parent booking, payment, task and assignment states remain separate.
- [ ] “Request received” never implies paid, confirmed or assigned.
- [ ] Assigned Walker appears only after trusted atomic confirmation.
- [ ] One active offer at a time is enforced by trusted service.
- [ ] Expired/declined/cancelled offer cannot later win.
- [ ] Duplicate taps/retries do not create duplicate bookings, offers, assignments or refunds.
- [ ] Concurrent acceptance cannot create two active Walker assignments.
- [ ] Assignment history preserves each attempt and its outcome.
- [ ] Manual retry/reassignment requires approved capability, scope, reason and audit.
- [ ] Ineligible/unavailable/suspended Walker cannot be assigned.
- [ ] Customer cancellation invalidates active offers according to approved backend rules.
- [ ] Cancellation requested is distinct from cancellation confirmed.
- [ ] Reschedule revalidates availability, quote, service area and assignment.
- [ ] One recurring occurrence change does not corrupt the whole series.
- [ ] Active-walk cancellation invokes incident/safe-handover workflow.
- [ ] No-show decision does not rely on GPS alone.
- [ ] Refund initiation is distinct from provider-confirmed completion.
- [ ] Failed/pending refund creates a Support follow-up.
- [ ] Search, filters, counts, details and export enforce server-side scope.
- [ ] Sensitive customer, dog, GPS and payment data is masked/restricted.
- [ ] Stale/unavailable data and ambiguous network outcomes are labelled truthfully.
- [ ] Mobile/accessibility and error states are tested.
- [ ] Exact-head CI passes after approved implementation.

All checks are **PLANNED — NOT EXECUTED**.

## 14. Explicit non-decisions and guardrails
- POL-005, POL-026 and POL-029 are Draft/unapproved; no production behavior is approved by this document.
- Booking API contract is a working draft and its implementation gate is blocked.
- No status enum, Firestore field, callable name, index, offer timeout, max attempts, ranking weight, cancellation fee, cutoff, no-show grace period or refund SLA is approved here.
- No role mapping or City/Zone permission is granted.
- No Customer/Partner schema migration, direct-write cutover or Firestore Rules change.
- No Firebase Functions/Rules/schema/production data change.
- No Admin runtime UI, mutation service or API integration.
- No tests, Emulator, CI, merge or deployment performed for this documentation-only task.
- PR #51 remains Draft and unmerged.

## 15. Status
This is a Team 02 Admin requirements draft based on inspected Admin source and Draft Notion policies/contracts. Product/Founder approval, Team 01 contract, Customer/Partner compatibility evidence, role/scope authorization, implementation and tests remain pending. Not launch-ready.

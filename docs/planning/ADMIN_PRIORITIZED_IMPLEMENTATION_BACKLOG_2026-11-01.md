# DOJO WALK Admin — Prioritized Implementation Backlog
Date: 2026-11-01
Team: 02 — Admin App
Branch: `ui/notion-brand-foundation-2026-10-28`
Tracking PR: #51 (Draft; unmerged)

## Operating guardrails
- Work in Team 02 Admin repository only.
- No Firebase project/schema/rules/functions/production-data changes from this backlog.
- No API/callable wiring until Team 01 confirms the relevant contract and POL-041/POL-021 are aligned.
- Keep PR #51 Draft; do not merge or deploy.
- Do not reintroduce coupons. Current product decision is no coupon system.
- A UI action is not “ready” merely because it renders: it needs policy approval, role/scope definition, stable state/error behavior, tests, and trusted backend enforcement where data is mutated.
- Every task must report evidence separately: source change, tests run, Emulator evidence (if authorized), CI result, and remaining blockers.

## Priority 0 — Governance and safety foundations (block privileged workflows)

### ADM-P0-01 — Resolve Admin role and geographic scope contract
**Status:** Blocked on Team 01 + policy approval.
**Scope:** Reconcile Founder/CEO, Super Admin, Central Admin, City Manager, Zone Supervisor, Support and Finance roles; define exact permission/action matrix and city/zone scope.
**Dependencies:** Team 01 D01 (role mapping), D03 (geographic scope), approved POL-021.
**Acceptance:**
- POL-021 has approved, versioned role × action × scope matrix.
- Source-of-truth role claims/Firestore membership mapping documented.
- Allowed and denied examples exist for each privileged role and cross-zone/cross-city attempts.
- UI hides/disables actions based on capability model, but server remains authoritative.
- Tests prove no privilege is gained by navigation/deep-linking or changing local UI state.
**Do not:** Treat `super_admin` as interchangeable with `central_admin` without written contract.

### ADM-P0-02 — Define incident and safe-handover Admin workflow
**Status:** Requirements/source gap; no live Admin incident workflow verified.
**Scope:** Incident queue, create/intake, severity, owner, escalation timeline, evidence references, safe handover, resolution/reopen, audit trail.
**Dependencies:** POL-016 and related safety policy approval; Team 01 trusted operation contract.
**Acceptance:**
- S0–S4 severity and escalation ownership are explicit.
- Dog custody/safe-handover is a required precondition where relevant; emergency stop cannot silently abandon a dog.
- Every action has actor, timestamp, reason, incident/walk/booking reference and immutable audit evidence.
- Duplicate submissions and network retries are idempotent.
- UI distinguishes submitted, acknowledged, assigned, escalated, handover pending/completed, resolved and failed states.
- Critical path has tests for unauthorized access, failed writes, duplicate requests and handover not completed.
**Do not:** Add direct client writes that stop an active walk or bypass trusted safety handling.

### ADM-P0-03 — Define live GPS freshness and route-session contract
**Status:** Source-level issues documented; backend contract required.
**Scope:** Distinguish online status from active walk and fresh location; isolate route points by walk/session; handle stale GPS, accuracy, missing updates and pagination.
**Dependencies:** Team 01 GPS/location data contract; POL-016 incident handling.
**Acceptance:**
- UI labels Online, Active Walk, GPS Fresh/Stale/Lost independently.
- Freshness threshold, accuracy threshold, timezone convention and last-seen display are approved.
- Route query is bound to exact walk/session and bounded time window; does not mix walks.
- Long routes retrieve the intended latest/complete segment with explicit pagination.
- Tests cover stale/future timestamps, poor accuracy, missing GPS, offline Walker, session changes and empty route.
**Do not:** Show an old `currentLocation` as current merely because `isOnline == true`.

## Priority 1 — Core operational workflows

### ADM-P1-01 — Complete Service Zone UI contract (UI/test work only until Team 01 responds)
**Status:** Blocked on Team 01 D01, D02, D03, D04, D05.
**Scope:** State/UT → District → City → Zone, boundary evidence, draft, review, Founder decision, activation/deactivation/suspension/reactivation views.
**Acceptance:**
- Four selectors only; no Locality selector.
- State/District/City are reference hierarchy only; Zone alone has service lifecycle.
- Boundary upload/create contract and revision/hash lifecycle are explicitly approved.
- Draft/review/approval/activation are distinct screens/states and never implied by preview navigation.
- Callable error codes map to stable actionable UI states; unknown errors fail closed.
- Role/scope and current revision/hash are checked before showing/allowing actions.
- Widget and service tests cover parent reset, missing boundary, invalid polygon, stale revision, duplicate submit, denied role, wrong scope and retry.
**Do not:** Invent a boundary upload callable or connect the existing callable-shaped service to unconfirmed APIs.

### ADM-P1-02 — Booking operations contract and UI
**Status:** Read-only Booking screen exists; assignment writer and cancellation/refund actions unverified.
**Scope:** Assignment visibility, assignment failure escalation, cancellation request review, reschedule, walk lifecycle and audit history.
**Dependencies:** Team 01 authoritative assignment contract; POL-026/POL-029 and cancellation policy approval.
**Acceptance:**
- One authoritative assignment writer and idempotency key are documented.
- Booking status transition matrix is approved; terminal/running walk safeguards are explicit.
- Admin UI presents assignment owner/status and escalation without allowing conflicting writes.
- Cancellation approval/decline and customer notifications have role/scope and reason requirements.
- Tests cover concurrent assignment, retry, duplicate event, active walk cancellation denial and audit atomicity.

### ADM-P1-03 — Walker Management authorization and lifecycle tests
**Status:** Real service/mutation path exists; authorization and coverage incomplete.
**Scope:** Preserve transactional Walker status + audit behavior while adding verified permission model and missing tests.
**Dependencies:** ADM-P0-01 and approved POL-021.
**Acceptance:**
- Every mutation checks active membership, exact capability and assigned geographic scope at trusted boundary.
- Read visibility is scoped; tests prove no cross-zone Walker/customer leakage.
- Emulator tests cover allowed/denied roles, stale membership, missing actor, invalid transition, reason validation and transaction rollback.
- Audit event and Walker mutation are atomic; retries do not duplicate effects.
**Do not:** Replace existing transaction semantics with optimistic client-only checks.

### ADM-P1-04 — Customer and Pet records: requirements and privacy-safe UI
**Status:** Hard-coded examples only; dedicated screen tests not identified in bounded search.
**Scope:** Define minimum Customer and Pet fields, consent/visibility, vaccination/care notes, data masking, retention and authorized actions before connecting records.
**Dependencies:** Approved customer/pet data contract and privacy policies.
**Acceptance:**
- Each field has purpose, source, visibility and retention classification.
- Sensitive data is masked by default and access is auditable.
- Search/filter handles loading, empty, error and permission-denied states.
- Dedicated widget tests cover no-data, redaction, consent missing, out-of-scope and mobile layout.
- No invented sample values are presented as live records.

### ADM-P1-05 — Support case management and notification delivery
**Status:** Both modules are prototypes; delivery/case backend not verified.
**Scope:** Case intake, triage, assignment, escalation, resolution/reopen; notification templates, channel state, delivery receipt, acknowledgement and retry.
**Dependencies:** Approved POL-009/POL-024/POL-032 and Team 01 case/notification contracts.
**Acceptance:**
- Cases and notifications have stable IDs, owner, timestamps, status history and audit records.
- Critical safety escalations do not rely only on push delivery.
- Notification retry is idempotent; delivery/ack status is explicit and separate.
- Marketing consent is separate from essential service communications.
- Tests cover duplicate, failure, denied access, reassignment and escalation.

### ADM-P1-06 — Finance, refunds and Walker payouts
**Status:** UI-only examples; provider and settlement connection not verified.
**Scope:** Payment ledger, refund decision workflow, payout ledger and reconciliation evidence.
**Dependencies:** Payment gateway contract, POL-030/POL-033, refund threshold approval and payout policy.
**Acceptance:**
- Amount/currency units, transaction IDs, provider references and idempotency are defined.
- ₹2,000 refund approval threshold and fraud escalation are approved in policy before UI enables actions.
- Initiation, approval and reconciliation are separated where required.
- Refund/payout states distinguish requested, approved, submitted, settled, failed and reversed.
- Reconciliation ties provider settlement to internal ledger; gross paid is never labelled net revenue.
- Tests cover duplicate provider callbacks, partial refund, reversal, mismatch and payout retry.

## Priority 2 — Management, reporting and quality-of-life

### ADM-P2-01 — Reports & Analytics
**Acceptance:** Approved KPI definitions, date-window semantics, scoped queries, empty/error states, export authorization and reproducible report tests. No fabricated metrics.

### ADM-P2-02 — Audit Logs
**Acceptance:** Trusted append-only event source, actor/action/resource/reason/time fields, tamper-evidence expectations, scope filtering and export audit. Prototype examples must never be confused with actual audit events.

### ADM-P2-03 — Settings & Governance
**Acceptance:** Each setting has owner, approved default, persistence location, audit behavior and rollback. Language persistence, MFA/session expiry, notification channels and retention settings remain disabled until defined and implemented.

### ADM-P2-04 — Dashboard alert quality
**Acceptance:** Pending booking count must not be described as unassigned unless walker assignment is checked; offline Walker count must distinguish off-shift from active-walk unreachable; payment failures include age/owner/context; GPS and incident alerts derive from approved source contracts.

### ADM-P2-05 — Navigation and regression coverage
**Acceptance:**
- Widget tests verify all 13 current sidebar destinations, Live Operations route, mobile drawer/collapsed rail and back navigation.
- No Coupons navigation or coupon management route.
- Role/scope tests cover route access, deep links and denied states.
- Full Admin test suite and Flutter Web build pass on the exact PR head before considering merge readiness.

## Suggested execution order
1. ADM-P0-01 and ADM-P0-02/03 requirements closure (policy + Team 01 contracts).
2. ADM-P1-01 Zone UI tests and state model after D01–D05 are answered.
3. ADM-P1-03 Walker authorization test expansion.
4. ADM-P1-02 Booking lifecycle UI and tests.
5. ADM-P1-05 Support/notification; then ADM-P1-04 Customer/Pet.
6. ADM-P1-06 Finance after gateway/refund/payout contracts.
7. Priority 2 reporting, audit, settings, dashboard and navigation regression.

## Current blockers / response tracking
- Team 01 D01–D05 decision request: `docs/architecture/TEAM_01_ZONE_API_CONTRACT_DECISION_REQUEST_2026-11-01.md`; response/evidence not confirmed in PR discussion as of this audit.
- POL-021 Admin roles policy remains Draft in the inspected context.
- No API wiring authorized until Team 01 contracts are confirmed.
- No new test or Emulator execution is claimed by this backlog document.

## Definition of done for every Admin task
1. Policy and source contract linked.
2. UI behavior and loading/empty/error/denied states implemented.
3. Role and geographic scope enforced at trusted boundary (when data is accessed or mutated).
4. Unit/widget/service tests added and run.
5. Emulator evidence recorded when backend behavior is involved and authorized.
6. Accessibility and mobile layout checked.
7. CI run tied to exact commit SHA; Static Analysis, complete test suite and Flutter Web build all successful.
8. PR description records limitations; remains Draft until all gates and approvals are met.

# Team 02 ↔ Team 01 Contract Readiness Gate — 2026-11-01

**Task:** ADM-CROSS-01 (readiness coordination; backlog prerequisite)
**Repository:** DOJOWALK/DOJO-WALK-Admin
**Branch:** ui/notion-brand-foundation-2026-10-28
**PR:** #51 — Open / Draft / Unmerged
**Status:** BLOCKED FOR LIVE INTEGRATION — no approved Team 01 decision/evidence was found in the sources inspected in this review.

## 1. Purpose

Record which Admin workflows can proceed independently, which require a signed/versioned Team 01 contract, and what evidence is still missing. This prevents Team 02 from guessing callable names, role aliases, schemas, error codes, geographic scope rules, or state transitions.

This is a documentation-only readiness review. It does not implement or authorize API/Firebase integration.

## 2. Sources checked

1. Notion **TEAM 01 — Backend & Firebase**, fetched 2026-11-01. It defines Team 01 ownership and the required API handoff: callable/endpoint name, region, request/response schema, auth role, authorization rules, error codes, idempotency behavior, Emulator test, compatibility notes and version/commit.
2. Notion **TEAM 02 — Admin App**, fetched 2026-11-01. It requires Admin to consume versioned Team 01 contracts and prohibits backend/schema/rules/functions changes from Team 02.
3. Notion **POL-021 — Access Control, Admin Roles & Privileged Account Security Policy**, fetched 2026-11-01. Still explicitly DRAFT / NOT APPROVED / NOT IMPLEMENTED / NOT TESTED.
4. Notion **POL-038 — India Admin Panel: Service Zone Setup...**, fetched 2026-11-01. Its confirmed override says State/UT, District and City are reference hierarchy only; only Zone has service activation; Create Zone has exactly State/UT → District → City → Zone and no Locality selector; Founder/CEO is final business approver; Central Admin executes activation after approval.
5. Notion **POL-041 — India Service Location API & Backend Workflow Specification**, fetched 2026-11-01. Still explicitly DRAFT / NOT APPROVED / NOT IMPLEMENTED / NOT TESTED. It contains older generic hierarchy/role proposals; apply POL-038's explicit Zone-only activation override and do not implement conflicting older City activation language.
6. Notion **POL-042 — Service Location Backend Implementation & Test Execution Plan**, fetched 2026-11-01. It records historical Firebase PR #39 emulator/Rules CI evidence on exact Firebase head `e8f5bf5128b0f27e63facd06f75556ed7e63e8fa`: 270 Functions/geometry tests and 56 Firestore Rules tests passed. It explicitly says this does not prove Admin UI E2E, deployed revision parity or production readiness. It also records prior Admin browser E2E failure on a different, historical branch/head. These results are not evidence for current Admin PR #51.
7. Notion **DOJO WALK — Booking API Contract & Callable Implementation Gate**, fetched 2026-11-01. Still Working Draft / not approved for production implementation; booking callable gate is BLOCKED pending contract and product decisions.
8. Admin PR #51 comments and source audits. No Team 01 reply/decision was found in the fetched PR #51 issue-comment history. This is bounded to PR #51 comments, not proof that no decision exists in another channel or repository.

## 3. Required handoff standard

A Team 01 contract is not ready for Admin consumption until all applicable fields are published together:

- Contract ID, version, status (Draft / Approved / Deprecated), owner and approval reference.
- Repository, branch, exact commit SHA and deployed/emulator revision.
- Callable/endpoint name and Firebase region.
- Request and success response schemas, including field allowlists and timestamp/currency/coordinate semantics.
- Stable error codes and safe UI handling.
- Authentication requirements, canonical role IDs and server-enforced geographic/resource scope.
- State-transition rules, concurrency/version preconditions and idempotency/retry behavior.
- Firestore/Storage read/write ownership and direct-client-write restrictions.
- Positive and negative Emulator tests, including out-of-scope and revoked/inactive identities.
- Backward compatibility, migration, rollback and deployment parity notes.
- Admin/Partner/Customer consumers and coordinated release dependencies.

A Notion proposal or source-level callable name alone is not an approved contract.

## 4. Cross-team readiness matrix

| Admin workflow | Current Team 02 evidence | Team 01 contract/evidence required | Gate |
|---|---|---|---|
| Authentication and Admin role entry | AuthGate/AuthService check Admin record exists and isActive in inspected source; role/scope/MFA/session enforcement not established there | Canonical role IDs, token/claims strategy, active/revoked account behavior, MFA/session/re-auth policy, server-side denial tests | BLOCKED for privileged production use |
| Role and geographic scope | Draft role × action × scope matrix exists; POL-021 Draft | D01 canonical role mapping; D03 authoritative City/Zone assignments; positive and negative Emulator evidence | BLOCKED |
| Service Zone lifecycle | Admin UI/service contract audit exists; current UI is incomplete | D01–D05 decisions; actual callable names; boundary create/upload contract; approval binding; role/scope enforcement; error/idempotency contract; exact emulator revision | BLOCKED |
| Booking request and assignment | Admin Bookings is read-only; assignment/cancellation mutations not connected | Approved legacy-compatible booking DTO; authoritative assignment writer/offer state; cancellation/reschedule/no-show contract; compatibility tests for Customer/Admin/Partner | BLOCKED |
| Walker Management | Read streams and privileged mutation path exist; source mutation currently checks exact `super_admin`; read scope gap noted | Canonical roles and scope; lifecycle transition contract; writer ownership; negative role/scope tests; audit atomicity | BLOCKED for broad role expansion |
| Live Operations and GPS | Current presence/route UI has freshness and walk/session isolation gaps | Canonical walk state, stable walkId/sessionId, location ingestion and freshness semantics, accuracy/sampling, pagination, authorized query scope | BLOCKED for safety-grade live claims |
| Incidents and safe handover | Draft workflow requirements exist; no live Admin incident workflow found in inspected screen | Trusted incident create/update/assignment/escalation contract, severity mapping, safe-handover state enforcement, idempotency, audit and notification guarantee | BLOCKED |
| Support cases and notifications | UI-only prototypes in inspected screens | Case record contract, owner/transfer/escalation lifecycle; event/outbox/delivery/receipt/retry contract; POL-032 channels and emergency fallback | BLOCKED |
| Payment, refunds and payouts | Gross paid count only; no connected Admin refund/payout workflow found in inspected paths | Verified provider states, payment/refund/reconciliation IDs, idempotency, ledger/settlement/payout contracts and Finance authorization | BLOCKED |
| Reports and analytics | Catalog not connected | Approved metric dictionary, trusted data sources, calculation owner, date basis, scope, lineage and refresh contract | BLOCKED |
| Audit Logs | UI prototype with hard-coded examples in inspected path | Trusted append-only event envelope, event producer ownership, pagination, retention, access audit and tamper protection | BLOCKED |
| Settings and governance | Preview-only settings in inspected path | Approved preference/config ownership, privileged control endpoints, MFA/session/recovery and retention contracts | BLOCKED |
| Dashboard alerts | Aggregate proxies exist; no unified alert lifecycle found in inspected path | Trusted detection/event source, severity/threshold/owner approval, dedupe/recovery/suppression, alert pipeline health | BLOCKED for actionable alerts |

## 5. D01–D05 Zone/API decision status

The Admin Team 02 decision request previously posted on PR #51 asks Team 01 to return:

- **D01 — Canonical roles:** exact stored role IDs, token/claim source, and explicit mapping between existing `super_admin`, `central_admin`, Founder and operational roles. Do not treat names as aliases.
- **D02 — Boundary write contract:** exact supported boundary draft/upload/create operation, storage location, metadata/hash/revision contract, and whether a supported server callable exists. Do not invent a missing upload endpoint.
- **D03 — Geographic scope:** authoritative assignment source and server enforcement for City Manager / Zone Supervisor; positive same-scope and negative sibling/out-of-scope/revoked/missing assignment tests.
- **D04 — Stable responses:** success/error envelope, stable machine codes, request/correlation ID, idempotency, retry safety and version/concurrency behavior.
- **D05 — Emergency and reactivation:** trusted emergency suspension, notification/review, Founder reactivation decision and execution path; prove emergency stop does not grant activation authority.

**Current status from inspected evidence:** no Team 01 response or approval was present in PR #51 issue comments. The latest Team 01 Notion page fetched is a team charter, not a completed D01–D05 decision. POL-021, POL-041 and POL-042 remain drafts/implementation gates in the retrieved pages. Therefore D01–D05 are **UNCONFIRMED**, not PASS.

## 6. Policy conflict and precedence note

POL-041 includes older generic proposals for hierarchy and role classes. POL-038 has an explicit confirmed override for the Admin Zone flow:
- Only Zone has service activation.
- State/UT, District and City are reference hierarchy only.
- Zone form has exactly four selectors and no Locality selector.
- Founder/CEO gives final business approval; Central Admin executes activation after approval.
- Super Admin is not automatically Founder.

Team 02 must implement the more specific POL-038 override in the UI requirements while the overall policies remain Draft/unapproved. This note does not approve POL-038 or make backend implementation production-ready.

## 7. What Team 02 may safely continue before contracts

Allowed without backend/API changes:
1. Static UI layout and accessibility work using clearly labeled fixture data.
2. Pure presentation widgets and view models with injected repositories/test doubles.
3. Navigation and route regression tests.
4. Client-side validation that does not claim to replace server validation.
5. Loading, empty, stale, partial, denied and recoverable error presentation using mocked states.
6. Documentation, acceptance matrices and design-system alignment.
7. Test harness improvements that do not alter production auth or Firebase behavior.

Not allowed until approval:
- Wiring proposed callable names to live UI.
- Guessing `central_admin` / `super_admin` / Founder equivalence.
- Adding client-side writes for trusted lifecycle, payment, audit, approval, incident or notification states.
- Inventing boundary upload/storage operations or GPS freshness thresholds.
- Changing Firebase Rules, schemas, indexes, Functions, production data or deployed configuration from Team 02.
- Claiming assignment, payment, refund, GPS freshness, alert acknowledgement or incident resolution without authoritative backend state.

## 8. Team 01 response format requested

For each D01–D05 and each workflow contract, Team 01 should respond with:
1. Decision: APPROVED / REJECTED / NEEDS PRODUCT DECISION / NOT IMPLEMENTED.
2. Exact repository + branch + commit SHA.
3. Contract document URL + version.
4. Exact callable/collection/storage names and region.
5. Request/response/error schema.
6. Role and scope checks enforced by trusted server.
7. Emulator test run URLs and positive/negative test counts.
8. Known limitations and migration/rollback notes.
9. Explicit statement whether it is safe for Team 02 to integrate in a non-production test branch.

No response is inferred from silence.

## 9. Next safe execution sequence

1. Request Team 01 to publish D01–D05 response with exact source/test evidence.
2. Request product/policy owner approval for POL-021 and any workflow policies still Draft.
3. Freeze a versioned cross-app contract bundle for Admin, Partner and Customer.
4. Select one isolated Admin workflow only after its dependency gate is green; implement behind test doubles first.
5. Pin the backend Emulator commit/revision and test actual Admin UI-to-callable behavior with allowed and denied roles/scopes.
6. Run Admin static analysis, complete tests and Flutter Web build on exact implementation SHA.
7. Do not merge/deploy until policy approval, cross-app compatibility, negative authorization tests and release evidence are reviewed.

## 10. Current disposition

- **Overall cross-team integration readiness: BLOCKED.**
- **D01–D05: UNCONFIRMED** from sources inspected on 2026-11-01.
- **POL-021:** Draft; role/scope/security approval not established.
- **POL-041 / POL-042:** Draft; proposal and historical CI evidence do not establish deployed/current production contract.
- **Booking API gate:** Working Draft / BLOCKED.
- **Admin PR #51:** Open / Draft / Unmerged.
- No runtime UI, API wiring, Firebase/schema/Rules/Functions, production data/configuration, tests or Emulator changes made by this document.
- No current Admin production readiness or cross-app integration PASS is claimed.

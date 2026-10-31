# Admin Walker Management — Authorization & Lifecycle Test Plan
Date: 2026-11-01
Team: 02 — Admin App
Backlog item: ADM-P1-03
Status: **DRAFT / POLICY-DEPENDENT / NOT APPROVED / NOT IMPLEMENTED / NOT TESTED**
Notion policies reviewed:
- POL-004 — Walker / Partner Management Policy (Draft; fetched 2026-10-30)
- POL-025 — Walker Recruitment, Verification, Onboarding & Training Policy (Draft; fetched 2026-10-25)
- POL-034 — Walker Performance, Ratings, Incentives & Disciplinary Management Policy (Draft; fetched 2026-10-30)
- POL-035 — Walker Attendance, Shift Management, Leave & Emergency Replacement Policy (Draft; fetched 2026-10-30)
Related: POL-013 Walker Earnings & Payout; POL-016 Incident & Emergency; POL-021 Admin Roles; Team 01 D01/D03.
Tracking PR: #51 (Draft, unmerged)

## 1. Purpose and evidence boundary
Define a test plan for Admin Walker Management authorization, geographic scope, lifecycle state transitions, and auditability before expanding the current implementation.

Prior Team 02 source audit findings:
- Walker read streams do not perform a local role/scope check in the inspected service path.
- Walker mutation `runAdminAction` reads `admin_users/{uid}` in a Firestore transaction and requires the record to exist, be active, and have exact `role == 'super_admin'`; it writes Walker status and audit log in the same transaction.
- Transition-policy unit tests cover valid/invalid transitions, required reason, reason length and stable audit action names.
- Those unit tests do not prove Firestore Rules enforcement or full trusted backend authorization.
- No evidence from those tests proves Manager/Zone scope isolation.
- Existing account configuration has used `super_admin`; Team 01 Zone callables inspected in a separate audit require exact `central_admin` for some operations and `founder` for Founder decisions. These identifiers must not be treated as aliases without an approved mapping.

This is a source-informed test plan, not a statement that current production authorization is safe or complete.

## 2. Policy-aligned lifecycle states
POL-004 describes these canonical business states:
- Applied
- Documents Pending
- Under Review
- Training Required
- Approved — Inactive
- Approved — Active
- Suspended — Temporary
- Rejected
- Offboarded

Only **Approved — Active** is eligible for booking matching, and only after scope, schedule/capacity and eligibility checks pass. A status change requires actor, timestamp, reason, scope, supporting evidence reference and next review date when temporary. Preserve historical booking, financial and audit records after suspension/offboarding.

**Important:** confirm whether these exact display labels map to existing stored enum values. Do not rename stored states or migrate data from this draft.

## 3. Admin read access requirements
- Every Walker list/detail/query must be restricted by authoritative role and assigned geographic scope at the trusted data layer.
- City Manager sees only walkers whose approved assignments fall within their assigned City/approved Zones.
- Zone Supervisor sees only walkers and operational fields in assigned Zone(s).
- Central Walker Operations may have cross-city scope only if Team 01 and POL-021 explicitly authorize it.
- Super Admin technical access is not automatically business permission to browse all worker data.
- Support sees minimum fields needed for an assigned case; Finance sees payout/reconciliation fields only where approved.
- Precise location, identity evidence, bank/payment details, private health data and disciplinary evidence require separate field/action permissions.
- Search, filter, count, pagination, exports, direct document reads and deep links must not leak out-of-scope Walker existence or data.
- UI hiding is defense-in-depth only; Firestore Rules and trusted service authorization must independently enforce the contract.

## 4. Status mutation and lifecycle requirements
Potential state transitions must follow approved transition policy and trusted server validation. At minimum, test:
- Applied → Documents Pending / Under Review
- Documents Pending → Under Review / Training Required
- Under Review → Training Required / Approved — Inactive / Rejected
- Training Required → Approved — Inactive / Under Review
- Approved — Inactive → Approved — Active (only after every required check)
- Approved — Active → Suspended — Temporary / Offboarded
- Suspended — Temporary → Approved — Inactive / Approved — Active / Offboarded only after authorized review and conditions
- Rejected → no reactivation unless an explicit appeal/reapplication policy defines it
- Offboarded → terminal for new offers unless a separately approved re-onboarding process exists

This list is a proposed test coverage map, not an approved transition table. Team 01/policy owners must confirm legal transitions, exact state values and who may perform each one.

For each mutation:
- Require current state/version to prevent stale overwrites.
- Require a reason category and explanation where policy demands it.
- Require evidence reference for verification/suspension decisions as applicable.
- Record actor, role/permission, scope, timestamp, request/idempotency key, before/after state, reason, evidence reference and result.
- Enforce no self-approval of privileged access or verification where policy requires separation of duties.
- Reject unauthorized, out-of-scope, stale-version, invalid-transition and duplicate requests safely.
- Preserve existing assignment/active-walk safety; suspension must not abandon a dog or silently cancel an active walk. Route active-walk cases through POL-016 safe-handover process.

## 5. Activation eligibility gate
Before Approved — Active can be granted, verify server-side:
1. Required application information complete.
2. Required identity/eligibility/document checks are recorded as reviewed by an authorized verifier.
3. Mandatory terms/agreement acceptance has version and timestamp.
4. Required training modules and assessment pass are recorded.
5. App access/contact readiness checks are complete where required.
6. City/Zone service scope is approved and enabled.
7. No unresolved suspension, conflict, expired required check or blocking safety restriction exists.
8. Approval is made by the authorized decision-maker distinct from the applicant.
9. Decision and evidence references are audited.

Do not store raw identity documents in Admin source, GitHub, Notion, logs or broad-access records. Store only restricted evidence references/status metadata in operational views.

## 6. Availability, shift, leave and assignment readiness
POL-035 requires separate concepts for availability, leave, attendance, offer, acceptance and assignment:
- Available time block is not a confirmed booking.
- Offer is not acceptance.
- Assignment is not proof of attendance.
- Online presence is not proof of availability or assignment readiness.
- Active account alone is not enough to qualify a backup walker.

Before matching/offer, trusted logic should check Approved — Active, approved service scope, availability, leave/restriction state, conflicting accepted work, travel/turnaround rules, required dog-handling/training criteria and booking prerequisites.

Attendance checks must not rely on GPS proximity alone as conclusive proof. GPS/network failure, customer delay, unsafe conditions and emergency events require an exception path. Do not invent grace periods, response deadlines, maximum offer attempts or working-hour caps; these need policy approval and configuration.

## 7. Performance, complaints and suspension safeguards
POL-034 is Draft and requires evidence-based fair review:
- A single low rating, unverified allegation or unstable small sample must not automatically trigger serious discipline.
- Separate immediate safety restrictions from final disciplinary findings.
- Record complaint source, related booking, evidence provenance, reviewer, Walker response, findings and appeal route.
- Avoid conflict of interest; serious allegations need an impartial reviewer.
- No automatic fines or arbitrary deductions. Financial consequences require approved contractual/legal basis and finance policy.
- Provide correction/appeal route for inaccurate records or decisions.
- A temporary suspension needs scope, reason, start time, review owner and review date/conditions.
- Any suspension during an active walk must invoke safe-handover/incident workflow; do not strand a dog.

## 8. Proposed role × action matrix (BLOCKED pending D01/D03 and POL-021)
Legend: P = proposed for review; C = explicit policy/backend confirmation required; — = not proposed by default. This is not an authorization contract.

| Action | Founder/CEO | Super Admin | Central Walker Ops | City Manager | Zone Supervisor | Support | Finance |
|---|---|---|---|---|---|---|---|
| Read cross-city Walker operational roster | Oversight summary | — / C technical need | P | — | — | — | — |
| Read assigned City Walker roster | — | — | P | P (assigned City) | — | C (assigned case) | — |
| Read assigned Zone Walker roster | — | — | P | P (assigned City) | P (assigned Zone) | C (assigned case) | — |
| Read identity/KYC evidence | — | C (security need only) | C (verification need) | — | — | — | — |
| Verify onboarding evidence | — | C (if authorized verifier) | P (authorized verifier only) | C | — | — | — |
| Approve activation | C (policy oversight) | — | P / C | C | — | — | — |
| Change weekly availability | — | — | C (assisted correction) | C (assigned City) | C (assigned Zone) | — | — |
| Suspend temporarily for safety | C (oversight) | — | P / C | C (assigned City) | C (assigned Zone, urgent report/escalation) | C (report only) | — |
| Reinstate after review | C (material escalation) | — | P / C | C | — | — | — |
| Offboard Walker | C (material policy exception) | — | P / C | C (recommend/escalate) | — | — | C (payout closeout only) |
| View payout/reconciliation fields | — | — | C | — | — | — | P |
| View incident/disciplinary evidence | C (material oversight) | C (security need) | P (assigned reviewer) | C (assigned case) | C (assigned zone case) | C (assigned case) | — |
| Export Walker data | — | C | C | C | C | C | C |

Every **P/C** entry needs exact permission and scope confirmation. Do not implement this matrix as a code gate.

## 9. Test layers and required evidence
### A. Unit tests
- Transition table: every allowed transition and every denied transition.
- Required reason/evidence/review date validation.
- Stale version and duplicate idempotency behavior.
- Audit event schema and stable action names.
- Activation readiness predicate with one missing prerequisite at a time.
- No self-approval / separation-of-duties predicate where approved.

### B. Widget tests
- Role/scope-aware action visibility and disabled states.
- No privileged action available via deep link when capability absent.
- Confirmation dialogs explain impact, reason and active-walk safety.
- Loading, empty, stale, permission-denied, server-error and unknown-outcome states.
- Temporary suspension displays review date/owner.
- Active walk shows safe-handover warning and blocks routine offboarding completion until safety state is resolved.
- Masked identity/evidence fields and mobile accessibility.

### C. Emulator / trusted authorization tests
- Inactive admin denied all privileged mutations.
- Active Super Admin cannot invoke Central-only action unless approved mapping grants it.
- Central Admin can act only within approved operational scope.
- City Manager allowed in assigned City and denied in sibling City.
- Zone Supervisor allowed in assigned Zone and denied in sibling Zone/City.
- Missing/revoked scope denied.
- Client-supplied cityId/zoneId cannot escalate access.
- Support and Finance cannot read unrelated sensitive fields.
- Applicant cannot approve/activate self.
- Unverified or training-incomplete Walker cannot be activated or matched.
- Walker outside enabled/verified service boundary cannot be offered booking.
- Suspension cannot bypass active-walk safe-handover state.
- Duplicate and stale concurrent mutations do not corrupt status/audit.
- Firestore Rules deny direct unauthorized reads/writes independently of UI.
- Audit event and status mutation are atomic where contract requires.

### D. End-to-end / operational tests
- Applicant → verification → training → approval → inactive → activation.
- Availability update → offer → accept/decline/timeout → assignment.
- Planned leave and unexpected absence with replacement.
- Safety incident during active walk → safe handover → temporary suspension → impartial review → decision.
- Offboarding with active booking, payout and retention records.
- Correction/appeal and reinstatement.
- Notification delivery/acknowledgement failure and recovery.

## 10. Acceptance checklist — PLANNED, NOT EXECUTED
- [ ] Canonical roles and capabilities approved in POL-021 / Team 01 D01.
- [ ] City/Zone assignment source and server enforcement approved in Team 01 D03.
- [ ] All Walker read queries and direct reads enforce scope.
- [ ] Sensitive fields have field-level permission and audit.
- [ ] Only Approved — Active and eligible Walkers can be matched.
- [ ] Activation cannot bypass documents, training, agreement or approval.
- [ ] Every lifecycle transition is server validated.
- [ ] Invalid/stale/duplicate transitions fail safely.
- [ ] Reason, actor, time, evidence and review date are audited.
- [ ] Self-approval and conflict-of-interest safeguards work.
- [ ] Availability, leave, attendance, offer and assignment remain distinct.
- [ ] Suspension/offboarding preserves historical records and active-walk safety.
- [ ] City/Zone isolation passes Emulator allow/deny tests.
- [ ] Firestore Rules and trusted service tests pass independently of widgets.
- [ ] Support/Finance field access is restricted.
- [ ] Mobile/accessibility and error/unknown states are covered.
- [ ] Exact-head CI passes after code implementation.

All checks are **PLANNED — NOT EXECUTED**.

## 11. Blocking decisions and Team 01 requests
1. D01: canonical backend roles, permission/capability mapping and exact role values accepted by each Walker operation.
2. D03: authoritative City/Zone assignment documents, inheritance rules, revocation behavior and server-side scope checks.
3. Walker status enum and allowed transition table; identify which transitions are callable vs transaction/service-owned.
4. Canonical audit schema, idempotency and optimistic concurrency/version contract.
5. Field-level access model for identity evidence, contact, location, incident, performance and finance data.
6. Whether any Manager/Supervisor actions are supported server-side or are report/escalation-only.
7. Exact Emulator tests proving allowed and denied actions for each role/scope.

Founder/policy owner must approve POL-004, POL-025, POL-034, POL-035 and POL-021 before production behavior is inferred from them.

## 12. Explicit non-decisions / guardrails
- No policy is approved by this document; all referenced policies were Draft when fetched.
- No role alias is inferred; `super_admin`, `central_admin` and `founder` remain distinct unless Team 01 documents otherwise.
- No Manager/Zone Supervisor mutation authority is granted.
- No new status enum or data migration is authorized.
- No numeric attendance grace period, offer timeout, maximum attempts or shift-hour limit is invented.
- No raw KYC/identity documents or sensitive records are copied into GitHub.
- No Firebase Rules/Functions/schema/production data changes.
- No runtime UI or API integration.
- No tests, Emulator, CI, merge or deployment performed for this documentation-only task.
- PR #51 remains Draft and unmerged.

## 13. Status
Requirements/test-plan draft only. Policy approval, Team 01 D01/D03 contract, backend authorization evidence, implementation and tests remain pending. Not launch-ready.

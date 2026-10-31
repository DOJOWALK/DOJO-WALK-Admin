# Admin Incident & Safe-Handover Workflow — Draft Specification
Date: 2026-11-01
Team: 02 — Admin App
Status: **DRAFT / NOT APPROVED / NOT IMPLEMENTED / NOT TESTED**
Policy source: Notion POL-016 — Incident & Emergency Management Policy (Draft, last fetched 2026-10-25)
Related: POL-007 Live Walk & Safe Handover; POL-008 Dog, Customer & Walker Safety; POL-009 Customer Support; POL-014 Privacy & Data Access; POL-015 Staff Conduct.
Tracking PR: #51 (Draft, unmerged)

## 1. Purpose and boundary
Define the Admin-side operational requirements for incident intake, triage, ownership, escalation, safe handover, evidence, and closure. This document translates POL-016 into a proposed Admin workflow; it does not approve POL-016, establish backend contracts, or prove that any alert/phone/incident integration exists.

**Non-negotiable:** urgent emergency/veterinary help and reasonable immediate safety action must not wait for internal Admin approval. The customer/owner is not expected to attend a walk or take over the dog. A walk must not be marked fully completed if it was stopped early.

## 2. Policy alignment
Use POL-016 severity exactly:
- **SEV-1 — Critical / immediate danger**
- **SEV-2 — High**
- **SEV-3 — Moderate**
- **SEV-4 — Low / near miss**

Severity is provisional and may be raised as facts change. If uncertain, use the safer higher severity and seek qualified help. Do not introduce a competing S0–S4 scale in Admin.

## 3. Proposed Admin navigation and queue
Proposed destination: **Incidents & Emergencies** under Live Operations / Operations (final placement requires product approval).

Queue columns:
- Incident ID
- Reported time (with time zone)
- Severity
- Category (dog missing/escape, dog injury/illness, human injury, unsafe person, unsafe handover, weather/route hazard, GPS/connectivity, privacy/security, payment/financial, near miss, other)
- Booking ID / Walk ID (when applicable)
- City / Zone (from trusted record, not user-entered scope)
- Current owner / escalation owner
- State and next action
- Last update / acknowledgement age

Filters: severity, state, category, city/zone (only within the viewer's authorized scope), owner, date range. Search by incident ID, booking ID, or walk ID. Do not expose broad customer search or unrestricted sensitive evidence through this queue.

## 4. Incident lifecycle — proposed states
1. **Reported** — incident record received; unique ID and reported timestamp assigned by trusted service.
2. **Triaged** — severity/category and immediate risk assessed; severity may be raised.
3. **Assigned** — accountable incident owner and backup route recorded.
4. **Acknowledgement pending** — notification/assignment sent but not yet acknowledged.
5. **Acknowledged** — named owner confirms responsibility.
6. **Escalated** — higher/independent owner or specialist notified; reason and timestamp recorded.
7. **Safety action in progress** — service/walk/access is paused or restricted by an approved trusted operation; no claim of successful action until backend confirms.
8. **Handover pending** — safe care/control transfer is required and not yet confirmed.
9. **Handover completed** — receiving capable/verified person accepts care/control; evidence and time recorded.
10. **Under review** — immediate risk controlled; investigation/corrective actions remain.
11. **Resolved** — immediate incident response complete and affected parties appropriately updated.
12. **Closed** — closure checklist and authorized review complete.
13. **Reopened** — new evidence or failed corrective action requires renewed review.

State transitions must be server-validated. UI must display the confirmed backend state, not optimistically imply success.

## 5. Walk safety and handover sub-workflow
When an incident affects an active walk:
1. Record the last verified walk state, timestamp, GPS freshness/accuracy if available, and reported location separately.
2. If continuing could worsen harm, stop/pause only through the approved trusted safety operation; never issue an unverified direct client write.
3. Initiate emergency/veterinary help as appropriate without waiting for Admin approval.
4. If the walker is injured or cannot continue, ensure the dog is safely controlled by a capable, uninjured person where safely possible. Do not leave the dog alone or require the injured walker to continue.
5. Seek a verified and suitable replacement walker. Explain the transfer to the customer and obtain agreement before transferring the remaining walk, except immediate emergency action necessary to protect life/safety.
6. If a replacement cannot arrive promptly, contact the pre-verified backup walker. If unavailable or outside the safe response window, use the approved alternative emergency assistance route.
7. **Never assume the customer/owner will attend or take over the dog.** If no safe handover/backup is available, stop the service and escalate to the designated incident lead for a documented safe-care arrangement.
8. Record actual completed duration, stop time, backup/replacement attempts, customer updates, receiving person's verified identity/role (minimum necessary), acceptance time, and final handover evidence.
9. Do not mark the full walk complete when it was not. Do not restart until required safety checks and authorized clearance are recorded.

The precise replacement assignment, emergency assistance route, safe response window, and handover evidence schema require Team 01 and policy-owner confirmation.

## 6. Severity response and escalation presentation
| Severity | Admin presentation | Required workflow behavior |
|---|---|---|
| SEV-1 | Critical / immediate danger; prominent active escalation | Emergency response first; immediate senior/on-call notification when safe; explicit acknowledgement and handoff tracking |
| SEV-2 | High; prompt senior and specialist escalation | Pause/restrict affected operation where needed; track specialist owner and acknowledgement |
| SEV-3 | Moderate; assigned owner and response target | Track approved response target, next update, and resolution actions |
| SEV-4 | Low / near miss; prevention review | Capture hazard/process weakness, owner, and preventive action |

Do not invent numeric response-time targets. Display them only after Founder/policy owner approval and actual rota configuration. If primary contact/acknowledgement fails, show backup escalation only when that route is configured and backend confirms dispatch.

## 7. Incident detail view
Sections:
- Summary: incident ID, severity, category, state, created/updated times.
- Affected work: booking/walk references; service status; verified location and freshness labels.
- People/dogs: minimum necessary identifiers and contact route; no unnecessary KYC.
- Timeline: immutable actor/action/time entries, source, and result.
- Ownership: current owner, backup, acknowledgement, escalation history.
- Safety/handover: pause/stop state, replacement/backup attempts, handover pending/completed.
- Communications: customer/walker updates, delivery/acknowledgement status if supported.
- Evidence: restricted links/metadata, provenance, timestamps, access history.
- Actions: role/scope-gated actions only after approved capability contract.
- Review/closure: findings, corrective actions, due dates, closure checklist, reopen reason.

## 8. Action controls — no optimistic or client-authoritative behavior
Potential actions (all disabled until policy and trusted backend contract are approved):
- Create incident / add factual update
- Set or raise severity
- Assign / reassign owner
- Acknowledge / escalate
- Pause or stop affected work using trusted safety operation
- Request replacement / backup assistance
- Confirm handover
- Add restricted evidence reference
- Resolve / close / reopen

Every mutation requires trusted server validation of active membership, canonical role, geographic/case scope, current record state, reason where required, and audit event. Client UI role labels and hidden buttons are not security boundaries. No direct Firestore write from the UI for emergency stop, walk completion, incident severity, handover, or closure.

## 9. Failure and degraded states
The UI must distinguish:
- Submitting / confirmed / failed / outcome unknown
- Owner notified / acknowledgement pending / acknowledged / notification failed
- Handover pending / confirmed / failed / outcome unknown
- GPS fresh / stale / unavailable / accuracy unknown
- Service running / pause requested / paused confirmed / stop requested / stopped confirmed
- Evidence upload pending / complete / failed

For ambiguous network outcomes, do not blindly retry non-idempotent actions. Show incident ID and safe next step; use an idempotency key/request ID supplied by the trusted contract. Never label an incident escalated or a walk stopped solely because the user tapped a button.

## 10. Privacy, audit, and access
- Incident records and evidence are restricted data; minimum necessary access only.
- Filter queue and detail data by authoritative server-side scope.
- Avoid displaying medical, identity, phone, or private evidence fields to users without explicit need.
- Preserve source/provenance and immutable audit history; no ordinary-user deletion/editing of original evidence.
- Record actor, timestamp, action, reason, before/after state, incident/walk/booking references, request ID, and backend result where supported.
- Conflict-of-interest or owner-involved cases route to an independent senior decision-maker/Founder delegate.
- Retention, legal hold, and deletion follow POL-014 and approved schedule; do not invent retention periods.

## 11. Team 01 contract request (blocking)
Before implementation, Team 01 must provide exact source branch and commit SHA, exported callable/service names, request/response schemas, authorization rules, error catalogue, idempotency/retry behavior, audit guarantees, and Emulator evidence for:
1. Create incident and unique incident ID generation.
2. Severity/category updates and severity escalation.
3. Assign/reassign owner and acknowledgement.
4. Primary and backup escalation dispatch, including durable record and delivery semantics.
5. Safe pause/stop operation for an active walk; exact preconditions and result states.
6. Replacement/backup request and assignment, if supported.
7. Safe-handover confirmation (who can confirm, required evidence, and when handover is mandatory).
8. Resolve, close, reopen, and corrective-action tracking.
9. Restricted incident/evidence read and write authorization.
10. Idempotency and ambiguous-outcome recovery for each mutation.

Emulator evidence must include allowed/denied roles, out-of-scope city/zone, owner conflict, duplicate request, failed notification, unavailable backup, handover not completed, stale GPS, and retry after ambiguous outcome.

## 12. Founder / policy-owner decisions required
- Confirm POL-016 and POL-007 safe-handover rules.
- Name primary/backup incident leads and operating-hour coverage.
- Approve severity-specific response targets and customer update cadence.
- Confirm local emergency/veterinary guidance and backup assistance route per launch area.
- Define who can authorize restart after each severity.
- Approve minimum evidence and privacy/retention controls with relevant specialist.
- Confirm replacement walker qualification and customer-consent exceptions for immediate danger.

## 13. Admin acceptance checklist — planned, not executed
- [ ] Queue shows only authorized-scope incidents.
- [ ] Unique incident ID and reported timestamp are server-assigned.
- [ ] Severity labels exactly match POL-016 SEV-1–SEV-4.
- [ ] Severity can be raised; lowering requires explicit authorized review.
- [ ] SEV-1 response never waits for internal approval.
- [ ] Owner acknowledgement and backup escalation are visibly distinct.
- [ ] Failed primary notification does not appear as acknowledged.
- [ ] Active walk stop/pause requires trusted confirmation.
- [ ] Injured walker is not required to continue the walk.
- [ ] Customer is not assumed to attend or take over dog custody.
- [ ] Replacement/backup attempts and customer consent are recorded.
- [ ] Handover pending blocks closure/restart when required.
- [ ] Full walk cannot be marked complete after early stop.
- [ ] Stale/unavailable GPS is not presented as live verified location.
- [ ] Unauthorized and out-of-scope reads/writes are denied server-side.
- [ ] Evidence access is restricted and audited.
- [ ] Duplicate/ambiguous requests do not create duplicate incidents/actions.
- [ ] Conflicted owner routes to independent reviewer.
- [ ] Resolve/close/reopen transitions are audited and tested.
- [ ] Mobile and accessibility states cover emergency use.

All items above are **PLANNED — NOT EXECUTED**. No UI implementation, backend integration, Emulator test, or operational drill is claimed.

## 14. Status and guardrails
- POL-016 source reviewed; page itself is marked DRAFT / NOT APPROVED / NOT IMPLEMENTED / NOT TESTED.
- This Admin workflow spec is DRAFT and needs Founder/policy-owner + Team 01 review.
- Existing Admin Live Operations audit found no incident intake, incident queue, safe-handover action, emergency stop, or emergency notification control in the inspected screen.
- Team 01 trusted incident/safety operation contract: not established by Team 02.
- API wiring: intentionally blocked.
- Firebase rules/functions/schema/production data: no changes.
- Runtime UI: no changes.
- Tests/Emulator/CI: not run for this documentation-only task.
- PR #51 remains Draft and unmerged; no deployment.

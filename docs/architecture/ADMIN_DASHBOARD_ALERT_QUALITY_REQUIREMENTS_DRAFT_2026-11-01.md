# Admin Dashboard Alert Quality — Implementation Requirements (Draft)

**Task:** ADM-P2-04
**Date:** 2026-11-01
**Status:** DRAFT — requirements only; source policies and alert thresholds remain unapproved. Not implemented, not tested.
**Repository:** DOJOWALK/DOJO-WALK-Admin
**Branch:** ui/notion-brand-foundation-2026-10-28
**PR:** #51 — Draft, unmerged

## 1. Purpose and implementation boundary

Define reliable Dashboard operational alerts that help Admin identify actionable booking, walker, payment, active-walk, GPS and service-health exceptions without creating false alarms or implying facts that the system has not verified.

Team 02 owns the Admin dashboard presentation, alert grouping, filters, acknowledge/resolve UI requirements and accessibility. Team 01 owns trusted event/data contracts, alert detection/aggregation, server-side authorization, deduplication, freshness and delivery. Policy owners approve thresholds, severity, response ownership and escalation times.

No new alert threshold, production notification, backend listener, API integration or Firebase schema is authorized by this draft. API/Firebase integration remains deferred until app readiness and cross-team contracts are approved.

## 2. Evidence reviewed

Notion sources reviewed:

- **POL-023 — Production Monitoring, Alerts & Service Health Policy:** Draft — not approved, implemented or tested. Requires customer/safety-impact monitoring, named alert owners, approved thresholds, distinction between live/stale/delayed/missing/estimated data, safe diagnostics, tested routing, monitoring-pipeline health and no unsupported service-health claims.
- **POL-005 — Booking & Walker Assignment Policy:** Draft — Founder approval required. A booking is assigned only after an eligible Walker accepts and the backend confirms it. Unassigned/exhausted-candidate cases must escalate to Central Operations; offer timeout/attempt thresholds remain open.
- **POL-026 — Walker Availability, Booking Assignment & Replacement Policy:** Draft — not approved, implemented or tested. Availability, eligibility, assignment offer and confirmed assignment are separate facts. Offer timeout and escalation thresholds require approval. Do not punish a Walker for a missed notification without reviewing delivery/system evidence.
- **POL-035 — Walker Attendance, Shift Management, Leave & Emergency Replacement Policy:** Draft. Shift, attendance, leave and emergency replacement states must not be conflated.
- **POL-016 — Incident & Emergency Management Policy:** Draft. Safety incidents require their own severity, owner, escalation and safe-handover process; a generic dashboard alert is not an incident workflow.
- **POL-012 — Payment, Refund & Reconciliation Policy:** Draft. Payment attempts, trusted verification, refunds and reconciliation outcomes are distinct. Client screenshots/events are not proof of payment.
- **POL-032 — Customer Notifications, Communication Preferences & Messaging Policy:** Draft. Notifications must reflect authoritative state; delivery receipt is not proof of reading; emergency assistance must not depend solely on push delivery.
- **Cross-App Live Tracking & Booking Data Contract — Readiness:** Draft, architecture review required, explicit NO-GO for production integration. Canonical walk/location schema, live feed, sampling, freshness threshold, scope and retention remain undecided.
- **Booking API Contract & Callable Implementation Gate:** Working draft, not approved for production implementation. Request received does not imply availability, payment, booking confirmation or Walker assignment.

Existing Admin source audits (2026-11-01):

- Dashboard's pending-status booking count is used as a proxy for unassigned bookings; that query does not independently verify walkerId == null.
- Dashboard's offline count does not distinguish a Walker safely off-shift from a Walker unreachable during an active walk.
- Failed-payment count is based on payment records whose status is failed; it does not establish a full provider reconciliation or identify all unknown/pending outcomes.
- Dashboard gross paid-payment total is not net revenue, settlement or payout.
- Live Operations derives LIVE from isOnline == true; this does not prove a current active walk or fresh GPS.
- The Live Operations route-history query was observed filtering by walkerId, ordering timestamp ascending and limiting to 300; it is not a confirmed active-walk live feed and can mix route sessions.
- The inspected Admin screens do not evidence a connected, unified alert engine with deduplication, ownership, acknowledgement and resolution lifecycle.

These findings are bounded to inspected Admin source paths and are not proof that no separate backend monitoring exists.

## 3. Alert quality principles

1. An alert must represent a verified condition from an authoritative source, not a UI label or weak proxy.
2. Distinguish business state, operational presence, active service state, telemetry freshness and provider outcome.
3. Every alert must include condition, affected entity/reference, first/last observed time, source, severity, owner/route and current alert lifecycle state.
4. Unknown, stale, unavailable and failed data must not be rendered as zero or healthy.
5. Alert creation must be idempotent and deduplicated for one continuing condition; repeated independent incidents remain distinct.
6. Resolve an alert only when the underlying condition is verified as recovered or an authorized reviewer records an approved disposition. Acknowledge is not resolve.
7. Alert delivery success is not alert acknowledgement; acknowledgement is not remediation.
8. Thresholds, grace periods, retry cadence, severity, response targets and escalation time require policy approval; do not hard-code guesses.
9. Use backend detection for trusted business/security/payment conditions. Client timers and dashboard refreshes cannot be the sole source of critical detection.
10. Restrict details by role/geographic scope and minimize customer, pet, financial and precise location data.
11. Alert fatigue must be reduced through grouping, deduplication and meaningful ownership—not by suppressing critical safety/security signals.
12. Monitoring the monitoring pipeline is necessary: missing telemetry cannot silently imply that all services are healthy.

## 4. Dashboard alert categories and detection requirements

### A. Booking and assignment

Candidate alert conditions:

- A booking is confirmed eligible for assignment but remains in a backend-defined unassigned/needs-operations state beyond an approved age/threshold.
- Assignment attempts are exhausted or no eligible Walker is available.
- An offer is stuck, expired or has an inconsistent terminal state.
- Two assignment records conflict or a booking appears assigned without a confirmed accepted offer.
- An upcoming booking is at risk because an assigned Walker has become unavailable or approved leave conflicts with the service time.
- Reassignment or replacement has failed or requires Operations action.

Required evidence:

- Authoritative booking ID and state.
- Confirmed assignment/offer state and attempt history.
- Service time and date basis/timezone.
- Relevant service area and authorized City/Zone scope.
- Last transition/offer update time and source event.
- Exception reason and Operations owner.

Do not trigger an unassigned alert from status == pending alone. Do not treat a sent offer or notification receipt as confirmed assignment. Do not apply a universal age threshold until POL-005/POL-026 owners approve it.

### B. Walker attendance and availability

Candidate alert conditions:

- A Walker has an active assigned walk but a verified attendance/check-in/start event is missing after an approved grace period.
- A Walker's approved leave/availability change creates a conflict with a future accepted assignment.
- A Walker is expected on an approved shift and attendance evidence is missing, subject to approved attendance policy.
- A replacement is required but no accepted replacement is confirmed.

Required evidence:

- Walker ID and authorized scope.
- Approved shift/availability version and time window.
- Active booking/walk reference where applicable.
- Attendance event state and last update.
- Leave state and effective period.
- Notification delivery/system evidence before any missed-response conclusion.

Do not equate isOnline == false with absence, misconduct, or missed work. A Walker outside an assigned shift should not generate an operational absence alert. Do not automatically penalize a Walker from one missed push notification or connectivity failure.

### C. Payment and refund integrity

Candidate alert conditions:

- A payment outcome remains unknown/pending beyond a provider-approved reconciliation window.
- Provider callback/signature validation fails.
- Provider event and internal payment record disagree on amount, currency, transaction reference or status.
- Duplicate provider event or idempotency conflict requires investigation.
- Refund is approved/initiated but provider completion or reconciliation fails.
- Reconciliation backlog or settlement mismatch exceeds an approved threshold.

Required evidence:

- Internal payment/refund reference and provider transaction reference where authorized.
- Trusted provider/server event and verification result.
- Amount and currency with explicit units, only for authorized Finance roles.
- Provider event time, received time and reconciliation state.
- Idempotency/correlation reference and safe failure code.
- Assigned Finance owner and evidence link.

A failed payment count is not a complete payment-integrity monitor. Do not mark an unknown outcome as failed, retry a possibly successful payment blindly, or label a refund complete from a request/approval event. Do not expose full payment credentials or bank details.

### D. Active walk and GPS / communication

Candidate alert conditions:

- An authoritative active walk has no location update within an approved freshness window.
- Location events are delayed, stale, unavailable, invalid or outside approved accuracy/quality criteria.
- A walk start/stop/handover transition is missing, contradictory or unexpectedly terminated.
- Partner-to-backend location ingestion fails or the monitoring pipeline stops receiving expected events.
- An active walk has a safety incident or unresolved handover requiring immediate incident workflow.

Required evidence:

- Stable walkId and linked bookingId.
- Assigned Walker identity and authorization.
- Server-authoritative walk state and state transition times.
- Last accepted location timestamp, ingestion timestamp, accuracy and source quality where available.
- Freshness classification from an approved backend contract.
- Last successful heartbeat/event and safe diagnostic reference.
- Incident ID and severity when safety-related.

Do not use isOnline as proof of active walk or fresh GPS. Do not infer an active walk solely from a booking's assigned Walker. Do not mix multiple walks into one route. Do not expose stale coordinates as live. The exact GPS stale threshold, sampling cadence, accuracy threshold, and customer-visible behavior remain unresolved in the cross-app contract.

A GPS gap alone is not proof that a dog is missing or that a Walker has abandoned the walk. If there is credible safety risk, create or link the incident workflow and follow POL-016/POL-007 safe-handover requirements; do not wait for a dashboard threshold or push delivery.

### E. Platform and integration health

Candidate signals under POL-023:

- Cloud Function invocation failures, elevated errors/latency or quota/resource exhaustion.
- Firestore permission-denied spikes, index/configuration failures or listener failures.
- Storage access errors.
- Payment provider callback/signature failures.
- Notification queue age, delivery failure or duplicate messages.
- Location ingestion failure or stale monitoring watermark.
- Deployment/hosting/DNS/certificate failure and unexpected cost signals where available.

Each signal needs an inventory entry: environment, owner, backup owner, source, normal behavior, approved threshold, alert route, diagnostic link, privacy classification and runbook. A page failing to load must not be displayed as zero alerts.

## 5. Alert severity and routing

POL-023 proposes Critical and High categories for safety/security/broad outage/payment integrity and major customer journey failures. This is a proposal in a Draft policy, not an approved final severity matrix.

Requirements:

- Map alert severity to the approved POL-023/POL-016 incident model without silently converting an operational alert into a formal incident.
- Define severity, response target, acknowledgement target, escalation owner and communication route only after approval.
- Every alert must have one accountable primary owner and a backup/escalation route.
- Safety incidents use the formal incident workflow and SEV taxonomy; the Dashboard alert is only an entry point/reference.
- Payment alerts route to authorized Finance; assignment/coverage alerts route to Central Operations; technical health alerts route to the service owner; geographic managers receive only their assigned scope.
- Founder/CEO receives only approved executive escalations, not every routine operational alert.
- If no owner/route is configured, show Owner not configured and raise a governance/configuration gap; do not pretend the alert is assigned.

## 6. Alert lifecycle, grouping and deduplication

Candidate lifecycle states:

- open — verified condition currently requires attention.
- acknowledged — authorized owner has accepted responsibility; condition may still exist.
- investigating — investigation is active.
- mitigated — immediate impact reduced; condition not yet fully verified as resolved.
- resolved — recovery or approved disposition is verified with evidence.
- reopened — condition recurred or resolution was invalidated.
- suppressed — only under approved maintenance/noise policy, with reason, owner and expiry.

The canonical states and storage contract require Team 01 approval. These are not existing production enums.

Deduplication requirements:

- Use a stable alert fingerprint based on condition type, affected entity, environment and relevant scope/time window.
- Repeated observations of one continuing condition update first/last seen, occurrence count and evidence references rather than creating an unbounded alert storm.
- A genuinely new booking, payment, walk or independent incident must remain a separate alert.
- Grouping must never hide distinct affected customers, transactions or safety incidents from authorized responders.
- Suppression must be time-bounded, attributable and auditable. Critical safety/security alerts must not be silently suppressed.
- Recovery clears the condition only after source confirmation; a temporary missing telemetry sample must not create repeated open/resolve oscillation.
- Retain related alert history and link duplicates/recurrences to the canonical alert.

## 7. Dashboard presentation and interaction

Top-level dashboard should prioritize:

1. Critical safety/security incidents and active-walk continuity issues.
2. Payment integrity and broad customer journey failures.
3. Upcoming booking assignment/coverage exceptions.
4. Operational/technical warnings and stale telemetry.

This ordering is a proposed presentation hierarchy, not a policy-approved severity/response SLA.

Each alert card/row should show:

- Clear human-readable title and category.
- Severity and lifecycle state.
- Affected booking/walk/payment/service reference (masked as needed).
- First seen and last updated timestamp with timezone.
- Source/freshness indicator and evidence availability.
- Authorized City/Zone scope.
- Accountable owner/queue and next recommended action.
- Link to the relevant detail, booking, incident or diagnostic view.

Interactions:

- Acknowledge, assign, transfer, escalate, mitigate, resolve and suppress controls remain unavailable until their backend contracts, role permissions and audit requirements are approved.
- Acknowledgement must record actor/time and not clear the alert.
- Resolution requires reason and source evidence or an approved disposition.
- Filters must be server-side and authorization-aware.
- Preserve filters and list position when opening and returning from details.
- Provide loading, empty, stale, partial, unavailable, access-denied and query-failed states distinctly.
- No active alerts may be shown only after a successful, sufficiently fresh query of all required sources. Otherwise show Alert status unavailable/partial.
- Display a monitoring coverage indicator identifying required sources that are not connected or stale.
- Mobile layout must preserve severity, affected entity and owner without relying on color alone.

## 8. False-positive and false-negative controls

Before a condition becomes a production alert:

- Define authoritative source and event semantics.
- Define freshness/watermark and expected missing-data behavior.
- Approve threshold, grace period and severity.
- Test normal operating cases, expected off-shift/offline cases, holidays/leave, app backgrounding, network loss and provider delay.
- Test duplicates, retries, late/out-of-order events and recovery.
- Compare alert outcomes with source records and an independent expected result.
- Define suppression/maintenance behavior and monitor suppressed counts.
- Review missed alerts after incidents and false alerts with operational owners.
- Monitor the alert pipeline itself; a broken feed must create a telemetry-health warning rather than a green dashboard.

No numerical thresholds or SLAs are selected by this document.

## 9. Privacy and authorization

- Enforce canonical role and geographic scope on backend alert query and detail endpoints.
- City Manager and Zone Supervisor see only assigned City/Zone alerts and approved fields.
- Finance alert details are limited to Finance-authorized roles.
- Support sees only assigned case/incident details.
- Sensitive incident evidence, dog safety notes, customer identity, precise GPS and payment details are not exposed on broad dashboard cards.
- Use masked references and secure drill-down to authorized source records.
- Log sensitive alert detail access and privileged lifecycle changes under the approved Audit Logs contract.
- Hiding an alert card or navigation item is not authorization; direct API access must be denied outside scope.
- Alert delivery channels and notification preferences must follow POL-032; urgent safety response cannot depend solely on push.

## 10. Monitoring ownership and operational readiness

Before activation, every alert definition must have:

- Alert ID/name and business purpose.
- Authoritative source and query/event definition.
- Environment and affected workflow.
- Approved condition, threshold and freshness.
- Severity and incident mapping.
- Primary owner and backup owner.
- Acknowledgement/response/escalation targets.
- Diagnostic/runbook link and first response steps.
- Deduplication/suppression/recovery semantics.
- Privacy classification, role/scope access and retention.
- Test cases, expected alert result and evidence of delivery.
- Last reviewed date, policy version and approval.

A dashboard with alert cards but no owner, route, runbook or verified source is not operationally complete.

## 11. Planned acceptance checklist — NOT EXECUTED

1. Pending booking count is not labeled unassigned unless the authoritative query verifies the approved unassigned condition.
2. Booking assignment alert requires backend-confirmed state and does not treat a sent offer as assignment.
3. Offer expiry/attempt exhaustion uses approved server-side thresholds and records the exception reason.
4. A future booking coverage alert checks approved Walker availability, shift, leave and assignment state.
5. isOnline == false alone does not create an attendance/missed-walk alert.
6. Off-shift Walker presence does not generate a false absence alert.
7. A missed notification alone does not trigger a punitive Walker alert.
8. Payment pending/unknown/failed/succeeded/reversed states are distinguished.
9. Payment mismatch alert uses trusted provider/server evidence and authorized Finance access.
10. Refund requested/approved/initiated/completed/reconciled states remain distinct.
11. Duplicate payment events do not create duplicate financial effects or unbounded alerts.
12. An active-walk GPS alert requires authoritative active walk ID and approved freshness contract.
13. isOnline or stale coordinates cannot be displayed as proof of current active GPS.
14. GPS gaps are distinguishable from confirmed safety incidents and trigger POL-016 workflow only when warranted.
15. Route data is isolated by walk ID/session and does not mix separate walks.
16. Monitoring-source outage is displayed as partial/unavailable, never as healthy zero.
17. Alert fingerprinting deduplicates a continuing condition without merging independent affected entities.
18. Acknowledge does not resolve; resolve requires verified recovery or approved disposition.
19. Suppression is reasoned, attributable, time-bounded and cannot silently hide critical safety/security alerts.
20. Every alert has an owner, backup route, diagnostic path and approved response target before production activation.
21. Role and geographic scope are enforced for list, detail and action endpoints.
22. Sensitive customer, pet, precise GPS and payment details are masked/minimized.
23. Filters, pagination, loading, empty, partial, stale, denied and failure states are tested.
24. Alert delivery and monitoring-pipeline failure are tested with synthetic events.
25. Static Analysis, full test suite and Flutter Web build are recorded against the exact implementation commit.

All checks above are planned. None is marked PASS or executed by this document.

## 12. Dependencies and decisions required

| Dependency | Required decision/evidence | Owner |
|---|---|---|
| Alert severity/thresholds | Severity mapping, numeric thresholds, grace periods, response/escalation targets | Founder/policy owner + Central Operations |
| Booking/assignment | Canonical states, unassigned definition, offer timeout/attempts and coverage conditions | Team 01 + POL-005/POL-026 owners |
| Walker attendance | Shift/leave/attendance evidence and exceptions | Operations + POL-035 owner |
| Payment monitoring | Provider callback, verified state, reconciliation and refund contracts | Team 01 + Finance |
| Live GPS | Canonical walk/location contract, freshness, accuracy, sampling, walk/session identity | Team 01 + Partner + Customer + POL-007 owner |
| Incident workflow | SEV mapping, safe handover, incident ownership and escalation | Central Operations + POL-016 owner |
| Monitoring platform | Service inventory, signals, alert routing, pipeline health and runbooks | Team 01 + Security/service owners |
| Notification delivery | Channels, retries, emergency fallback, delivery evidence | Team 01 + POL-032 owner |
| Role/geographic scope | Canonical roles and server-enforced assignment scope | Team 01 + POL-021 approval |
| Admin UI | Alert list/card/detail, filtering, lifecycle actions, partial/stale/error states | Team 02 |

## 13. Implementation sequence after gates clear

1. Approve POL-023 severity/threshold/ownership model and relevant booking, Walker, payment, incident and notification policies.
2. Team 01 publishes trusted event/query contracts and verifies server-side role/scope enforcement.
3. Resolve cross-app booking and live-walk/GPS schema, identity, freshness and writer/reader mismatch before activating those alerts.
4. Build alert detection, deduplication, recovery, suppression and monitoring-pipeline health in an isolated environment.
5. Verify alert behavior with synthetic events, normal/off-shift cases, provider delays, stale GPS, network loss, duplicates and recovery.
6. Team 02 implements dashboard presentation and lifecycle controls only against approved backend contracts.
7. Run authorization, widget, integration and end-to-end tests; test alert delivery and escalation routes.
8. Run Static Analysis, full test suite and Flutter Web build on the exact implementation commit.
9. Keep PR #51 Draft until policies, cross-app contracts and evidence are approved.

## 14. Current disposition

- Documentation-only deliverable.
- No Admin runtime/dashboard UI changes.
- No API or Firebase integration.
- No Firestore schema/rules/indexes/functions, monitoring provider, notification provider or production alert configuration changes.
- No thresholds, response SLAs or severity mapping approved by this document.
- No tests, Emulator runs or CI are claimed for this document.
- PR #51 remains Draft and unmerged.

# Admin Audit Logs — Implementation Requirements (Draft)

**Task:** ADM-P2-02  
**Date:** 2026-11-01  
**Status:** DRAFT — requirements only; source policies remain unapproved where noted. Not implemented, not tested.  
**Repository:** DOJOWALK/DOJO-WALK-Admin  
**Branch:** ui/notion-brand-foundation-2026-10-28  
**PR:** #51 — Draft, unmerged

## 1. Purpose and boundary

Define a trustworthy, privacy-minimizing Admin Audit Logs experience and its dependencies. Audit history must support accountability, security investigation, operational review and financial traceability without becoming a place to store secrets or duplicate sensitive source records.

Team 02 owns Admin UI requirements. Team 01 owns trusted event creation, server-side authorization, durable storage, integrity protections, and backend query contracts. API/Firebase integration remains deferred until cross-team contracts and policies are approved.

This document does not authorize a new collection/schema, a client-writable audit log, a retention duration, production monitoring, or a security/compliance claim.

## 2. Evidence reviewed

Notion policies reviewed:

- **POL-021 — Access Control, Admin Roles & Privileged Account Security Policy:** Draft, not approved/implemented/tested. Requires least privilege, server-side authorization, attributable privileged actions, security logging/monitoring, protected audit logs and defined retention.
- **POL-014 — Privacy & Data Access Policy:** Draft, not approved/implemented/tested. Calls for logs of privileged access, role/scope changes, sensitive document access where feasible, exports, payment/refund adjustments, deletion requests and security-rule changes; logs must not contain secrets or unnecessary personal data.
- **POL-020 — Data Privacy, Retention & Deletion Policy:** Draft, not approved/implemented/tested. Requires audit/accountability records, limited log readership, data-specific approved retention, legal holds and backup/restore handling.
- **POL-017 — Quality Assurance, Audits & Continuous Improvement Policy:** Draft, not approved/implemented/tested. Requires evidence-backed findings, redaction, restricted evidence access, independent review for high/critical findings where practical, and no silent alteration of audit history by ordinary users.
- **POL-016 — Incident & Emergency Management Policy:** Draft, not approved/implemented/tested. Requires incident IDs, timestamped factual actions/decisions, preserved evidence provenance, restricted access, audit history and controlled reopening/closure.

Existing Admin source audit (2026-11-01):

- Audit Logs screen is a UI-only prototype with four hard-coded examples.
- No connected audit-log stream, repository/service, detail retrieval, filter query or live audit source was identified in the inspected screen path.
- This bounded source inspection does not prove that no backend audit collection or logging capability exists elsewhere.

## 3. Non-negotiable design principles

1. Audit events must be created by trusted backend services or verified platform security sources, not by a client claiming that an action happened.
2. A UI action attempt and a successful state change are different facts. Record outcome explicitly: succeeded, denied, failed, pending/unknown where meaningful.
3. An audit event must be attributable to a human or service identity, action, target, timestamp, outcome and correlation context, subject to approved data minimization.
4. Audit records are append-only from the Admin user perspective. Corrections must be new, linked, reason-coded events; never silently overwrite or delete the original event.
5. Audit storage, queries, exports and retention controls require separate authorization. Super Admin status alone must not imply unlimited access.
6. Record facts, not conclusions. An access-denied event is not proof of malicious intent; an allegation is not a finding.
7. Do not log passwords, OTPs, access tokens, API keys, service-account keys, payment authentication secrets, full identity documents, or unnecessary personal/dog/location data.
8. Preserve source provenance and timestamps. Do not invent an event when source evidence is unavailable.
9. Log access to sensitive audit data and audit exports where technically feasible, while avoiding recursive infinite audit loops.
10. A missing audit event must be represented as a logging/telemetry gap, not treated as proof that the action did not occur.

## 4. Event catalogue — candidate coverage

Final event names, mandatory fields and source systems require Team 01 contract approval.

| Event family | Candidate events | Important evidence |
|---|---|---|
| Authentication & session | Admin sign-in success/failure, sign-out, session revocation, MFA/security challenge result where supported | Actor/service identity, time, outcome, safe reason/code; never credentials or OTP |
| Account & access lifecycle | Admin account activation/deactivation, role grant/revoke, scope assignment/change, privileged access review, emergency access | Before/after role and scope references, approver, reason, effective time, request/reference ID |
| Authorization | Sensitive read/export/action denied, scope mismatch, inactive account attempt, privileged action rejected | Resource category/reference, action, outcome, safe denial code; avoid copying record contents |
| Admin operations | Zone draft/review/approval/activation/deactivation, walker status actions, booking/support/incident state changes | Target ID, prior/new state where safe, actor, reason, approval and linked workflow ID |
| Finance controls | Payment verification/reconciliation, refund approval/completion, earnings adjustment, payout approval/status, financial correction | Financial reference IDs, amount/currency only where approved, actor/approver, evidence reference; no bank secrets |
| Privacy & data rights | Sensitive document access, customer data export, deletion/correction request, legal hold, retention action | Data category, purpose/reason, request/case ID, outcome; do not duplicate personal data |
| Security & configuration | Security-rule/configuration change, privileged credential/key lifecycle, unusual export alert, production deployment | Change/request ID, environment, actor, outcome, review reference; never log secret values |
| Incident & audit | Incident create/escalate/assign/close/reopen, evidence access, audit finding and remediation state | Incident/finding ID, severity, factual action, timestamp, owner and evidence provenance |

The table is a proposed coverage catalogue, not confirmation that these events are currently emitted or that every event is approved for launch.

## 5. Minimum event envelope — contract gate

Team 01 should propose a versioned event contract. Candidate fields to decide include:

- Immutable event ID.
- Event schema/version.
- Event type/category.
- Server-generated occurrence timestamp; ingestion timestamp where useful.
- Actor type (human/service/system), stable actor reference and role snapshot/reference where authorized.
- Action and target resource type/reference.
- Outcome (success/denied/failure/unknown) and stable safe reason code.
- Correlation/request/trace ID and related booking, case, incident, payment, payout or approval reference when applicable.
- Environment/source service.
- Approved geographic scope reference where relevant.
- Change summary or safe before/after values only for fields approved for audit capture.
- Evidence/source reference and integrity metadata if supported by the selected architecture.

Do not copy full customer profiles, dog notes, precise GPS coordinates, identity documents, payment credentials or free-form payloads into the event. Use a restricted source reference where investigators need authorized access to underlying evidence.

No field is mandatory for implementation until Team 01 defines and approves the contract, privacy classification and migration/compatibility behavior.

## 6. Event lifecycle and integrity

- Generate event identity and trusted timestamp on the server/platform side.
- Link an event to the business operation using a correlation or workflow identifier.
- Record the operation outcome; do not record success before the underlying transaction is confirmed.
- For transaction-backed state changes, define whether the audit event is committed atomically with the state change or emitted through a reliable outbox/event mechanism. Team 01 must document failure and replay semantics.
- Use idempotency/deduplication so retries do not create misleading duplicate business events. Preserve legitimate repeated attempts as separate attempt events where required.
- Protect event storage from ordinary client writes, updates and deletes.
- Define integrity/tamper detection and privileged break-glass procedures. Do not claim cryptographic immutability unless implemented and independently verified.
- Corrections, annotations, investigation conclusions and retention/legal-hold decisions are separate linked records with actor, time, reason and approval.
- A source event that cannot be delivered must enter a controlled retry/dead-letter/alert path; silent loss is unacceptable for critical security/financial actions.

## 7. Admin Audit Logs screen requirements

### List view

Candidate columns:

- Timestamp (display timezone clearly; retain authoritative timestamp).
- Event category/type.
- Actor (masked or stable identifier based on viewer permission).
- Action and target reference.
- Outcome.
- Geographic scope where relevant and authorized.
- Correlation/event ID.

### Filters and search

Potential filters, subject to approved backend query support:

- Time range.
- Event category/type.
- Actor.
- Outcome.
- Target resource type/reference.
- City/zone scope.
- Related booking, case, incident or financial reference.

Requirements:

- Search and filters must query the authorized server-side dataset; local filtering of a hard-coded or partially fetched list is not sufficient.
- Display active filters and timezone.
- Validate date ranges and bounded result limits.
- Use cursor pagination or another Team 01-approved stable pagination contract; do not assume offset pagination over a changing event stream.
- Preserve filters when opening an event and returning to the list.
- Show loading, empty, partial, stale, access-denied, query-failed and retention-limited states distinctly.
- Do not silently omit records when pagination or source retrieval fails.

### Event detail

Show only fields the viewer is authorized to see:

- Event ID/type/schema version.
- Occurrence and ingestion timestamps, if supplied.
- Actor/service reference and approved role context.
- Action, target, outcome and safe reason code.
- Correlation and related workflow references.
- Approved before/after summary, with sensitive fields masked or omitted.
- Source/evidence references and integrity verification status, if supported.
- Any linked correction/review/incident record.

Do not render raw untrusted payloads as executable content. Escape free text and safely display unknown future event fields.

## 8. Access control and separation of duties

- Apply the approved role × action × geographic scope matrix on the backend for every list, detail and export request.
- Enforce least privilege at field level where event content includes sensitive data.
- Super Admin, Central Admin, City Manager, Zone Supervisor, Support, Finance and Founder/CEO permissions must follow the approved POL-021 and Team 01 role contract. This document grants no access.
- A City Manager must not see another city's restricted events; a Zone Supervisor must not see unrelated zones by default.
- Finance access should focus on finance evidence and not automatically include dog safety notes or precise live-location history.
- Support access should be tied to assigned cases and approved escalations.
- Sensitive audit access should itself be logged where feasible.
- No person should approve their own privileged access grant, conflicted investigation, or risk exception where separation is required.
- Emergency/break-glass access must be purpose-limited, time-limited, attributable, reviewed afterward and follow the approved emergency process.
- Hiding navigation items is not authorization; direct backend requests must be denied when access is not permitted.

## 9. Export and evidence handling — disabled until separately approved

The inspected screen does not have a connected export workflow. Do not add a working export action until approval and implementation exist.

Before export is enabled, approve:

- Which roles and scopes can export which event categories.
- Whether export is aggregate, selected-event or bounded time-range.
- Column/field minimization and masking.
- Maximum range/row count and secure delivery/download mechanism.
- File expiry, retention, deletion and recipient restrictions.
- Audit event for requester, approver where required, filter criteria, generated artifact reference, download/access and outcome.
- Protection against bulk extraction and repeated enumeration.
- Legal-hold and incident-evidence handling.

Screenshots or downloaded exports must not become an uncontrolled parallel audit store.

## 10. Retention, deletion, legal hold and backups

- Do not invent a retention duration in Admin code or this specification.
- POL-020 requires a data-specific retention schedule, accountable owner, deletion method, backup lifecycle and legal-hold behavior to be approved.
- Treat audit/security/financial/incident records as distinct data categories; one blanket retention period must not be assumed.
- When deletion is permitted, record the authorized retention action without unnecessarily preserving the data that was meant to be deleted.
- Where a valid legal/safety/accounting hold applies, restrict use, record reason and review owner/date as approved.
- Define how backup restoration avoids silently reintroducing records that were lawfully deleted or restricted.
- Limit who can view audit records and define audit-log access review and retention controls.
- Retention, deletion and restore procedures require legal/privacy/finance review as applicable.

## 11. Monitoring and alert requirements

Candidate security signals for Team 01 and security owner review:

- Unexpected role/scope changes or privilege escalation.
- Repeated authorization failures or cross-scope access attempts.
- Unusual/bulk exports or sensitive record access.
- New/rotated/revoked privileged credentials or service-account keys.
- Security-rule/configuration changes.
- Audit event ingestion failures or integrity verification failures.
- Critical financial or incident actions with missing audit evidence.

Alert thresholds, routing, response targets and ownership are not defined here. They require approved risk thresholds, actual telemetry and tested escalation routes. Do not create noisy or unsupported “suspicious user” labels from a single failed request.

## 12. Planned acceptance checklist — NOT EXECUTED

1. Ordinary Admin clients cannot create, update or delete trusted audit events.
2. An authorized action records a server-trusted event with correct actor, target, timestamp and outcome.
3. A denied action is recorded where the approved security event source supports it.
4. Failed/unknown operation outcomes are not falsely recorded as successful.
5. A transaction failure cannot leave a misleading success audit event.
6. Retries do not create duplicate business effects or ambiguous duplicate event records.
7. Repeated independent denied attempts remain attributable as separate attempts where required.
8. Passwords, OTPs, tokens, keys and payment authentication secrets never appear in event payloads.
9. Sensitive personal, dog, identity and precise location data are minimized or masked.
10. Role and geographic scope are enforced for list, detail and direct API access.
11. A user cannot read another city's/zone's restricted audit events by changing IDs or query filters.
12. Sensitive audit-detail reads and exports are themselves logged where supported.
13. Audit history cannot be silently altered by ordinary users.
14. Corrections are linked, reason-coded and attributable without overwriting the original event.
15. Pagination is stable under concurrent new events and does not silently skip/duplicate records.
16. Query failure, partial source failure and retention-limited results are visibly distinguished from empty results.
17. Export remains unavailable until approval, masking, authorization, audit and retention controls are tested.
18. Legal hold prevents unauthorized disposal and is visible only to authorized roles.
19. Backup restore does not silently reintroduce records that should remain deleted/restricted.
20. Monitoring alerts route to an assigned owner and are tested with safe synthetic events.
21. Evidence is redacted and access-controlled; tests use synthetic/minimized data.
22. Static Analysis, full test suite and Flutter Web build are recorded against the exact implementation commit before claiming completion.

All checks above are planned. None is marked PASS or executed by this document.

## 13. Dependencies and decisions required

| Dependency | Decision/evidence required | Owner |
|---|---|---|
| Event contract | Event names, envelope, trusted producer, timestamp, outcomes, correlation and versioning | Team 01 |
| Write/integrity architecture | Atomicity/outbox, retries, dedupe, tamper detection, privileged break-glass | Team 01 + Security |
| Role and scope matrix | Canonical roles, permissions, geographic assignment and field-level restrictions | Team 01 + POL-021 approvers |
| Sensitive-data classification | What is logged, masked, linked or excluded | Privacy/Security owner + Founder |
| Retention/legal hold | Category-specific durations, triggers, exceptions, backup and deletion process | Founder + legal/privacy/finance |
| Monitoring | Alert thresholds, ownership, escalation and tested routes | Security owner + Central Operations |
| Export governance | Permitted categories, roles, range, masking, expiry and audit | Founder + Privacy/Security |
| Admin UI contract | List/detail/filter/pagination/error states and accessibility | Team 02 |

## 14. Implementation sequence after approval

1. Approve POL-021 role matrix and POL-014/POL-020 data classification and retention decisions.
2. Team 01 publishes the versioned audit event and read-query contracts with integrity, failure and authorization evidence.
3. Verify direct read/write authorization and negative role/scope tests in Emulator using synthetic data.
4. Team 02 implements list/detail/filter/pagination and all loading/empty/denied/failure states against the approved contract.
5. Add unit, widget, integration, security and audit-integrity tests.
6. Verify representative events end-to-end for access changes, privileged operations, finance, privacy requests and incidents.
7. Add monitoring/export only after separate approvals and tested workflows.
8. Run Static Analysis, full test suite and Flutter Web build on the exact implementation commit.
9. Keep PR #51 Draft until required policy approvals and evidence are complete.

## 15. Current disposition

- Documentation-only deliverable.
- No Admin runtime/UI changes.
- No API or Firebase integration.
- No Firestore collection/schema/rules/indexes/functions or storage changes.
- No log ingestion, alerting, export or retention job changes.
- No tests, Emulator runs or CI are claimed for this document.
- PR #51 remains Draft and unmerged.

# Admin Support Case Management & Notification Delivery Requirements — Draft
Date: 2026-11-01
Team: 02 — Admin App
Backlog items: ADM-P1-05
Status: **DRAFT / POLICY-DEPENDENT / NOT APPROVED / NOT IMPLEMENTED / NOT TESTED**
Notion sources reviewed:
- POL-009 — Customer Support & Complaints Policy (Draft; Founder approval required)
- POL-024 — Customer Support, Complaints, Refunds & Dispute Resolution Policy (Draft; not approved, implemented or tested)
- POL-032 — Customer Notifications, Communication Preferences & Messaging Policy (Draft; not approved, implemented or tested)
- POL-016 — Incident & Emergency Management Policy (Draft; not approved, implemented or tested)
- Related: POL-014 Privacy & Data Access, POL-029 Cancellation/Reschedule/No-Show/Refund, POL-031 Customer Account/Profile/Consent.
Tracking PR: #51 (Draft, unmerged)

## 1. Purpose and current source baseline
Define the Admin requirements for one accountable support case workflow and trustworthy notification operations.

Existing Team 02 source audit findings:
- Support Center is a UI-only queue prototype with three hard-coded sample records and local filters.
- Assignment, escalation, transfer and resolution controls are disabled.
- No connected Firestore case stream, case repository/service, create-case form, evidence upload, case mutation or notification integration was found in the inspected Support Center paths.
- Notification Center is a UI-only prototype with four hard-coded examples and local search/category filters.
- Send/Retry are disabled; no delivery, acknowledgement, preference update, read/unread, receipt or audit operation was found connected in the inspected Notification Center paths.
- Dashboard shows pending-status bookings as a proxy for unassigned bookings, failed payments and offline walkers; these counts have known semantic limitations and do not constitute a support/notification alert engine.

These are bounded source-inspection findings, not proof that no separate backend/provider workflow exists elsewhere.

## 2. Non-negotiable support principles
1. One company-owned case process should serve customers and walkers; route internally without forcing a reporter to restart or repeat the story.
2. Every case has one accountable primary owner until an explicit accepted transfer.
3. Immediate dog/person safety, security/privacy exposure and payment integrity risks outrank ordinary queue order.
4. A case's receipt, investigation, decision, financial action, follow-up and closure are separate events.
5. A sent reply does not mean the complaint is resolved.
6. Do not promise a refund, compensation, response deadline, operating hours or outcome unless approved and supported.
7. Do not ask for passwords, OTPs, UPI PINs, card security codes or full payment credentials.
8. Record facts separately from allegations, assumptions and unverified evidence.
9. Use company-controlled contact channels only after provision and monitoring are verified.
10. Do not use support tools to bypass booking, safety, payment, privacy or role/scope controls.

## 3. Support case queue
Proposed Admin destination: **Support / Cases**.

### Queue columns
- Case reference
- Created/last-updated time
- Reporter type (Customer / Walker / Staff / Other)
- Category and subcategory
- Severity (provisional until policy approval)
- Related booking/walk/payment/incident reference (masked as needed)
- City/Zone or other authorized operational scope
- Primary owner / assigned team
- Current case state
- Next action / next-update target (only if approved)
- Safety, privacy/security or financial-integrity flags
- Age/overdue indicator only after an approved SLA exists

### Queue filters
- Case state
- Severity
- Category
- Reporter type
- Primary owner / team
- City/Zone within viewer scope
- Created/updated date
- Safety/privacy/security/financial flag
- Linked booking/walk/payment/incident reference
- Awaiting customer / internal team / provider / decision / follow-up

Search, counts, filters, pagination, exports and autocomplete must enforce server-side authorization and geographic/case scope. Avoid exposing whether an out-of-scope person's case exists.

## 4. Case intake and detail
### Minimum intake data
- Server-generated unique case ID and received timestamp
- Reporter account/reference and verification outcome (not raw credentials)
- Reporter type and approved contact route
- Category/subcategory
- Factual description and event time
- Related booking, walk, payment, refund, incident or notification event ID where applicable
- Provisional severity and reason
- City/Zone or scope reference when relevant
- Immediate safety/privacy/security/financial-integrity flag
- Primary owner and consulted teams
- Next action and next update target if configured
- Evidence references with access classification
- Communication log, decisions, audit events and resolution outcome

Collect the minimum necessary information. Do not make optional sensitive fields mandatory without policy approval.

### Case detail sections
1. Overview and current owner
2. Reporter and verification summary
3. Category, severity and risk flags
4. Related booking/walk/payment/incident timeline
5. Evidence and attachments (restricted)
6. Internal notes (not customer-visible)
7. Reporter-visible messages
8. Assignment, transfer and escalation history
9. Decision and approval history
10. Corrective actions / follow-up
11. Closure, reopen and appeal history
12. Audit trail

Internal notes and customer-facing messages must be visually and technically distinct. Never expose internal risk notes, staff-only evidence or another person's personal data through a customer-visible reply.

## 5. Proposed case lifecycle — mapping and approval required
The following are UI workflow concepts, not approved backend enum values:
- New / received
- Verification needed
- Triage
- Open / investigating
- Waiting for reporter
- Waiting for internal team
- Waiting for Finance/provider
- Escalated
- Decision pending
- Resolved (decision recorded and required actions complete)
- Closed
- Reopened / appeal

A case must not be closed simply because a message was sent or the reporter did not immediately reply. Closure rules, inactivity handling, reopen windows and appeal route require approval.

## 6. Category and severity model
### Proposed categories from POL-009
- Booking creation/status
- Walker assignment / no available Walker
- Arrival, lateness, missed pickup / no-show
- Walk quality / service conduct
- Dog safety, missing dog, injury, bite / incident
- Customer/Walker safety or threatening conduct
- Cancellation, rescheduling or refund
- Payment, receipt or duplicate charge
- Walker earnings/payout
- App, login, map, GPS or notification
- Privacy, data access or suspected account compromise
- Staff conduct / discrimination
- Feedback / suggestion / other

### Provisional severity
POL-009 proposes S0–S3; POL-016 separately defines SEV-1–SEV-4. These systems must not be silently merged:
- POL-009 S0: critical safety/security
- POL-009 S1: urgent live service
- POL-009 S2: time-sensitive service/finance
- POL-009 S3: standard
- POL-016 SEV-1..SEV-4: incident severity for emergency/incident management

Team 01/Product/Operations must approve a cross-reference and source-of-truth severity model. A safety/privacy/security flag may escalate a case independently of its ordinary category. When uncertain, route for safer review; do not automatically downgrade.

No response SLA, escalation timer, 24/7 coverage, operating hours or on-call availability is approved by this document.

## 7. Ownership, assignment, transfer and escalation
- Each case has one primary accountable owner.
- Consulted teams may include Central Support, Area Manager, Safety Lead, Finance, Privacy/Security, Engineering or Founder/CEO.
- Area Manager access is limited to assigned city/zone; out-of-scope work goes to Central.
- Finance owns authorized payment reconciliation/refund decisions; Support may gather facts and communicate but cannot self-authorize financial changes.
- Safety Lead owns urgent dog/person safety matters and related restrictions.
- Founder/CEO receives/escalates only matters assigned to executive authority under approved policy.
- Transfer is complete only after the receiving owner/team accepts; until then the sending owner remains accountable.
- Every assignment/transfer/escalation records actor, from/to, reason, timestamp, scope, acknowledgement and next action.
- A conflicted or implicated owner must not adjudicate their own conduct; provide independent escalation.
- Failed acknowledgement must use a configured and tested backup route. Do not invent contact names, phone numbers or an on-call rota.

## 8. Emergency and incident integration
For immediate danger, the UI must direct staff to the approved emergency process and verified local emergency help as appropriate. Do not wait for a ticket workflow or internal approval before urgent care.

- Create or link the incident record under POL-016; do not duplicate incident truth in an ordinary support case.
- Keep case and incident references linked with controlled access.
- Preserve timestamps and facts without delaying emergency response.
- Show who has acknowledged ownership and the next action.
- Restrict dog/person health, precise location, identity and incident evidence to authorized roles.
- Do not ask the customer to attend the walk or take over the dog as a default resolution.
- Active-walk interruption must follow safe-handover requirements; a support case closure cannot mark a walk completed.
- Emergency communications must not rely solely on push notification delivery.
- Do not claim an emergency message was read because a provider reports delivery.

## 9. Refund, payment and payout disputes
- Support may intake, investigate and explain approved policy; only authorized Finance/backend workflows can approve or execute a refund/payout adjustment.
- Separate complaint received, investigation, refund decision, provider transaction and final reconciliation.
- Verify authoritative provider/backend records; screenshots are contextual evidence, not settlement proof.
- Record currency, amount, reason, approver, provider reference, idempotency key/reference and final outcome only as supplied by trusted records.
- Duplicate case events, retries or provider callbacks must not cause duplicate refunds.
- A pending/unknown provider result must remain pending/unknown until reconciled.
- Failed refunds create follow-up and remain visible to Support/Finance.
- Do not promise processing timelines or bank posting dates without approved provider-supported terms.
- Link payout disputes to POL-013 and route to Finance.

## 10. Notification Center — purpose and event model
The Notification Center is an operational delivery/health view, not a general-purpose message composer that can bypass approved templates or recipient consent.

POL-032 notification categories:
- Account/security
- Booking lifecycle
- Walker updates
- Walk progress/handover
- Safety/emergency
- Payment/package
- Support
- Optional marketing (separately consent-governed)

For each notification event, the system should retain minimum metadata:
- Unique event ID and idempotency key
- Event source and related booking/walk/case/incident/payment reference
- Template ID and version
- Category, language and approved recipient reference
- Channel
- Created/queued/sent/delivered/failed/suppressed timestamps where supported
- Provider message reference and failure code (redacted/safe)
- Retry attempt number and outcome
- Consent/preference decision where relevant
- Correlation ID and audit reference

Do not store secrets, full contact details or message payloads unnecessarily in operational logs.

## 11. Delivery states and retry controls
Keep these states distinct; final names must match Team 01/provider contract:
- Queued
- Sent / accepted by provider
- Delivered (only where provider confirms delivery)
- Failed
- Suppressed (consent, invalid destination, policy or safety rule)
- Retry scheduled
- Exhausted / dead-letter review
- Unknown / provider outcome uncertain

“Sent” is not “delivered”; “delivered” is not “read.” Do not display read/acknowledged unless a genuine acknowledgement signal exists and is defined.

Retry requirements:
- Unique event and delivery-attempt identifiers.
- Idempotent event generation and callback processing.
- Category-specific retry limits/backoff configured only after approval.
- No retry for invalid destination or suppressed consent state unless corrected/authorized.
- Manual retry must show the last provider result, reason and idempotency behavior; prevent duplicate delivery where outcome is uncertain.
- Exhausted failures create an operational follow-up/case according to approved rules.
- Preserve original failure and every retry attempt; do not overwrite history.
- A provider timeout with unknown outcome must be reconciled before sending another potentially duplicate message.

## 12. Message templates, channel fallback and preferences
- Version-controlled templates: template ID, category, language, owner, approval status, variables and revision history.
- Validate localization, variable substitution, accessibility, length and sensitive-data leakage.
- In-app status is the authoritative customer-facing view where available; opening a push must refresh current backend state.
- Push is an alert, not the authoritative source.
- SMS/email/phone only where provider configuration, legal basis, consent and monitoring are verified.
- Define channel priority, fallback, retry and escalation separately for each category.
- Emergency response must have a human/operational fallback and cannot rely only on push.
- Separate essential service/security messages from optional marketing.
- Marketing opt-out must not suppress essential transactional/safety notifications.
- Record preference/consent changes with timestamp and applicable notice version.
- Never put full address, sensitive dog/health detail, payment credentials or unnecessary personal information in lock-screen previews.
- Company-number calling/masking/call recording must not be represented as available until selected provider configuration and legal requirements are verified.

## 13. Admin actions and approval gates
Potential controls, all disabled until policy, role/scope and backend contracts are approved:
- Create case
- Assign/reassign owner
- Transfer to another team
- Escalate severity
- Request/attach evidence
- Send approved template reply
- Record internal note
- Resolve / close / reopen
- Request Finance review
- Link/create incident reference
- Retry eligible notification
- Suppress/cancel a queued notification where supported
- View delivery attempts and provider error

Every mutation must enforce trusted backend role/capability and case/geographic scope, validate current state, require reason where appropriate, be idempotent, return authoritative result and write an audit record. UI-only role checks are not security boundaries. Do not expose an unrestricted free-form broadcast or arbitrary recipient tool.

## 14. Privacy, evidence and retention
- Verify reporter proportionately before disclosing booking, location, financial or incident information.
- Mask customer/Walker contact details by default.
- Restrict precise location, dog safety/health notes, identity documents, payment references and incident evidence.
- Separate reporter-visible message from internal notes.
- Attachments need approved private storage, access control, file validation, malware scanning where supported, retention and audit.
- Do not store evidence in public URLs or personal messaging channels.
- Search, export, download and bulk actions need separate permission and purpose audit.
- Apply POL-014/POL-020 retention/deletion and legal/dispute hold rules once approved.
- Redact authentication secrets and unnecessary personal information from provider errors and logs.

## 15. Reliability, stale data and UI states
Support queue:
- Loading, no cases, stale snapshot, unavailable/error, scope denied, partial data.
- Case creation result confirmed vs unknown.
- Transfer pending vs accepted.
- Escalation sent vs acknowledged.
- Resolution decision recorded vs follow-up outstanding.

Notification Center:
- Queue loading/empty/stale/unavailable.
- Queued/sent/delivered/failed/suppressed/unknown.
- Retry eligible / retry blocked / retry outcome unknown.
- Provider outage / callback delayed / event reconciliation pending.

Do not display hard-coded sample cases or sample notifications as live data. If the source is unavailable, show unavailable state rather than synthetic examples. A network error after a mutation must trigger an authoritative refresh before retrying. Do not optimistically claim sent/delivered/resolved/closed.

## 16. Team 01 / cross-app / provider decisions required
Before implementation obtain exact branch + commit SHA and approved contract for:
1. Canonical case schema, case ID generation, state transitions and immutable history.
2. Case create/update/assign/transfer/escalate/resolve/reopen operations, idempotency and stable errors.
3. Case ownership and role/capability + City/Zone/case scope enforcement.
4. Cross-reference between POL-009 S0–S3 and POL-016 SEV-1–SEV-4.
5. Verified emergency/on-call ownership, contact routes, backup and acknowledgement semantics.
6. Incident linkage and safe-handover interface.
7. Evidence/attachment storage, access, retention and audit.
8. Refund/payout case references and Finance authority boundaries.
9. Notification event schema, event ID/idempotency, template version and recipient resolution.
10. Provider/channel list and exact semantics for queued/sent/delivered/failed/suppressed/unknown.
11. Retry/backoff/maximum attempts/dead-letter and manual retry safety.
12. Provider callback authentication, duplicate/out-of-order event handling and reconciliation.
13. Consent/preferences and essential-vs-marketing classification.
14. Search/query/pagination/index requirements and server-side scope.
15. Emulator/provider-sandbox evidence for authorized/denied roles, transfer race, escalation acknowledgement, attachment privacy, duplicate event, timeout/unknown result, retry, opt-out, emergency fallback and delivery callback.

Do not assume Firebase Functions, provider, email/SMS, push, masked calling, call recording or emergency rota exists because it appears in a policy draft.

## 17. Planned acceptance checklist — NOT EXECUTED
### Support cases
- [ ] Case receives unique server-generated ID and timestamp.
- [ ] Reporter identity is verified proportionately before private data is disclosed.
- [ ] One primary owner remains accountable until accepted transfer.
- [ ] Transfer records sender, receiver, reason, time and acknowledgement.
- [ ] Case queue/detail/search/count/export enforce backend role and scope.
- [ ] Safety/security flags override ordinary queue ordering.
- [ ] POL-009 severity and POL-016 incident severity are not silently conflated.
- [ ] Internal notes are never exposed as customer-visible messages.
- [ ] Evidence links enforce private access and retention.
- [ ] Refund/payout actions are Finance-authorized and provider-verified.
- [ ] Case cannot be closed solely because a reply was sent.
- [ ] Reopen/appeal and conflict-of-interest route preserve original history.
- [ ] Emergency action does not wait for ordinary ticket SLA or push delivery.
### Notifications
- [ ] Every event and delivery attempt has unique ID/idempotency.
- [ ] Status reflects authoritative backend state.
- [ ] Sent, delivered and read/acknowledged are distinct.
- [ ] Duplicate/out-of-order callbacks do not duplicate or regress status.
- [ ] Provider timeout/unknown outcome is reconciled before unsafe retry.
- [ ] Retry limit/backoff is configurable and approved.
- [ ] Failed/exhausted delivery creates visible follow-up.
- [ ] Invalid destination/suppressed consent is not retried blindly.
- [ ] Marketing opt-out does not suppress essential service/safety messages.
- [ ] Push open refreshes authoritative status.
- [ ] Emergency process has a tested non-push fallback.
- [ ] Sensitive information is absent from lock-screen previews and logs.
- [ ] Templates are versioned, localized, approved and validated.
### Platform and QA
- [ ] Loading, stale, unavailable, denied and ambiguous mutation states are tested.
- [ ] No hard-coded sample records are presented as live data.
- [ ] Mobile/accessibility behavior is tested.
- [ ] Exact-head CI and authorized sandbox/Emulator evidence are attached.

All checks are **PLANNED — NOT EXECUTED**.

## 18. Explicit non-decisions and guardrails
- POL-009, POL-024, POL-032 and POL-016 remain Draft/unapproved; no production SLA, channel, emergency rota or financial authority is approved here.
- No support case schema, notification schema, callable name, provider, delivery channel, retry count/backoff, severity mapping, SLA or retention period is invented/approved here.
- No new role, City/Zone scope or permission is granted.
- No real customer/Walker notification is sent by this documentation task.
- No runtime UI, API integration, Firebase Functions/Rules/schema, provider configuration, live data or production settings changed.
- No tests, Emulator, provider sandbox or CI run for this documentation-only task.
- No merge or deployment. PR #51 remains Draft and unmerged.

## 19. Status
Team 02 requirements draft based on inspected Admin UI and Draft Notion policies. Policy approval, Team 01 case/notification contracts, role/scope authorization, provider selection/configuration, verified emergency contacts, implementation and tests remain pending. Not launch-ready.

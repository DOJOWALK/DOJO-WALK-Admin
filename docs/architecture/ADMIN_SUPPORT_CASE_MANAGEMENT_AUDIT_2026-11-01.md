# Admin Support & Case Management Audit — 2026-11-01

## Scope
Read-only review on Admin branch `ui/notion-brand-foundation-2026-10-28`.

Reviewed:
- `lib/features/support/screens/support_center_screen.dart`
- `lib/screens/dashboard/admin_shell.dart`
- `test/features/support/support_center_screen_test.dart`
- Related Dashboard / Notifications audits already on this branch for cross-reference.

Searched the Admin repository for support case collections/services, complaint and dispute records, case IDs, incident IDs, escalation, resolution and assignment workflows.

No runtime code, Firebase, Firestore Rules, production data, merge or deployment changes were made. Tests and Emulator were not run.

## 1. Support Center source findings

- The Support Center source comment explicitly labels the screen a UI-only queue prototype aligned with POL-009 / POL-024.
- Its source comment says all cases are examples and no customer or incident data is loaded.
- The queue contains three hard-coded sample records: a live-walk safety concern (S0), a Walker assignment delay (S1), and a payment receipt question (S2). These are not live customer complaints or incident records.
- Search and severity filters operate on the local in-memory example list only.
- The screen has an appropriate safety/privacy warning: safety and privacy concerns override ordinary queue priority; do not promise unapproved refunds, compensation, outcomes or response times; never request passwords or authentication codes.
- Case assignment, escalation, transfer and resolution actions are explicitly disabled pending authorization, evidence storage and audit logging.
- The only active case action opens an example detail dialog, which explicitly states no live support or incident data was accessed.
- No Firestore collection stream, repository, case service, create-case form, attachment/evidence upload, case mutation or notification integration is connected in this screen.

## 2. Navigation and role / scope observations

- AdminShell exposes Support as a sidebar item and routes it to SupportCenterScreen.
- The inspected Support screen contains no role-specific or geographic-scope checks because it is currently a local prototype with no connected data/actions.
- This does not establish that any future support action is authorized. Before live access, case visibility and actions must be enforced by trusted backend/Firestore Rules using the approved role and geographic-scope model.
- Founder, Central Admin, City Manager, Zone Supervisor and Walker/customer access boundaries must be reconciled with the canonical POL-021 role matrix and Team 01's role/scope contract before implementation.

## 3. Existing tests

Support widget tests cover:
- Sample queue rendering and S0 example priority display.
- Local S1 severity filtering.
- Example-only case detail dialog.
- Narrow mobile viewport rendering.
- Transfer and Resolve controls remaining disabled.

These tests prove prototype presentation behavior only. They do not prove live case creation, evidence storage, access isolation, role/scope enforcement, case assignment, escalation, notifications, resolution, reopen, or audit atomicity. No tests were executed as part of this audit.

## 4. Missing workflow / evidence

Not found in the inspected Support Center and matched Admin repository paths:
- Live support-case collection/repository or callable integration.
- Customer or Walker complaint intake and case creation.
- Incident linkage to booking ID, walk ID, Walker/customer and service zone.
- Evidence attachment upload, private access control, retention or access audit.
- Case owner assignment, transfer, queue claiming or geographic routing.
- SLA timers, escalation acknowledgement, escalation history or overdue alerts.
- Customer/Walker response timeline and approved communication channel integration.
- Resolution reason, customer confirmation, reopen, closure and immutable case audit trail.
- Case-level refund/compensation approval integration.

These are bounded source-search findings, not proof that no such workflow exists elsewhere in the wider DOJO WALK platform or Notion policies.

## 5. Required implementation gates

1. Reconcile POL-009, POL-024, POL-016 (Incident & Emergency Management) and POL-021 (Admin roles) into one approved support/incident workflow map. Confirm policy status and owners; do not treat draft policy text as implementation approval.
2. Separate general support cases from safety incidents. S0 safety events need an immediate trusted escalation path and must preserve dog custody/safe handover; ordinary case resolution must never stop an active walk or release a dog.
3. Define canonical case and incident IDs, reporter type, subject, bookingId, walkId, zoneId, severity, status, owner, timestamps, due/escalation times, linked evidence and closure reason.
4. Define a server-owned state machine with allowed transitions, mandatory reason/evidence fields, concurrency/idempotency protection and reopen rules.
5. Define role × action × geographic-scope authorization for view, create, assign, transfer, escalate, communicate, resolve, reopen and close. Enforce on trusted backend/Rules, not only in UI.
6. Define private evidence storage: allowlisted file types/size, malware/content checks where applicable, short-lived authorized access, no public URLs, retention/deletion rules and access audit.
7. Define communication templates, language preferences, consent/opt-out for optional marketing, delivery retry and message-history linkage. Do not expose internal safety/security details unnecessarily.
8. Define SLA clocks by severity, acknowledgement ownership, escalation destinations and fallback if push/network delivery fails.
9. Add Emulator/integration tests for unauthenticated/inactive/out-of-scope access, role matrix, cross-zone isolation, S0 escalation, safe-handover invariants, evidence privacy, invalid transitions, concurrent updates, idempotent retries, reopen and audit atomicity.
10. Keep all live case mutations disabled until Team 01 confirms the data/callable contract, POL-021 role/scope approval is recorded, and Emulator evidence is attached.

## Status
- Support Center source review: COMPLETE for listed files.
- Support queue UI: PRESENT as a prototype.
- Live case data / case service: NOT CONNECTED in inspected Support screen.
- Create / assign / transfer / escalate / resolve / reopen: NOT IMPLEMENTED in inspected Support screen; mutation controls disabled.
- S0 safety sample: PRESENT as illustrative local example only; no real incident evidence.
- Role/geographic-scope enforcement for Support actions: NOT VERIFIED; no live actions are connected.
- Widget tests: PRESENT for prototype rendering and disabled controls; NOT EXECUTED by this audit.
- Emulator / evidence-storage / notification workflow: NOT RUN / NOT VERIFIED.
- Firebase/API/runtime changes, merge, deployment: NONE.
- Admin PR #51 remains Draft and unmerged.
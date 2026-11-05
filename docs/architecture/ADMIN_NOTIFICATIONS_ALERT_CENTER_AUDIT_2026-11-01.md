# Admin Notifications & Alert Center Audit — 2026-11-01

## Scope
Read-only source and test review on Admin branch `ui/notion-brand-foundation-2026-10-28`.

Reviewed:
- `lib/features/notifications/screens/notification_center_screen.dart`
- `lib/screens/dashboard/dashboard_screen.dart`
- `lib/screens/dashboard/dashboard_data_source.dart`
- `lib/screens/dashboard/admin_shell.dart`
- `test/features/notifications/notification_center_screen_test.dart`
- `test/screens/dashboard/dashboard_screen_test.dart`

Searched the Admin repository for notification delivery services, FCM/push token handling, read/unread status, acknowledgement, emergency alerts, GPS-lost alerts, and assignment-pending notifications.

This audit did not change runtime code, Firebase, Rules, production data, or deployment.

## 1. Notification Center

### Observed
- The screen's source comment explicitly labels it a UI-only notification operations prototype aligned with POL-032.
- It renders four hard-coded example records (NOTICE-EX-001 through NOTICE-EX-004); no Firestore/repository/service stream is connected.
- Search and category filters operate only on the local examples.
- Send and Retry controls are disabled. Source text says delivery channels are not connected and no notification will be sent from this screen.
- Example content includes booking created, Walker assignment confirmed, safety escalation, and optional marketing. These are illustrative records, not real event/delivery evidence.
- The screen includes useful safeguards: do not claim assignment/arrival/live location/payment/refund completion without trusted backend confirmation; delivery receipts do not prove a message was read; optional marketing requires separate consent.
- No actual send, retry, cancel, preference update, acknowledgement, read/unread mutation, delivery receipt, or notification audit-log operation is implemented in the inspected screen.
- Repository search did not identify a connected Notification Center delivery service, FCM token pipeline, or notification backend in the matched Admin paths.

## 2. Dashboard operational alerts

### Observed
Dashboard Operations Alerts contains three live count rows:
1. Unassigned bookings — bookings status aliases for Pending.
2. Payment failures — payments.status == failed.
3. Offline walkers — walkers.isOnline == false.

The dashboard data source exposes read-only count streams. Dashboard tests verify the alert rows render, and that permission/query failures are shown rather than displayed as false zero values.

### Gaps / risks
- These are aggregate counts, not individual actionable alert records.
- No alert detail navigation, acknowledgement, assignment, snooze, close, escalation, or owner assignment action is connected to the rows in the inspected code.
- Pending booking count is used as the proxy for unassigned bookings; the query is status-based and does not independently verify walkerId == null. If status and assignment drift, the count may be misleading.
- Offline Walker count uses isOnline == false; it does not distinguish a Walker who is safely off shift from one who became unreachable during an active walk.
- Payment failure count has no inspected age threshold, retry status, gateway response context, or owner/escalation workflow.
- No GPS stale/lost, active-walk tracking gap, emergency incident, notification-delivery failure, or overdue acknowledgement alert is present in the inspected Dashboard alert list.

## 3. Navigation and tests

- AdminShell exposes Notifications as a navigation destination and opens NotificationCenterScreen.
- Notification widget tests cover example rendering, safety copy, local category filtering, mobile layout, and that Send/Retry remain disabled.
- Dashboard widget tests cover alert display, loading/error states, and permission failures using an injected fake data source.
- These tests validate presentation behavior; they do not prove event creation, push delivery, retries, read/acknowledge state, alert escalation, authorization, or Firestore Rules.
- This audit did not execute the tests or an Emulator.

## 4. Required implementation gates

1. Confirm canonical event producers and schemas with Team 01/Partner/Customer: booking lifecycle, assignment, payment/refund, Walker availability, active-walk GPS freshness, incidents and safety escalation.
2. Define a durable notification/event record with event ID, entity reference, recipient, category, severity, created/updated timestamps, channel, delivery attempts, provider result, and correlation/idempotency key.
3. Separate business event state, delivery state, and read/acknowledgement state. A sent/delivered message must not imply a user read it or that the underlying business action completed.
4. Define required service messages versus optional marketing consent, opt-out, language, quiet hours, template versioning and privacy-safe message content.
5. Define role/scope rules for alert visibility and acknowledgement. Safety alerts must not be hidden by ordinary notification preferences or depend only on push delivery.
6. Define retry/backoff, provider timeout, dead-letter/manual review, duplicate suppression, rate limits, delivery receipts and immutable audit trail.
7. Replace status-only unassigned count with a server/schema-consistent query that verifies assignment state; define a time-based threshold and owner for pending assignment.
8. Define offline-vs-active-walk-unreachable semantics and GPS freshness thresholds; alert only when the Walker is expected to be active and tracking is stale.
9. Add Emulator/integration tests for event authorization, out-of-scope access, duplicate event delivery, provider failure/retry, acknowledgement idempotency, consent/opt-out, escalation timeout and audit atomicity.
10. Keep delivery and alert mutation actions disabled until trusted backend contracts, roles, policy and Emulator evidence are approved.

## Status
- Notification Center source review: COMPLETE for listed files.
- Notification Center live records/backend delivery: NOT CONNECTED in inspected screen.
- Send/Retry: DISABLED.
- Read/unread and acknowledgement workflow: NOT FOUND in inspected paths.
- Dashboard aggregate alerts: PRESENT (3 categories).
- Actionable alert lifecycle/escalation: NOT FOUND in inspected Dashboard flow.
- GPS lost/stale and emergency alert rows: NOT FOUND in inspected Dashboard flow.
- Existing widget tests: PRESENT for presentation and disabled controls; not executed by this audit.
- Emulator/provider delivery evidence: NOT RUN / NOT PROVIDED.
- Firebase/API changes, merge, deployment: NONE.
- PR #51 remains Draft; no API wiring authorized by this audit.
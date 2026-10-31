# Admin Live Operations & Emergency Management Audit — 2026-11-01

## Scope and evidence boundary
Read-only source audit on Admin branch `ui/notion-brand-foundation-2026-10-28`.

Reviewed:
- `lib/screens/live/live_operations_screen.dart`
- `lib/screens/live/live_map_widget.dart`
- `lib/screens/live/live_booking_details_helper.dart`
- `lib/screens/dashboard/dashboard_screen.dart`
- Prior Admin role-entry and feature permission audits.
- GitHub code-index searches for Live Operations, emergency, incident, GPS, walk stop/start, `walk_locations`, and `currentLocation`.

No runtime code, Firestore Rules, Firebase Functions, production data, or deployment was changed. No tests or Emulator sessions were run.

## 1. Live Walker presence

### Observed implementation
- Live screen subscribes to `walkers` where `isOnline == true`.
- It reads each Walker's `currentLocation` and creates map markers when the value is a Firestore `GeoPoint` or a map with numeric `latitude` / `longitude`.
- It displays Walker status and online/offline state, and supports selecting a Walker, retrying the listener, and viewing a linked booking summary.
- Listener errors are surfaced with a permission-denied-specific message and a retry action.

### Gaps / risks
- The query filters by `isOnline`, not by an active walk or a verified current booking state.
- The inspected marker path does not check a location timestamp/age, accuracy, or source. A stale `currentLocation` can therefore still appear as a current marker if the Walker remains online.
- UI label `LIVE` is derived from `isOnline == true`; it is not evidence that GPS updates are fresh or that a walk is in progress.
- No explicit stale-location state, last GPS update time, accuracy indicator, or tracking-loss alert was identified in the inspected screen.

## 2. Route history

### Observed implementation
- Selecting a Walker triggers a one-time read of `walk_locations` filtered by `walkerId`.
- Results are ordered by `timestamp` ascending and limited to 300 documents.
- The returned points are drawn as a map polyline; fewer than two points produce a no-route message.
- Route load errors are caught and displayed; booking details are read separately.

### Gaps / risks
- This is a one-time fetch, not a live subscription to route updates.
- With ascending order and `limit(300)`, a Walker with more than 300 records may receive the oldest 300 points, not the most recent 300. Query semantics should be deliberately chosen for a requested time range / active walk.
- Query is scoped by Walker ID only in the inspected implementation; it does not filter by a distinct `walkId` or `bookingId`. Multiple walks can therefore be mixed into one route if the collection contains multiple sessions for that Walker.
- No time window, route-session boundary, GPS freshness, accuracy threshold, or pagination control is present in this query.
- No evidence here establishes that location writes are reliable in background mode, protected by Rules, or linked to the correct active walk; those require Partner/Firebase inspection and Emulator evidence.

## 3. Booking detail privacy

### Positive control observed
- `safeLiveBookingSummary` uses an explicit allowlist of operational fields (status, IDs, zone, schedule/start/completion timestamps, duration and dog count).
- The screen explicitly tells operators that sensitive fields are omitted; it does not dump the full booking document into the dialog.

### Follow-up
- Review the allowlist against a role-based minimum-necessary policy. Customer and Walker IDs may still be sensitive and should be masked or restricted where the operational role does not need them.
- Timestamp display currently converts to device-local time in this helper; operational time policy should be consistent with the Admin's IST display convention.

## 4. Emergency / incident workflow

### Observed in inspected Admin paths
- No incident list, incident creation form, severity selector, escalation action, emergency stop/suspend action, safe-handover workflow, or emergency notification control was identified in the inspected Live Operations screen or matched Admin code-search results.
- Live Operations is a monitoring/map screen with Walker and booking read actions; no lifecycle mutation or emergency callable is invoked from this screen.

### Not established
- This bounded Admin source audit does not prove that incident or emergency handling is absent from all repositories, external systems, phone procedures, or Notion policy pages.
- The existence of a separate incident policy is not proof of an implemented Admin workflow, configured notifications, or tested escalation.
- Do not add a direct client-side emergency status write. Any emergency suspend/stop must use the approved trusted backend operation and preserve dog-custody/handover rules.

## 5. Required acceptance gates

1. Confirm the canonical active-walk identity and location schema across Partner, Firebase and Admin (booking ID, walk ID, Walker ID, timestamp, accuracy, sequence/session).
2. Require location freshness thresholds and visible states such as fresh, delayed, stale, tracking unavailable; do not label `isOnline` alone as LIVE GPS.
3. Query route points by active `walkId` (or another approved session key), bounded by walk start/end; define latest-point behavior, pagination and retention.
4. Verify background GPS capture, offline buffering/replay, duplicate/out-of-order points, app termination, permissions, battery constraints and server timestamps in Partner/Firebase tests.
5. Enforce least-privilege read access to live location and route history by Admin role and geographic assignment; test denied roles and out-of-scope zones in Emulator.
6. Define incident severity, evidence capture, escalation recipients, acknowledgement timeout, notification retry and immutable audit history.
7. For emergency action, define who can initiate, which trusted callable is used, idempotency, reason/severity fields, immediate suspension behavior, dog handover confirmation, customer/Walker notifications and Founder/Central Admin escalation.
8. Add Emulator and integration tests for stale GPS, missing GPS, unauthorized location reads, cross-zone access, wrong walk/session linkage, emergency duplicate requests, failed notifications and safe-handover-before-stop.
9. Keep the Admin UI read-only until Team 01 confirms the exact callable/role contract and Notion policy is aligned.

## Status
- Live Operations source inspection: COMPLETE for listed files.
- Online Walker map markers: PRESENT.
- Freshness/accuracy indicators: NOT FOUND in inspected screen.
- Route history: PRESENT as one-time fetch; not a continuous route stream.
- Route session filtering / pagination: NOT FOUND in inspected query.
- Safe booking summary allowlist: PRESENT.
- Admin incident/emergency workflow: NOT FOUND in inspected paths; organization-wide absence is NOT established.
- Tests executed by this audit: NO.
- Emulator / background GPS / notification evidence: NOT RUN / NOT PROVIDED.
- Firebase/API changes, merge, deployment: NONE.
- PR #51 remains Draft; no API wiring is authorized by this audit.

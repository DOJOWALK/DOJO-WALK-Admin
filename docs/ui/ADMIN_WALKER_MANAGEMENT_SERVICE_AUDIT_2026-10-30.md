# DOJO WALK Admin — Walker Management Service Deep Audit

- Audit date: 2026-10-30
- Admin repository: `DOJOWALK/DOJO-WALK-Admin`
- Admin branch reviewed: `ui/notion-brand-foundation-2026-10-28`
- Firebase rules repository reviewed: `DOJOWALK/DOJO-WALK-Firebase` default branch snapshot
- Scope: source-level review of walker service, model/helpers and current Firestore rules. No production data, emulator execution, merge, or deployment.

## 1. Service behavior confirmed

- `watchWalkers()` subscribes to the entire `walkers` collection and maps every document into a `WalkerAdminModel`.
- `watchBookings()` subscribes to the entire `bookings` collection; the dashboard derives running walker IDs client-side.
- `watchWalkerBookings(walkerId)` filters only by `walkerId`; it has no status/date filter or limit.
- `watchWalkerAuditLogs(walkerId)` filters by `targetType == walker` and `targetId == walkerId`, applies a clamped limit (1–200), then sorts the returned subset locally by `createdAt`.
- `watchWalker(uid)` and `getWalker(uid)` read one walker document.
- `runAdminAction()` checks the signed-in user's `admin_users/{uid}` record and currently accepts only `role == super_admin` plus `isActive == true`.
- The action and audit record are written in one Firestore transaction. The service validates current status and required reasons before writing.
- Supported transitions are approve, reject, suspend, reactivate and request correction.
- Model maps legacy aliases such as `name/fullName/displayName`, phone fields, area/locality and state/stateName; raw profile and KYC maps are retained for detail views.

## 2. Confirmed risks and required decisions

| Priority | Finding | Impact / required follow-up |
|---|---|---|
| P0 | Walker and booking streams read entire collections. | Read cost and data exposure scale with national growth. Replace with approved paginated/filtered query contracts and server-enforced city/zone scope before broad rollout. |
| P0 | Client service has no city/zone scope parameters. | UI tabs/search are not authorization. Confirm canonical walker zone/city fields and manager/supervisor visibility contract; enforce in trusted backend/rules, not client-only filters. |
| P0 | Client-side transaction checks only `super_admin`. | This does not implement the agreed Founder → Central → City Manager → Zone Supervisor hierarchy. Keep lifecycle controls disabled until POL-004 defines action-level authority and the backend/rules enforce it. |
| P1 | Audit query limits before local sorting and has no `orderBy(createdAt)`. | It can return an arbitrary subset rather than the newest 50 records. Add a deterministic descending timestamp query with an appropriate composite index and stable tie-breaker, after checking index ownership. |
| P1 | Walker booking stream has no status/date constraint or limit. | A walker with long history can cause growing reads; the dashboard's separate all-bookings stream is even broader. Define whether running detection should query only active statuses and use a bounded/maintained assignment index. |
| P1 | Running detection currently recognizes only `in_progress`, `active_walk`, `walking`, `walk_started` in the UI adapter. | Status drift or a canonical status change can misclassify walkers. Reconcile with the booking lifecycle contract and shared canonical status helper before adding aliases. |
| P1 | `runAdminAction` is client-callable and trusts a client-side transition implementation. | Transactions prevent partial writes but do not replace trusted authorization/business validation. Verify the exact deployed Firestore update rules and consider callable/server-side decisions with immutable audit creation. |
| P1 | Service writes `decisionBy`, `decisionAt`, `decisionReason`, and audit actorRole as hard-coded `super_admin`. | This is incompatible with future action-level roles and may overwrite decision metadata; align field names and actor role with POL-004 and audit schema. |
| P2 | `watchWalkerAuditLogs` treats missing/invalid timestamps as oldest only after fetching. | Missing timestamps remain possible and sorting is not deterministic for ties. Validate audit schema and timestamp requirements. |
| P2 | `watchWalkerBookings` has no dedicated service tests in the inspected tree. | Add fake/emulator tests for query constraints, errors, status transitions, transaction atomicity and audit payloads. |
| P2 | Model stores full raw data and KYC map in memory. | Keep sensitive KYC access least-privilege; avoid logging raw model/maps and verify Storage rules independently. |

## 3. Firestore rules cross-check (Firebase repository snapshot)

- The inspected rules define `isAdmin()` as an active `admin_users` document with role exactly `super_admin`.
- `walkers` collection listing is restricted to `isAdmin()`; therefore the Admin full-collection walker stream depends on Super Admin access in the inspected rules.
- The rules contain explicit walker status/verification validation and separate owner update paths. The admin service's lifecycle transaction must be checked against the exact walker `allow update` clauses and current deployed rules before any action is enabled.
- The rules reviewed are a repository snapshot, not proof of what is deployed to Firebase. No production rules state was queried.
- No zone/city manager read-scope implementation was established by this source review.

## 4. Safe implementation direction

1. Keep all lifecycle actions disabled in the UI; do not loosen the `super_admin` check or add manager roles speculatively.
2. Treat this as a cross-repository contract task: Notion POL-004/POL-026 → Admin service → Firebase rules/functions → emulator tests.
3. Agree the canonical fields for `cityId`, `zoneId`, active booking status, and audit actor role before changing queries.
4. Introduce bounded query APIs only after those fields and indexes are confirmed. Avoid silently filtering by display names such as city/area.
5. Add service tests using injected Firestore/Auth or emulator fixtures; include denied-role, inactive-admin, missing-walker, invalid transition, required reason, transaction/audit atomicity and query-bound cases.
6. Run targeted tests, full Flutter tests, analyze, web build and Firebase rules emulator tests on exact resulting commits.

## 5. Validation status

- Admin service/model/helper source review: DONE.
- Firebase rules source cross-check: PARTIAL; repository snapshot only, exact deployed rules and full transition-rule compatibility not verified.
- Service-level tests: NOT FOUND in inspected Admin test tree.
- Flutter Analyze / Flutter Test: NOT RUN.
- Firestore emulator/rules tests: NOT RUN.
- Production Firebase read/rules verification: NOT performed.
- Merge/deployment: NOT performed.

This report records source-level findings only. It does not claim runtime tests, security approval, or production readiness.

## 6. Lifecycle policy test seam added — 2026-10-30

- Extracted deterministic state-transition validation into `lib/features/walkers/services/walker_admin_transition_policy.dart`.
- Moved the shared action enum and safe service exception into `walker_admin_contracts.dart` to avoid a circular import.
- `WalkerAdminService` delegates its existing transition validation to the pure policy; this is a structural refactor intended to preserve the existing transition rules.
- Added `test/features/walkers/walker_admin_transition_policy_test.dart` covering approval, rejection, suspension, reactivation, correction requests and terminal-state guards.
- These are authored tests, not executed test results. No Firestore/Auth transaction, audit write, query shape, rules emulator or role authorization is tested by this pure policy suite.
- Exact-head CI has not yet appeared. Flutter Analyze/Test remain unverified.

## 7. Additional pure-policy coverage — 2026-10-30

- Centralized the "reason required" rule for Reject, Suspend and Request Correction in `WalkerAdminTransitionPolicy.requiresReason`.
- Centralized stable audit event names for all five lifecycle actions in `WalkerAdminTransitionPolicy.auditActionName`.
- Updated `WalkerAdminService` to consume these shared policy methods and removed unused transition method parameters.
- Added tests for exact reason-required action set and audit event mapping.
- This still does **not** test Firestore transaction atomicity, Firebase Auth state, admin role authorization, rules enforcement or audit persistence. Those require emulator-backed service tests and are not claimed complete.
- Exact PR head checked: `465d48df0bab5da602205fb1ba8e5ec4d09af25d`.
- PR #51 remains open and draft; latest queried workflow run list was empty. GitHub reported mergeable=false at the time of the check; conflict/status details need a fresh PR review before merge.

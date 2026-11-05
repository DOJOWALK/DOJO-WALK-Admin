# DOJO WALK Admin — Full Navigation & Feature Coverage Gap Audit
Date: 2026-11-01
Team: 02 — Admin App
Repository: `DOJOWALK/DOJO-WALK-Admin`
Branch inspected: `ui/notion-brand-foundation-2026-10-28`
PR: #51 (Draft; unmerged)

## 1. Scope and method
Read-only source inspection of the AdminShell navigation and the screens/services/tests already identified in the Team 02 audit series. This report consolidates those bounded inspections and adds the Customers and Pets screens. It is not a production, security-rules, backend-parity, or Emulator certification.

No runtime code, Firebase project, Firestore schema/rules/functions, production data, API wiring, merge, or deployment was changed. No tests were executed for this audit. Test statements below distinguish existing test coverage from execution evidence.

## 2. Navigation inventory
The current `AdminShell` defines 13 sidebar destinations. Live Operations is a separate route launched from Dashboard, not a fourteenth sidebar item.

| # | Sidebar destination | Screen / source | Data and actions observed | Coverage status |
|---:|---|---|---|---|
| 1 | Dashboard | `DashboardScreen`, `DashboardDataSource` | Connected Firestore aggregate streams; recent bookings/activity. Paid-payment total is gross all-time paid amount, not net revenue. Three alert-like counts are aggregate proxies, not actionable cases. | **Connected, limited read-only** |
| 2 | Bookings | `BookingsScreen`, `FirestoreBookingsDataSource` | Live `bookings` snapshot read; search/status filtering and detail display. No assignment, cancellation decision, refund, or lifecycle mutation in inspected screen/data-source interface. | **Connected, read-only** |
| 3 | Walker Management | `WalkerManagementDashboardScreen`, `WalkerAdminService` | Live Walker and running-booking streams. Walker status mutation transaction checks active Admin and exact `super_admin` role and writes audit record atomically in inspected service. No complete role/scope matrix or equivalent service-level authorization test established. | **Partially connected; privileged mutation exists, authorization/test gaps** |
| 4 | Customers | `CustomerManagementScreen` | Three hard-coded `CUS-EX` records; local search/status filter. Screen labels itself UI-only; no live customer records or connected mutation. | **Prototype only** |
| 5 | Pets | `PetManagementScreen` | Three hard-coded `DOG-EX` records; local search/filter. Screen says no live pet, health, or customer records are loaded. | **Prototype only** |
| 6 | Notifications | `NotificationCenterScreen` | Four hard-coded examples; local filters. Send/Retry disabled; no delivery, acknowledgement, read/unread, receipt, or preference workflow found. | **Prototype only** |
| 7 | Support | `SupportCenterScreen` | Three example cases; local severity/search filters. Transfer/Resolve disabled; no live case intake, evidence, assignment, escalation, or closure flow found. | **Prototype only** |
| 8 | Admin Users & Roles | `AdminAccessControlScreen` | Static POL-021 role/scope matrix preview. Role grants, scope changes, disable/revoke and MFA actions disabled. POL-021 remains Draft in inspected context. | **Prototype / policy blocked** |
| 9 | Audit Logs | `AdminAuditLogsScreen` | Four hard-coded examples; local filters; export disabled. No live stream in inspected screen. | **Prototype only** |
| 10 | Reports & Analytics | `ReportsAnalyticsScreen` | Six policy-mapped report catalogue cards; all Not connected; period chips are local state; Open/Export disabled. | **Catalogue only** |
| 11 | Finance Operations | `FinanceOperationsScreen` | Hard-coded payment/refund/payout/reconciliation examples; no gateway/provider or settlement connection; actions disabled. | **Prototype only** |
| 12 | Settings | `SettingsGovernanceScreen` | Policy-mapped settings preview; no settings persistence/configuration service; language, security, notification and privacy controls not configured/disabled. | **Preview only** |
| 13 | Service Locations | `ServiceLocationScreen` and child Zone screens | Existing hierarchy/import services and reads coexist with Zone workflow UI. Zone selectors/example data and boundary preview are not an end-to-end upload/approval lifecycle; Save Draft/Submit remain disabled in Add Zone flow. | **Mixed: existing data/import capability + incomplete Zone workflow** |

### Separate route — Live Operations
Dashboard opens `LiveOperationsScreen`. It subscribes to online Walker records and reads `currentLocation`; its LIVE indicator means `isOnline == true`, not fresh GPS or an active walk. Route history is a one-time read filtered by Walker ID, ascending, limited to 300, without walk-session/time-window isolation. No Admin incident intake/escalation/safe-handover action was found in the inspected paths.

## 3. Cross-cutting readiness
- **Navigation:** All 13 listed sidebar entries resolve to a concrete screen. Live Operations is reachable from Dashboard. The shell also supports mobile drawer and collapsed desktop navigation.
- **Authentication:** AuthGate/AuthService check active Admin membership (document exists and `isActive == true`). The inspected entry points do not independently enforce role, geographic scope, MFA, or session expiry. The shell is not an authorization boundary.
- **Role and geographic scope:** POL-021 remains Draft in inspected context. Team 01 D01–D05 Zone API/role decision request has been posted to PR #51; no authoritative Team 01 response/evidence was present in the latest PR discussion read. Do not infer that a global role check enforces city/zone scope.
- **Zone lifecycle:** Source inspection found a callable-shaped service but the screen is not connected. Firebase source audit found role mismatch risk (`central_admin` vs current `super_admin`), no inspected boundary-create/upload callable, and no demonstrated Manager/Supervisor geographic scope enforcement. Team 01 decision request remains a blocking dependency.
- **Test evidence:** Earlier audits identified widget/unit tests for Dashboard, Bookings helpers, Walker transition policy, Zone UI/import failure, Notifications, Support, Reports, Finance, Access Control, Audit Logs and Settings. The current bounded search did not identify dedicated Customer/Pet screen tests or a clear AdminShell navigation test. This is not a repository-wide proof that none exist. Earlier audits did not execute their tests.
- **Current CI evidence:** Workflow Run #439 (`41239066976`) for commit `7b0a187cd9fa5d23f95b0ce3280e63e14a1a8c37` completed successfully. Its single job completed Static Analysis, the complete Admin test suite, and Flutter Web build. This is valid CI evidence for that commit only; it does not execute tests for this new documentation commit or certify runtime integrations/security.
- **Coupons:** The current inspected AdminShell on this branch contains no Coupons sidebar entry, import, or route. The no-coupon decision is therefore reflected in the current navigation. A GitHub code-search result against the repository's indexed default-branch snapshot surfaced legacy coupon files/references; because that index is not the inspected branch head, this audit does not claim those legacy files have been removed from all refs. Keep coupons out of current Admin navigation and do not implement coupon management.

## 4. Prior audit evidence (detailed reports)
- [Zone UI ↔ Callable Contract Audit](ADMIN_ZONE_UI_CALLABLE_CONTRACT_AUDIT_2026-11-01.md)
- [Firebase Zone API Role/Response Cross-check](ADMIN_FIREBASE_ZONE_API_ROLE_RESPONSE_CROSSCHECK_2026-11-01.md)
- [Team 01 Zone API Contract Decision Request](TEAM_01_ZONE_API_CONTRACT_DECISION_REQUEST_2026-11-01.md)
- [Admin Role Entry & Role Matrix Source Audit](ADMIN_ROLE_ENTRY_AND_ROLE_MATRIX_SOURCE_AUDIT_2026-11-01.md)
- [Feature Permission & Test Coverage Audit](ADMIN_FEATURE_PERMISSION_AND_TEST_COVERAGE_AUDIT_2026-11-01.md)
- [Booking, Finance & Refund Workflow Audit](ADMIN_BOOKING_FINANCE_REFUND_WORKFLOW_AUDIT_2026-11-01.md)
- [Live Operations & Emergency Management Audit](ADMIN_LIVE_OPERATIONS_EMERGENCY_MANAGEMENT_AUDIT_2026-11-01.md)
- [Notifications & Alert Center Audit](ADMIN_NOTIFICATIONS_ALERT_CENTER_AUDIT_2026-11-01.md)
- [Support & Case Management Audit](ADMIN_SUPPORT_CASE_MANAGEMENT_AUDIT_2026-11-01.md)
- [Reports & Analytics Audit](ADMIN_REPORTS_ANALYTICS_AUDIT_2026-11-01.md)
- [Settings & Governance Audit](ADMIN_SETTINGS_GOVERNANCE_AUDIT_2026-11-01.md)

## 5. Prioritized next work (no API integration yet)
1. **P0 — Governance contract:** Obtain Team 01 written D01–D05 answers with source commit, callable/storage contracts and Emulator allow/deny evidence; finalize POL-021 role/scope policy. Do not enable privileged UI actions before this.
2. **P0 — Safety-critical Admin visibility:** Define incident/case intake, severity ownership, escalation, safe handover, GPS freshness/session model, and notification delivery/acknowledgement contracts. Keep direct client emergency writes prohibited.
3. **P1 — Complete Zone UI contract:** Define approved boundary upload source and revision/hash flow; normalize callable errors into stable UI states; add role/scope-gated actions only after Team 01 confirms contracts.
4. **P1 — Customer/Pet operational requirements:** Replace examples only after approved data access, consent/privacy rules, and scoped read/update contracts exist; add dedicated tests.
5. **P1 — Booking/Finance workflows:** Define authoritative assignment writer, cancellation state machine, refund approvals and provider idempotency/reconciliation before adding mutation controls.
6. **P2 — Reporting, audit and settings:** Connect only to approved, access-scoped sources; define retention/export, settings ownership, localization persistence and MFA/session requirements.
7. **P2 — Regression gates:** Add explicit navigation coverage and feature authorization tests, then Emulator tests for role × scope × action and atomic audit behavior.

## 6. Release posture
**Admin is not production-ready as a complete operational console.** The shell and several read surfaces exist; several core operational modules remain honest prototypes or partial read-only surfaces. The Walker mutation path and selected hierarchy/import code are real implementation surfaces but need broader authorization and integration evidence. Keep PR #51 Draft and unmerged. Continue to defer API wiring until all app/backend contracts are approved, per project direction.

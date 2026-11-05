# Admin Reports & Analytics Audit — 2026-11-01

## Scope
Read-only review on Admin branch `ui/notion-brand-foundation-2026-10-28`.

Reviewed:
- `lib/features/reports/screens/reports_analytics_screen.dart`
- `test/features/reports/reports_analytics_screen_test.dart`
- `lib/screens/dashboard/dashboard_screen.dart`
- `lib/screens/dashboard/dashboard_data_source.dart`
- `test/screens/dashboard/dashboard_screen_test.dart`
- `lib/features/finance/screens/finance_operations_screen.dart`
- `test/features/finance/finance_operations_screen_test.dart`
- `lib/screens/dashboard/admin_shell.dart` navigation mapping.

No runtime code, Firebase, Rules, production data, merge or deployment changes were made. Tests and Emulator were not run as part of this audit.

## 1. Reports & Analytics screen

- AdminShell exposes Reports & Analytics and routes it to `ReportsAnalyticsScreen`.
- The screen source explicitly describes itself as a UI-only report catalog; it intentionally does not query data or fabricate KPI values.
- Six policy-mapped report catalogue entries are displayed: Booking lifecycle, Walker performance, Zone readiness, Safety & incidents, Payments & refunds, Support resolution.
- Every report card shows `Not connected`; Open report and Export controls are disabled.
- Reporting period chips show Last 7 days, Last 30 days and Custom range. The selected value is only local widget state. It is not passed to a query, report service or data source.
- Custom range is not a date picker; there are no start/end dates, timezone boundary rules or inclusive/exclusive range semantics.
- No chart series, report detail page, generated dataset, CSV/PDF export, scheduled report, refresh operation, saved filter, pagination or report history is connected in the inspected screen.
- The six policy references are labels in the catalog; this UI alone does not establish that the policies are approved or that the metric definitions are finalized.

## 2. Dashboard metrics — separate from Reports

The Dashboard is connected to Firestore read streams, but its metrics are limited and should not be mistaken for a full reporting system:
- Total Bookings, Customers and Walkers use collection snapshot counts.
- Paid Payments (All Time) sums numeric `amount` values from `payments` documents where `status == paid`.
- The Dashboard UI explicitly labels this as gross paid amount and states refunds and fees are not deducted.
- Live Overview and Operations Alerts show status/boolean counts, including Pending bookings and `isOnline` Walker count.
- Recent Bookings reads the latest eight booking documents by `createdAt`; System Activity reads the latest six `audit_logs` documents by `createdAt`.
- These streams do not implement selectable date windows, historical grouping, period-over-period comparisons or downloadable reports.
- The gross paid aggregate does not establish net revenue, gateway settlement, refunds, chargebacks, fees, taxes, walker payable/payout, company margin or reconciled cash position.
- Amount currency/unit consistency, duplicate-payment protection and settlement linkage are not proven by this Dashboard query.

## 3. Finance Operations relationship

- Finance Operations is also explicitly a UI-only prototype; example amounts/statuses are not transactions and no gateway, bank settlement, refund API or payout provider is connected.
- Payments, Refunds, Walker payouts and Reconciliation tabs switch among hard-coded examples.
- Verify, Approve and Reconcile controls remain disabled.
- Therefore finance example cards cannot be used as report data or evidence of actual payout/refund reconciliation.

## 4. Existing tests

Reports widget tests cover:
- The six policy-mapped catalogue entries render without fabricated KPIs.
- Not connected / Export disabled labels render.
- Last 30 days selection changes the selected chip state.
- Narrow mobile viewport rendering.

Dashboard widget tests cover injected data-source rendering, gross paid amount label, loading/empty/error/permission states, refresh resubscription and responsive layouts.

Finance widget tests cover the example-only finance prototype, disabled mutation controls, tab switching and mobile layout.

These are presentation and injected-stream tests. They do not establish report query correctness, date-range filtering, financial reconciliation, export file integrity, role/scope authorization, or scheduled report delivery. This audit did not execute tests or Emulator.

## 5. Required implementation gates

1. Approve a metric dictionary for each report: business definition, source collection/event, status inclusion/exclusion, currency/minor-unit handling, timezone, deduplication key, null handling and owner.
2. Define date range semantics in IST for customer-facing operations, with explicit start/end instants, daylight/timezone conversion, inclusive/exclusive boundaries and maximum query window.
3. Separate operational counts from financial ledger metrics. Reconcile payment intents, provider confirmations, refunds, reversals, fees, taxes, settlement batches and Walker payouts before publishing revenue or margin.
4. Define booking lifecycle cohorts and event-time versus current-state reporting; avoid deriving historical assignment/completion counts from mutable current status alone.
5. Define Walker performance measures from verified completed walk records, quality review and policy-approved eligibility; do not expose personal or customer data beyond role need.
6. Define zone readiness from approved boundary revision/hash, Founder approval, activation and capacity evidence; do not infer readiness from a draft UI record.
7. Define safety/support reports with privacy minimization, severity taxonomy, safe-handover and access restrictions; aggregate where individual details are not required.
8. Define report role × geographic scope: Founder/CEO national oversight, Central Admin approved central scope, City Manager city scope, Zone Supervisor assigned zone scope. Enforce scope in trusted queries/backend, not only client filters.
9. For exports, define allowed columns, redaction, row limits, asynchronous generation, short-lived authorized download, watermark/audit record, retention and deletion; prevent public or guessable file URLs.
10. Add deterministic tests for time boundaries, status mapping, duplicate events, refund/reversal treatment, currency precision, out-of-scope access, large datasets, export contents, failed export retry and immutable export audit.
11. Keep report Open/Export and scheduled delivery disabled until Team 01 source contracts, role/scope approval and Emulator evidence are recorded.

## Status
- Reports screen source review: COMPLETE for listed files.
- Report catalog: PRESENT (6 policy-labelled entries).
- Live report data / charts / report detail: NOT CONNECTED in inspected screen.
- Period chips: PRESENT as local selection only; no query filtering.
- Custom date picker: NOT PRESENT.
- Export / scheduled reports / refresh: DISABLED or NOT CONNECTED.
- Dashboard live aggregate metrics: PRESENT, but limited to all-time gross paid amount and current counts/recent lists.
- Finance Operations live provider data: NOT CONNECTED in inspected screen.
- Widget tests: PRESENT for UI and injected data-source behavior; NOT EXECUTED by this audit.
- Emulator / financial reconciliation / export evidence: NOT RUN / NOT PROVIDED.
- Runtime/Firebase/API changes, merge, deployment: NONE.
- Admin PR #51 remains Draft and unmerged.
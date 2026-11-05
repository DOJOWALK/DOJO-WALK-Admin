# Admin Reports & Analytics — Implementation Requirements (Draft)

**Task:** ADM-P2-01
**Date:** 2026-11-01
**Status:** DRAFT — requirements only; policies and financial blueprint remain unapproved where noted. Not implemented, not tested.
**Repository:** DOJOWALK/DOJO-WALK-Admin
**Branch:** ui/notion-brand-foundation-2026-10-28
**PR:** #51 — Draft, unmerged

## 1. Purpose and implementation boundary

Define the requirements for turning the Admin Reports & Analytics catalog into trustworthy, role-scoped reporting. This document does not authorize financial calculations, new Firestore collections, report exports, scheduled jobs, or API integration.

Team 02 is documenting the Admin experience and its acceptance requirements. Team 01 owns backend data contracts, trusted aggregation, authorization enforcement, and provider reconciliation. Integration remains deferred until the cross-team API contracts and required business policies are approved.

## 2. Evidence reviewed

Notion source documents reviewed:

- **FIN-001 — DOJO WALK Master Financial Blueprint & Developer Specification:** consolidated draft; explicitly not Founder-approved, not CA/legal-cleared, not implemented, and not tested. Proposed values and illustrative scenarios are not production metrics.
- **POL-012 — Payment, Refund & Reconciliation Policy:** Draft; describes trusted payment verification, distinct refund states, provider/company settlement reconciliation, exception reporting, and audit controls.
- **POL-013 — Walker Earnings & Payout Policy:** Draft; explicitly says no earnings rate, payout schedule, minimum payout, or payout method is approved by that draft.
- **POL-033 — Walker Earnings, Payouts, Adjustments & Financial Reconciliation Policy:** Draft; backend ledger is authoritative; payout and reconciliation evidence must be independently verified.
- **POL-014 — Privacy & Data Access Policy:** Draft; least privilege, role/geographic scope, privacy-safe reporting and restricted exports.
- **POL-020 — Data Privacy, Retention & Deletion Policy:** Draft; retention periods must not be invented; data-specific retention schedule and deletion controls require approval.

Existing Admin source audit (2026-11-01):

- Reports catalog contains six report entries marked “Not connected”.
- Period chips are local UI state only; no report query/service/data source was found in the inspected path.
- Custom range is not a functioning date picker.
- No report detail/dataset, chart, CSV/PDF export, scheduled report, refresh workflow, or report history was found in the inspected implementation.
- Finance Operations is a UI-only prototype.
- Dashboard Paid Payments is a gross paid-payment total, not net revenue, company settlement, profit, or walker payout.

These findings are bounded to the inspected Admin source paths and are not proof that no corresponding backend capability exists elsewhere.

## 3. Core reporting principles

1. Every metric must have an approved definition, owner, source of truth, currency/unit, time basis, inclusion/exclusion rules, and reconciliation method before implementation.
2. Backend-authoritative records and trusted aggregation are required for financial reports. The Admin client must not calculate or decide financial truth from incomplete client-side collections.
3. Distinguish event time, service time, payment time, settlement time, refund time, earning time, and payout time. A report must state which date basis it uses.
4. Show reporting period, timezone, generated-at time, data freshness, filters, and any known data limitations.
5. Separate gross customer payments, verified receipts, provider settlement, refunds, chargebacks, adjustments, Walker payable, payout execution, contribution, and operating result.
6. Never label an estimate, weighted scenario, prepaid allocation, or gross collection as audited revenue or net profit.
7. Preserve historical figures and source references. Corrections must be auditable; a report refresh must not silently rewrite finalized ledger history.
8. A report must fail visibly when required data is unavailable, incomplete, stale, unauthorized, or unreconciled. Do not silently substitute zero.
9. Apply role and geographic scope on the trusted backend for every report query and export. Hiding a menu item is not authorization.
10. Minimize personal data. Default reports should use aggregate or pseudonymous data unless a defined operational need authorizes record-level detail.

## 4. Report catalog — proposed scope, not an approved metric catalogue

The existing six catalog entries should be reviewed against these report families. Exact names and metrics must be finalized with Finance/Operations and the relevant policy owners.

| Report family | Intended questions | Critical distinctions / prerequisites |
|---|---|---|
| Booking & Service Operations | Bookings by lifecycle, completion, cancellation, reschedule, no-show, service volume | Booking, walk, assignment and payment are separate entities/states; definitions and date basis required |
| Walker Operations & Performance | Active/available workforce, assigned/completed walks, attendance/shift and service quality | Approved lifecycle and performance definitions; city/zone scope; avoid punitive conclusions from GPS/network gaps alone |
| Customer & Pet Service Insights | Customer cohorts, repeat usage, service demand and booking patterns | Aggregate by default; privacy and purpose limitation; no unnecessary pet/customer identity in exports |
| Payments & Collections | Amount due, payment attempts, verified receipts, failed/disputed payments | PAID_VERIFIED only from trusted provider confirmation or authorized reconciliation; distinguish amount due from amount received |
| Refunds & Disputes | Requested, approved, pending, completed, failed and disputed refunds | Request/approval/provider completion/reconciliation are distinct; do not label request as refunded |
| Walker Earnings & Payouts | Eligible earnings, approved adjustments, payout batches, paid/failed/on-hold amounts | Approved effective-dated rate card; separate payable from payout initiated and payout paid-verified |
| Settlement & Reconciliation | Provider transactions versus provider settlement and company bank receipts | Reconciliation period, provider statement, settlement reference, fee/adjustment treatment, exception ownership |
| Company Financial Summary | Approved revenue/expense/contribution/operating result measures | FIN-001 and CA-approved accounting definitions required; do not derive profit from gross payments |
| Safety, Support & Quality | Incidents, case volumes, resolution states, audit/quality trends | Severity taxonomies remain distinct; restrict incident evidence and personal data |

This table is a candidate coverage model, not confirmation that all nine reports are currently in the six-item catalog or that any report is approved for launch.

## 5. Metric dictionary gate

Before a metric is built, record the following fields in an approved metric dictionary:

- Metric ID and display name.
- Business definition and intended decision/use.
- Formula, numerator, denominator, rounding and null/zero behavior.
- Included and excluded statuses/events.
- Authoritative source record(s) and backend owner.
- Event timestamp/date basis and timezone.
- Currency and minor-unit precision, where monetary.
- Aggregation grain (transaction, booking, walk, walker, customer, city, zone, day, month).
- Deduplication and idempotency rules.
- Treatment of refunds, reversals, chargebacks, adjustments and late-arriving events.
- Geographic and role scope.
- Refresh/finality expectations, once approved.
- Reconciliation evidence and exception handling.
- Data classification, masking and export permission.
- Approver, effective date, version and change history.

No metric should be implemented from a label alone. If any required definition is unresolved, show it as “Definition pending” in the specification and keep it out of production totals.

## 6. Financial terminology and separation

The following are separate measures and must not be combined or renamed interchangeably:

- **Amount due:** customer liability recorded for an order/booking under approved terms.
- **Payment attempt:** an initiated attempt; not proof of receipt.
- **Verified customer receipt:** amount confirmed through trusted provider verification or authorized reconciliation.
- **Provider settlement:** amount reported/confirmed as settled by the provider, net of the provider's applicable treatment.
- **Company bank receipt:** amount evidenced in the company-controlled settlement account.
- **Refund requested / approved / provider-pending / refunded-verified:** separate lifecycle stages.
- **Chargeback / reversal / adjustment:** separate events linked to the original transaction.
- **Walker gross earning / approved adjustment / net payable:** separate ledger components.
- **Payout processing / paid-verified / failed / on-hold:** distinct payout states.
- **Recognized revenue, contribution and operating result:** only after approved accounting definitions and CA review.

FIN-001 explicitly warns that prepaid package allocation across walk equivalents is not necessarily accounting revenue recognized in that month. Weighted unit-economics scenarios are planning estimates, not statutory P&L. Do not display them as live financial reporting.

## 7. Filters and report interaction requirements

Potential filter controls, subject to approval and data availability:

- Reporting period: preset periods plus a real start/end date picker.
- Date basis: explicit selector only where the metric supports multiple date bases.
- State/UT, district, city and zone, limited to the user's authorized scope.
- Service/booking type and lifecycle status.
- Walker/Partner identifier only for roles and purposes authorized to see it.
- Payment provider and transaction status, where supported.
- Currency, where multiple currencies are actually supported.

Requirements:

- Display the active filters and selected timezone in the report header.
- Validate start/end dates and prevent an inverted or unsupported range.
- Changing a filter must visibly reload or recompute the report; local chip selection alone is not a completed report.
- Provide loading, empty, partial-data, stale-data, access-denied and query-failed states.
- Show “No records” only when the query succeeded and returned zero qualifying records. Show “Data unavailable” for a failed query.
- Do not imply real-time refresh unless the backend contract and freshness guarantee support it.

## 8. Charts, tables and drill-down

- Choose chart type only after the metric grain and comparison meaning are approved.
- Every chart must have a title, units, date basis, legend where needed, accessible text/table equivalent, and clear empty/error state.
- Tables must expose the underlying metric definition and relevant record identifiers to authorized users.
- Drill-down must preserve the parent report's period and filters and must re-check authorization for every row/detail.
- Avoid exposing customer phone, exact address, pet health/safety notes, precise GPS history, payment credentials, or payout destination details in aggregate reports.
- Do not infer causation or rank workers as unsafe/poor performers from incomplete operational signals.

## 9. Export, scheduling and report history — gated, not enabled

No export or scheduling feature is currently evidenced in the inspected Admin report catalog. These are future requirements only.

Before CSV/PDF or other export is implemented, approve:

- Allowed report families, roles and geographic scopes.
- Column-level minimization/masking and whether row-level data is permitted.
- Export limits, retention, expiry, download authorization and audit events.
- Treatment of sensitive personal, financial, location and incident data.
- Whether export output is a point-in-time snapshot and how its source/version is recorded.

Before scheduled reports are implemented, approve:

- Recipient eligibility and verified destination.
- Schedule, timezone, failure handling and delivery channel.
- Data freshness and report finality.
- Secure delivery (prefer controlled access over sensitive attachments).
- Retry/idempotency, audit history, cancellation and recipient access revocation.

Do not add export/schedule buttons that appear operational until the corresponding trusted workflow exists.

## 10. Roles, scope and privacy

- Founder/CEO: receive approved company-level summaries and escalations; no assumption of routine operational execution.
- Central Finance: candidate owner for financial reporting, reconciliation exceptions, payout statements and finance report definitions, subject to approved role matrix.
- Central Admin/Operations: only reports required for assigned operational responsibilities.
- City Manager: city-scoped reports only after authoritative city assignment and backend enforcement are confirmed.
- Zone Supervisor: zone-scoped operational summaries only; no automatic access to all finance, identity or incident evidence.
- Support: assigned-case reporting only; no broad financial ledger access by default.
- Walker/Partner: own permitted earnings/payout statement only through the appropriate Partner experience, not unrestricted Admin analytics.
- Super Admin: do not assume this role is interchangeable with Central Admin or Finance. Follow the approved POL-021 and Team 01 role contract.

All role names, scope assignments and permissions remain subject to POL-021 and Team 01 decisions. This document does not grant permissions.

## 11. Data quality, reconciliation and audit

Required report-level controls:

- Source and aggregation version recorded for each generated report.
- Last successful refresh and source watermark, if backend supports it.
- Duplicate and late-arriving event handling defined.
- Reconciliation status and unresolved exception count visible for finance reports.
- No silent balancing or manual editing of calculated totals.
- Corrections represented by linked, reason-coded, authorized entries.
- Access to sensitive reports and all exports logged where supported.
- Report generation failures and missing source partitions surfaced to an accountable owner.
- Retention and deletion follow approved POL-020 schedules; no duration is invented here.

## 12. Planned acceptance checklist — NOT EXECUTED

1. A report cannot show “connected” when no authoritative data source is configured.
2. Every released metric has an approved metric-dictionary entry and owner.
3. Amount due, verified receipt, provider settlement and company bank receipt remain distinct.
4. Refund requested, approved and refunded-verified remain distinct.
5. Walker earnings, payable and payout paid-verified remain distinct.
6. Prepaid package allocation is not mislabeled as recognized revenue.
7. A failed query is not rendered as zero records or zero revenue.
8. Date filters use the documented timezone and date basis.
9. Start/end validation rejects invalid ranges.
10. City/zone scope is enforced server-side for direct query and export paths.
11. Unauthorized roles cannot retrieve restricted financial or personal data by direct API request.
12. Aggregate reports do not leak unnecessary customer/pet identity or precise location.
13. Drill-down preserves filters and re-checks row-level access.
14. Export is unavailable until approval, masking, audit and retention controls are implemented.
15. Scheduled delivery is unavailable until recipient verification and secure delivery are implemented.
16. Late-arriving events and duplicate source events do not silently double-count.
17. Reconciliation mismatches appear as exceptions with traceable ownership.
18. Report freshness and generation time are visible and truthful.
19. Historical report results can be explained from their source and definition versions.
20. Accessibility, mobile layout, loading, empty, stale, denied and failure states are verified.
21. Tests use synthetic/minimized data and do not require production personal data.
22. CI evidence is tied to the exact commit SHA containing the implementation.

All checks above are planned. None is marked PASS or executed by this document.

## 13. Dependencies and decisions required before implementation

| Dependency | Required decision/evidence | Owner |
|---|---|---|
| Metric dictionary | Definitions, formulas, date basis, units, owners and effective versions | Finance + Operations + Founder as applicable |
| Financial accounting | Revenue recognition, taxes, fees, refunds, expenses and P&L treatment | Founder + qualified CA/legal |
| Payment/reconciliation | Provider event, settlement and bank evidence contracts | Team 01 + Finance |
| Walker earnings/payout | Approved rate card, payout schedule, thresholds, adjustments and status contract | Founder + Finance + Team 01 |
| Role and geography | Canonical roles, city/zone assignments, direct-query enforcement | Team 01 + POL-021 approval |
| Privacy/retention | Data inventory, permitted purposes, export policy and approved retention schedule | Privacy owner + Founder/legal |
| Report backend | Trusted aggregation/read contract, pagination, freshness and error contract | Team 01 |
| Admin UI | Approved catalog, filters, charts/tables, states and accessible drill-down | Team 02 |

## 14. Implementation sequence after gates clear

1. Approve policy and metric definitions; record owner and effective date.
2. Team 01 proposes and verifies trusted read/aggregation contracts and authorization in Emulator.
3. Team 02 implements the report catalog and states against the approved contract, without embedding financial business logic in the client.
4. Add unit, widget, authorization, aggregation and Emulator tests using synthetic data.
5. Verify each report against source-ledger/provider evidence and document reconciliation.
6. Add exports/scheduling only after separate security/privacy approval.
7. Run Static Analysis, full test suite and Flutter Web build on the exact implementation commit.
8. Keep PR #51 Draft until approvals and required evidence are complete.

## 15. Current disposition

- Documentation-only deliverable.
- No Admin runtime/UI changes.
- No API or Firebase integration.
- No Firestore schema, rules, indexes, functions, provider, export or scheduler changes.
- No tests, Emulator runs or CI are claimed for this document.
- PR #51 remains Draft and unmerged.

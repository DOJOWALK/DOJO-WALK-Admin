# DOJO WALK Admin — Dashboard Deep Source Audit

- Audit date: 2026-10-30
- Repository: `DOJOWALK/DOJO-WALK-Admin`
- Branch: `ui/notion-brand-foundation-2026-10-28`
- PR: #51 (Draft/open; do not merge/deploy)
- Audited PR head: `99964e7192f4fc4809de8da42a1464212c9213a3`
- Source: `lib/screens/dashboard/dashboard_screen.dart` (38,744 bytes at inspected head)
- Shell: `lib/screens/dashboard/admin_shell.dart`
- Scope: static source review only. No app code, Firebase configuration, production data or runtime behavior changed.

## 1. What is implemented in source

- Four top metrics: all-time booking count, users count, walkers count, and paid payment amount.
- Live overview: in-progress bookings, walkers with `isOnline == true`, pending bookings and completed bookings.
- Booking status counts use `bookingStatusQueryAliases`.
- Recent bookings: latest eight by `createdAt`, with booking ID, pet ID and normalized status.
- Operations alerts: pending bookings, failed payments and walkers with `isOnline == false`.
- System activity: latest six audit log records.
- Responsive layout: metric cards use 4/2/1 columns; two-column dashboard sections stack below 900 px.
- Header actions route to Live Operations and Service Locations.
- Loading/error/empty handling exists for Recent Bookings and System Activity. Metric cards and live/status rows show partial loading/error indicators.

## 2. Confirmed gaps and risks

| Area | Source finding | Risk / required decision |
|---|---|---|
| Dashboard tests | No dedicated dashboard widget test file was found in the inspected test tree. | Add a dedicated widget test before calling this screen validated. |
| Alert rows | `_AlertStreamRow` always renders `snapshot.data ?? 0`; it does not distinguish waiting, permission denied or query failure. | A failed alert query can look like a genuine zero-alert state. Add explicit loading/error/permission states. |
| Status rows | `_StatusStreamRow` does distinguish errors/loading, but does not expose a retry action. | Add retry/re-subscription behavior or a screen-level refresh strategy. |
| Metric errors | `_StatCard`, `_RevenueCard` and `_LiveStreamRow` show an icon/tooltip on error, without a visible inline explanation or retry. | Important operational numbers can become unclear, especially on touch devices where tooltip discovery is weak. |
| Online walker metric | “Available Walkers” counts every walker with `isOnline == true`. | This is an online flag, not proof of schedule availability, assigned-work capacity, recent heartbeat or location freshness. Rename to “Online Walkers” unless a trusted availability contract is implemented. |
| Offline alert | “Inactive walkers” counts `isOnline == false`. | Offline is not equivalent to inactive/suspended/deactivated. Rename to “Offline Walkers” or query the approved lifecycle status. |
| Pending alert | “Unassigned bookings” counts only exact `status == 'Pending'`, while other booking metrics use alias-aware status queries. | Legacy status spellings can be missed by the alert. Reuse the canonical status alias helper. |
| Waiting assignment | “Waiting Assignment” is also a Pending booking count. | Pending may include records not yet eligible for assignment; confirm the canonical business definition before treating it as unassigned. |
| Revenue | Reads every payment document with exact `status == 'paid'` and sums numeric `amount` values in the client. | No currency filter, refund adjustment, fee deduction, date window or server-side aggregate. The label correctly says gross/all-time and discloses refunds/fees are not deducted; keep it explicitly informational until Finance defines the authoritative metric. |
| Collection counts | `_countAll` subscribes to full collection snapshots and uses `snapshot.size`. | Counts may incur read cost and include records outside the current admin's city/zone scope. Confirm role scope and cost strategy before production use. |
| Recent bookings | Query orders by `createdAt` and limits to eight. | Documents missing `createdAt` may not appear; index/query errors need visible state. No booking detail navigation is wired in this list. |
| System activity | Displays action and actorRole only; latest six audit logs. | No timestamp, actor identity, filtering or “view all” route from the dashboard. |
| Header status | Green dot and “Overview” are static. | It must not be interpreted as Firebase/system health. Replace with neutral “Company overview” or a real health state. |
| Greeting | Always says “Good morning”. | Time-inaccurate after morning; make greeting time-aware or use neutral “Welcome, Admin”. |
| Retry | No dashboard-wide retry control is present. | Provide refresh/retry for streams or ensure stream recreation is explicit and tested. |

## 3. Notion / product guardrails

- Dashboard remains the Admin command center; Live Operations opens from the prominent dashboard action.
- Keep gross paid amount clearly distinguished from net revenue and refunds.
- Do not introduce coupon metrics or coupon navigation.
- Do not show an “online” flag as proof of walker availability or GPS freshness.
- Do not make the UI a security boundary: city/zone scoping and role authorization must be enforced by trusted backend rules/services.
- Do not add Firebase integration or change Firestore contracts in this UI-first phase without the approved Notion contract.

## 4. Recommended next work (ordered)

1. Add dedicated dashboard widget tests using a controllable Firestore test/emulator setup or injectable dashboard data source; do not rely on live production Firebase in widget tests.
2. Fix `_AlertStreamRow` so waiting, error/permission-denied and successful zero are visibly distinct.
3. Rename “Available Walkers” to “Online Walkers” and “Inactive Walkers” to “Offline Walkers” until a verified availability/lifecycle contract exists.
4. Make pending/unassigned counts alias-aware and agree the precise “waiting assignment” state definition.
5. Replace the static green “Overview” indicator and fixed “Good morning” greeting.
6. Add visible refresh/retry and accessible error text for metric cards.
7. Define with Finance whether the gross paid amount is appropriate for this Dashboard role; preserve the explicit gross label until a net metric is approved.
8. Validate narrow mobile, tablet and desktop widths, including long IDs, query failures and permission-denied states.

## 5. Validation status

- Source review: **DONE** for the files listed above.
- Dedicated dashboard widget test: **MISSING**.
- Dashboard UI runtime/screenshot QA: **NOT EVIDENCED**.
- Exact-head CI for this audit commit: **NOT RUN / NOT YET VERIFIED**.
- Firebase integration: **NOT STARTED** (intentionally deferred).
- PR #51: keep **Draft/open**; no merge or deployment.

This report records source-level findings only; it does not claim that Firestore rules, production data, query indexes or runtime behavior have been verified.


## 6. Follow-up source changes (commit 9fcdb139451ab193c6c0d3d397101642c26b2ca7)

The following narrow UI corrections were committed after the source audit:

- Replaced the misleading static green status dot / “Overview” indicator with neutral “Company overview” text.
- Changed the fixed morning greeting to a time-aware morning/afternoon/evening greeting.
- Renamed “Available Walkers” to “Online Walkers”; it still reflects only the `isOnline` field and is not a schedule/capacity guarantee.
- Renamed “Inactive walkers” to “Offline walkers”; it does not imply account deactivation.
- Changed the unassigned-booking alert to use the existing booking-status alias helper for Pending.
- Added explicit loading and error/permission-denied indicators to alert count rows so a failed query is not silently rendered as zero.

These are source-level changes only. They have not been runtime-tested in this commit. The dashboard still lacks a dedicated widget test, and the alert rows still need a visible retry mechanism or an agreed refresh strategy.

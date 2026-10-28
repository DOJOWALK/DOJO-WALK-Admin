# DOJO WALK Admin UI — POL-040 File Map & Gap Audit

**Source of truth:** Notion POL-040 — Admin Service Location UI: Screen-by-Screen Design & Developer Checklist  
**Related specifications:** POL-038 (Zone lifecycle), POL-041 (API/backend contract), POL-042 (implementation/test plan)  
**Working branch:** `ui/notion-brand-foundation-2026-10-28`  
**Scope boundary:** UI and file organization only. Do not add Firebase integration, merge, or deploy from this workstream.

## Governing rules

- Founder/CEO is the final business approver for Zone launch/activation, material boundary changes, deactivation and reactivation.
- Central Admin prepares the request and executes an approved activation only after checks; it cannot approve its own request.
- Super Admin is not automatically Founder.
- State/UT, District and City are hierarchy/reference records; only Zone has service activation status.
- Zone polygon verification is mandatory before activation. Radius-only coverage is insufficient.
- Deactivation blocks new bookings but must preserve existing bookings and safely handle running walks.
- Use `#FF7900`, `#FFFAF5`, and `#252525`; display operational timestamps in IST.
- All mock/example data and disabled actions must remain clearly labelled. Do not present them as live data or completed server actions.

## Screen-to-file map

| POL-040 screen / requirement | Current file(s) | Audit status based on repository inspection |
|---|---|---|
| Location Dashboard / overview | `lib/features/service_location/screens/service_location_screen.dart` | Partial: existing Service Locations screen has hierarchy tabs/map preview; compare summary cards, attention panel, recent changes, and failure states against spec. |
| Location Directory | `lib/features/service_location/screens/zone_directory_screen.dart`, `service_location_screen.dart` | Prototype: search/status filters, parent path, Zone ID, boundary/readiness metadata, update metadata, links to review screens, and disabled lifecycle actions. Live pagination and data-backed states remain pending. |
| Add Location / Create Zone | `lib/features/service_location/screens/add_zone_screen.dart` | Prototype has four dependent selectors (State/UT → District → City → Zone). The fourth selector offers a create-new path plus city-dependent, explicitly marked mock existing-Zone options because the approved Zone catalog is not connected; name input appears only for the create-new choice, and selecting a mock existing Zone never edits it. A clearly labelled preview navigation opens Boundary Review without submitting. Boundary drawing, save and submission remain unavailable. |
| Location Details | `lib/features/service_location/screens/zone_details_screen.dart` | UI prototype receives example Zone metadata from Directory, shows hierarchy/readiness/audit details and keeps edit/lifecycle actions disabled. No live Zone record is loaded. |
| Boundary Review | `lib/features/service_location/screens/boundary_review_screen.dart` | Prototype: example rows, explicit unconnected map placeholder and evidence labels; no live boundary data or decision actions. Preview navigation opens Founder Approval Queue. |
| Founder Approval Queue | `lib/features/service_location/screens/zone_approval_queue_screen.dart` | Prototype: example rows with parent path, submitter, timestamp, revision, boundary status/hash and blockers; decision action remains disabled and approval remains separate from activation. |
| Activate / Suspend / Deactivate / Reactivate | `lib/features/service_location/screens/suspended_zones_screen.dart`, service-location service files | Partial: suspension/deactivation screen is a mock UI; verify activation lifecycle screen/guards and safe handling of bookings/running walks. No new Firebase actions in UI-only phase. |
| Import & Reconciliation | `service_location_screen.dart`, `services/location_csv_*.dart` | Existing UI/service files: audit visual states and alignment with POL-040; no claim that full acceptance suite passes. |
| Audit History | `audit_history_screen.dart`, `zone_audit_history_screen.dart` | Screens exist; verify loading, empty, error, permission-denied and success states and that mock data is not confused with live audit records. |
| Required UX states | All screens | Not yet proven complete: Loading, Empty, Error, Permission Denied and Success must be checked screen by screen. |

## Structural observations

- Service-location screens are grouped under `lib/features/service_location/screens/`; models, services and widgets have separate folders. Keep new work in these existing feature folders unless the source-of-truth architecture explicitly requires a change.
- The main Admin shell is `lib/screens/dashboard/admin_shell.dart`. Top-level destinations now route to UI prototypes or existing screens for Live Operations, Bookings, Walkers, Customers, Pets, Notifications, Support, Admin Users & Roles, Audit Logs, Reports, Finance, Settings Governance and Service Locations. Existing Dashboard/Bookings/Walker/Live Operations screens still need a policy-by-policy visual/interaction audit.
- Existing Firebase/service imports are already present in the repository. This UI-only phase must not expand or change backend integration.
- Coupons must not be reintroduced as an Admin menu item; the business decision is no coupon system.

## Confirmed form gap — fourth Zone selector

The Unified UI/UX Design System and POL-038/POL-040 explicitly require exactly four dependent selectors: State/UT → District → City → Zone. The prototype now includes the fourth Zone selector after City. Because the approved Zone catalog is not connected, existing choices are explicitly marked mock records; this is intentionally not represented as live Zone data. Existing Zone choices must come from an authoritative catalog when the UI data contract is approved. The Zone name/details input appears only for the create-new path. Do not add a Locality selector. Changing State/UT, District or City must clear all downstream selections.

## Validation record

- Earlier completed runs passed Analyze, the full test suite and Flutter Web build for the incremental Add Zone/Zone Directory/Finance/Audit UI commits. The latest code commit `b7db5707b9de7e452623d174086bd87addd3b640` has Analyze PASS; the full test suite is still running in GitHub Actions run `40685274460`, and Web Build has not started yet.
- The Suspended Zones filter test was updated to reveal lazy filter controls before interacting; it passed in a later full test run.
- Added widget tests for the fourth dependent Zone selector, parent-change resets, disabled Save Draft/Submit, Approval Queue safeguards, Directory lifecycle filters, Zone Details metadata and preview navigation. Run `40685274460` must finish before these newest changes can be marked PASS.
- A separate widget test was added for Founder Approval Queue authority copy, disabled decision buttons, and status filtering.
- Latest workflow runs must be inspected for their final results before declaring PASS. Do not infer success from an in-progress run.
- No merge, deployment, or new Firebase integration is authorized by this file.

## Next UI-only sequence

1. Finish run `40685274460`; fix any actual failing assertion before declaring PASS.
2. Confirm the newest Web Build succeeds after the full test suite.
3. Audit existing Dashboard, Live Operations, Bookings and Walker Management screens against their Notion policies, including loading/empty/error/permission-denied/success states.
4. Run a final full validation against the latest branch head and record the exact run link.
5. Only after UI and tests are complete, start the planned Firebase/auth/Firestore integration.

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
| Location Directory | `lib/features/service_location/screens/zone_directory_screen.dart`, `service_location_screen.dart` | Partial: directory screen exists; verify exact Zone-only status semantics, filters, readiness blockers, pagination, and action gating. |
| Add Location / Create Zone | `lib/features/service_location/screens/add_zone_screen.dart` | Prototype: State/UT, District, City and Zone name; boundary editor is disabled; data catalog is placeholder; no save/submission. |
| Location Details | Existing detail handling in service-location module | Gap to audit: no dedicated Location Details screen was found in the inspected screen list. Do not create a competing details flow until existing handlers are reviewed. |
| Boundary Review | `lib/features/service_location/screens/boundary_review_screen.dart` | Prototype: example rows and evidence labels; no live boundary data or decision actions. |
| Founder Approval Queue | `lib/features/service_location/screens/zone_approval_queue_screen.dart` | Prototype: example rows and disabled decision action; approval remains separate from activation. |
| Activate / Suspend / Deactivate / Reactivate | `lib/features/service_location/screens/suspended_zones_screen.dart`, service-location service files | Partial: suspension/deactivation screen is a mock UI; verify activation lifecycle screen/guards and safe handling of bookings/running walks. No new Firebase actions in UI-only phase. |
| Import & Reconciliation | `service_location_screen.dart`, `services/location_csv_*.dart` | Existing UI/service files: audit visual states and alignment with POL-040; no claim that full acceptance suite passes. |
| Audit History | `audit_history_screen.dart`, `zone_audit_history_screen.dart` | Screens exist; verify loading, empty, error, permission-denied and success states and that mock data is not confused with live audit records. |
| Required UX states | All screens | Not yet proven complete: Loading, Empty, Error, Permission Denied and Success must be checked screen by screen. |

## Structural observations

- Service-location screens are grouped under `lib/features/service_location/screens/`; models, services and widgets have separate folders. Keep new work in these existing feature folders unless the source-of-truth architecture explicitly requires a change.
- The main Admin shell is `lib/screens/dashboard/admin_shell.dart`. Several top-level menu entries currently use a generic “coming soon” screen; these are broader Admin UI gaps and need their own Notion specification mapping before implementation.
- Existing Firebase/service imports are already present in the repository. This UI-only phase must not expand or change backend integration.
- Coupons must not be reintroduced as an Admin menu item; the business decision is no coupon system.

## Confirmed form gap — fourth Zone selector

The Unified UI/UX Design System and POL-038/POL-040 explicitly require exactly four dependent selectors: State/UT → District → City → Zone. The current prototype has only three dropdowns plus a free-text Zone name field, so it does not yet meet this requirement.

Next UI implementation must add the fourth Zone selector after City, with the create-new path clearly represented. Existing Zone options must come from an authoritative catalog once available; until then, any illustrative options must be explicitly marked as examples and must not imply live data. Keep the Zone name/details input available only for the create-new path. Do not add a Locality selector. Changing State/UT, District or City must clear all downstream selections.

## Validation record

- The last observed completed run before the latest fixes failed in `SuspendedZonesScreen UI prototype filters example zones by status` with `Bad state: No element` in `scrollUntilVisible`; the test was attempting to scroll down to a filter control after it had already scrolled past it.
- Test was changed to interact with the filter first, then scroll to result rows and return to the top before selecting another filter.
- A separate widget test was added for Founder Approval Queue authority copy, disabled decision buttons, and status filtering.
- Latest workflow runs must be inspected for their final results before declaring PASS. Do not infer success from an in-progress run.
- No merge, deployment, or new Firebase integration is authorized by this file.

## Next UI-only sequence

1. Confirm the latest workflow result and fix the first real failing assertion/root cause.
2. Complete Service Location navigation and test coverage for Add Zone, Boundary Review, Founder Approval Queue, Suspended/Deactivated Zones and Audit History.
3. Audit Location Directory and details flow against POL-040, avoiding duplicate screens.
4. Map every top-level Admin menu item to its Notion specification and existing files before expanding the broader Admin UI.
5. Run full analyze, tests and web build; record exact run links and outcomes.

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
| Location Dashboard / overview | `lib/features/service_location/screens/service_location_screen.dart`, `lib/features/service_location/utils/boundary_preview_status.dart`, `test/features/service_location/boundary_preview_status_test.dart` | Partial: existing Service Locations screen has hierarchy tabs/map preview. Boundary preview status now distinguishes loading, error, disconnected source, and a real non-empty polygon count; the empty placeholder is no longer reported as zero active Zones. Compare summary cards, attention panel and recent changes against spec. |
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

- Baseline validation: GitHub Actions run `40687163413` completed successfully at commit `c41a1568bc54d0f2de16112fd1ece3c1ae4af7c7`. For recent UI changes, run `40741909918` passed at `3dd6943244944e31f5e7d2acd73c9238cf70b60e` (Zone Directory clear-search); run `40742326990` passed at `152e0e3eddf020375dd6be56cf37bf51632cf7a8` (Zone Audit History clear-search); and run `40742444471` passed at `d84a6a50b39f4a1cef9a768a9c100198f6b7071d` (Zone Audit History detail line breaks). Each run completed `flutter analyze`, the complete test suite, and Flutter Web release build successfully.
- Latest Service Location validation: run `40743210291` passed at `a721e31c730dac5b499443493d6becf48062f298` (raw provider exception details removed from user-facing location screens); run `40743789957` passed at `be4f34d5002e6d4982afbd89febae98471ae121a` (nested State/UT streams now show visible loading/error feedback); and run `40744272652` passed at `a65e8cdef73b142381a3fc029385efceeaf0e156` (City streams show loading/error feedback and State/City search has contextual empty messages). Each run completed analyze, full tests and web release build. Continue the screen-by-screen audit; do not infer that all POL-040 acceptance criteria are complete from these targeted fixes.
- The Suspended Zones filter test was updated to reveal lazy filter controls before interacting; it passed in a later full test run.
- Widget tests for the fourth dependent Zone selector, city-dependent mock options, parent-change resets, disabled Save Draft/Submit, Approval Queue safeguards, Directory lifecycle filters, Zone Details metadata, preview navigation, booking-status normalization, permission error classification and sensitive-field omission passed in run `40687163413`.
- A separate widget test was added for Founder Approval Queue authority copy, disabled decision buttons, and status filtering.
- Latest verified CI check (2026-10-29): runs [40757393216](https://github.com/DOJOWALK/DOJO-WALK-Admin/actions/runs/40757393216) and [40757415352](https://github.com/DOJOWALK/DOJO-WALK-Admin/actions/runs/40757415352) both failed in the complete test suite (199 passed, 3 failed); Analyze passed and Web Build was skipped. The failure was in Founder Approval Queue tests that assumed blocked example rows were visible under the default “Awaiting decision” filter. Test fixes were committed to the working branch, including an explicit regression test that blocked examples remain absent from “Awaiting decision”. Latest follow-up commit at this documentation check: `269591ea1b29a4f21c48194f8728c4ceac88acc7`; a fresh full CI result for the follow-up commits has not yet been verified. Do not mark the branch green until Analyze, all tests and Web Build pass on the latest head.
- Suspended Zones UI now explicitly documents the narrow emergency safety-suspension exception: only to prevent immediate harm, with an append-only audit record and prompt Founder/CEO notification. A corresponding widget assertion was added; latest full CI result remains unverified.
- Main Service Locations map status was corrected: the UI no longer reports `Active boundaries: 0` when the Zone-specific source is an intentional empty placeholder. It now explicitly says `Zone boundary source not connected` (or a loading/error state), so an unconnected data source is not misrepresented as verified zero coverage. Commit `a263ac2a8c2db9481a2486f91708fe808eebc597`; latest full CI result remains unverified.
- The boundary preview status logic is now isolated in `lib/features/service_location/utils/boundary_preview_status.dart` with four unit cases (loading, error, disconnected/empty source, and a non-empty polygon count). Added in commits `7068735699bde166f0f3c05d478a401e771a6397`, `a7bd0d363153b079444ed9e6428284d45b86fb87`, and `995ec6c050d953c8ed3f450c512d24d0e9e7ac70`. These new tests have not yet been confirmed by a full CI run.
- Do not infer success from an in-progress run; record the run ID and commit for every PASS claim.
- No merge, deployment, or new Firebase integration is authorized by this file.

## Next UI-only sequence

1. Continue the Service Location screen-by-screen audit against POL-040, especially hierarchy navigation, empty/error/permission-denied states and disabled lifecycle actions.
2. Audit existing Dashboard, Live Operations, Bookings and Walker Management screens against their Notion policies, including loading/empty/error/permission-denied/success states.
3. Run final full validation against the latest branch head and record the exact run link.
4. Only after UI and tests are complete, start the planned Firebase/auth/Firestore integration.

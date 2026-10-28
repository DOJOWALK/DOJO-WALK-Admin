# DOJO WALK Admin — Notion-Driven File Structure Contract

**Authority:** Notion is the source of truth. This file documents how the repository must be organized to implement the approved Notion specifications; it does not override them.
**Branch:** `ui/notion-brand-foundation-2026-10-28`
**Phase guardrail:** Admin UI and its validation first. Do not expand Firebase/backend integration, merge, or deploy during this UI phase.

## Non-negotiable rules

1. Before adding, moving, renaming, or duplicating a screen/model/service, identify the controlling Notion policy and update the Notion-to-file map.
2. Keep each domain's code in its established feature folder. Do not create a second implementation of an existing screen in a different folder.
3. Keep presentation, reusable widgets, domain models, services, and utilities separated by responsibility. Do not move code across these boundaries merely for cosmetic consistency.
4. Tests should mirror the production domain path under `test/` wherever practical.
5. A file path is not proof of implementation. Record the actual screen/state/test and exact-head CI evidence before marking a requirement complete.
6. Do not reorganize legacy files or change backend/service ownership based on assumptions. Record a specific Notion requirement and migration plan first.
7. Do not add Locality to the Create Zone form. Its selectors remain exactly State/UT → District → City → Zone.
8. Keep server-authorized actions disabled until backend authorization, readiness checks, and audit logging are actually implemented and tested.
9. Mark example/mock data clearly. Never represent it as live service data.
10. Keep the obsolete Coupons destination out of the Admin menu; DOJO WALK has no coupon-code system.

## Current domain-to-folder map

| Domain / responsibility | Production path | Test path | Governing Notion source(s) / notes |
|---|---|---|---|
| App theme and shared shell | `lib/app/`, `lib/screens/dashboard/admin_shell.dart` | Relevant widget tests under `test/` | DOJO WALK brand/system decisions; route menu items to the owning domain screen. |
| Dashboard | `lib/screens/dashboard/` | `test/screens/dashboard/` when added; otherwise existing screen-level test convention | Owner Dashboard in India Operating System & Area Launch Master. Metrics must be defined, not fabricated. |
| Bookings | `lib/screens/bookings/` | `test/screens/bookings/` | POL-026 assignment; POL-029 cancellation/reschedule/refund; POL-030 payment controls. |
| Live Operations | `lib/screens/live/` | `test/screens/live/` | POL-007, POL-008, POL-016, POL-020. Booking summaries use an explicit safe-field allowlist. |
| Service Locations / Zones | `lib/features/service_location/screens/`, plus its existing `models/`, `services/`, `widgets/`, and `utils/` subfolders | `test/features/service_location/` | POL-038, POL-039, POL-040, POL-041, POL-042. Keep Zone-only activation and revision/hash-bound approval rules. |
| Walker Management | `lib/features/walkers/` | `test/features/walkers/` | POL-004 and POL-026. Do not enable lifecycle mutations without policy-required evidence and authorization. |
| Customer Management | `lib/features/customers/` | `test/features/customers/` | POL-031 and POL-021. Current prototype/example data is not a live customer connection. |
| Pet Management | `lib/features/pets/` | `test/features/pets/` | POL-008 and POL-031. Keep unverified safety/health data clearly marked. |
| Notifications | `lib/features/notifications/` | `test/features/notifications/` | POL-032 and POL-020. Send/retry remain disabled until delivery channels and permissions exist. |
| Support & Complaints | `lib/features/support/` | `test/features/support/` | POL-009, POL-024, POL-016. Case transfer/resolution remains disabled until server workflow exists. |
| Admin Users & Roles | `lib/features/access_control/` | `test/features/access_control/` | POL-021. Founder/CEO approval authority is distinct from Super Admin technical access. |
| Audit Logs | `lib/features/audit/` | `test/features/audit/` | POL-021 and POL-020. Do not imply mock rows are persisted audit records. |
| Reports & Analytics | `lib/features/reports/` | `test/features/reports/` | India Operating System reporting standards and related operating policies. No invented KPI totals. |
| Finance Operations | `lib/features/finance/` | `test/features/finance/` | POL-012, POL-033, POL-029. Provider/reconciliation actions remain disabled until approved integrations and authorization exist. |
| Settings & Governance | `lib/features/settings/` | `test/features/settings/` | POL-021, POL-032, POL-009, POL-020, POL-031. Unconfigured settings must not be shown as saved. |

This map describes intended ownership and the current documented layout; it is not a claim that every listed test folder already exists or that every policy is fully implemented.

## Service Location file-level authority

The detailed screen-by-screen mapping lives in `docs/ui/NOTION_POL040_FILE_MAP.md`. The cross-domain Admin mapping lives in `docs/ui/ADMIN_UI_NOTION_FILE_MAP.md`.

For Service Locations, keep screens in `lib/features/service_location/screens/`; put pure status/formatting logic in the existing `utils/` area; keep data access in the existing `services/` area; and keep reusable visual elements in `widgets/`. Use the existing `models/` folder for typed domain representations when a model is required. Do not introduce a parallel `lib/screens/service_location/` tree.

The Admin service-location setup hierarchy is State/UT → District → City → Zone. The Create Zone UI has exactly four dependent selectors—State/UT → District → City → Zone—and must not add a Locality selector or a Locality step to the Zone activation workflow. Only Zone is a service activation unit; State/UT, District and City are reference hierarchy records. Founder/CEO approves business decisions; Central Admin prepares requests and executes approved changes only after server checks; Super Admin technical access alone does not grant Founder authority.

## Change checklist for every next task

- [ ] Read the relevant Notion policy and note whether it is draft or approved.
- [ ] Find the existing owner file before creating a new file.
- [ ] Update the appropriate Notion-to-file map if the path or responsibility changes.
- [ ] Add focused tests beside the domain's existing tests; cover Loading, Empty, Error, Permission Denied, Success where applicable.
- [ ] For mobile UI, add or update narrow-viewport regression coverage.
- [ ] Keep mock data, disabled actions, and missing backend connections explicit in both UI and docs.
- [ ] Run Analyze, the complete test suite, and Flutter Web release build on the latest code head.
- [ ] Record the exact commit and run URL. Do not claim PASS for an earlier commit or an in-progress run.
- [ ] Keep PR #51 Draft; no merge, deployment, or new backend integration until the UI phase is complete.

## Current validation caveat

The branch head must be checked independently before declaring CI green. The latest code head reported during the handoff was `f8ff6a53daba7a70436c9419755a20c3bb9f4b7a`; the PR description explicitly notes that the booking status alias update and current head still require exact-head full CI verification. Historical successful runs are not proof that this later head passes.

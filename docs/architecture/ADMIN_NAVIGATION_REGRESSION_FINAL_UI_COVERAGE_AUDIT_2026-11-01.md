# Admin Navigation Regression & Final UI Coverage Audit — 2026-11-01

**Task:** ADM-P2-05
**Repository:** DOJOWALK/DOJO-WALK-Admin
**Branch:** ui/notion-brand-foundation-2026-10-28
**PR:** #51 — Open, Draft, Unmerged
**Audit type:** Read-only source, test and documentation reconciliation
**Status:** PARTIAL — sidebar navigation correction is present and has focused widget coverage; actual screen mapping, key Dashboard routes, AuthGate authorization states, visual QA and canonical file-tree migration remain incomplete.

## 1. Purpose and scope

Close the Admin UI navigation and coverage audit by reconciling:
- Team 02 responsibilities and boundaries in Notion.
- Unified DOJO WALK UI/UX standards.
- Current PR #51 source and test paths.
- Existing screen-level audits and implementation requirements.
- Canonical target file structure.

This is an audit and implementation plan, not a declaration that the Admin UI is complete or release-ready. No source-code changes are made by this document.

## 2. Authoritative product and team requirements

### Team 02 — Admin App (Notion)
Team 02 owns the Central Admin application, role-aware navigation, operational screens, support/incidents/refunds/finance, service-location administration, approvals, audit/reporting, responsive behavior, accessibility and Admin tests.

Team 02 boundaries:
- Firebase integration must use Team 01 approved contracts.
- Do not change backend repository, schemas, Rules or Functions from Admin.
- UI visibility is not authorization; backend must enforce role and scope.
- Founder-only approvals remain separate from Super Admin technical access and Central Admin operational access.
- Definition of Done includes acceptance criteria, complete UI states, actual tests/CI evidence and backend permission checks.

### Unified UI/UX Design System (Notion)
- Premium SaaS + minimal UI + map-centric operations.
- Brand tokens: orange #FF7900, background #FFFAF5, text #252525.
- Responsive mobile/tablet/desktop; no clipped content or accidental horizontal overflow.
- Loading, empty, error, permission-denied and confirmed-success states where applicable.
- Status must not rely on color alone; live data must expose freshness.
- Dashboard opens the detailed Live Operations workspace; Live Operations is not a duplicate sidebar destination.
- Zone creation uses exactly State/UT → District → City → Zone; no Locality selector; only Zone has activation controls and verified polygon evidence is required.
- The design-system page explicitly says implementation and visual QA are not yet verified.

## 3. Current navigation source inspection

Inspected:
- `lib/screens/dashboard/admin_shell.dart` (blob SHA `696fc0afe80c7b109b527f3cc1b9c2d33f8de82a`)
- `test/screens/dashboard/admin_shell_test.dart` (blob SHA `702898b2ae4ce3212ca328094cace960249147d8`)
- `docs/ui/ADMIN_FINAL_INTEGRATION_NAVIGATION_AUDIT_2026-10-31.md`
- `docs/ui/ADMIN_SHELL_NAVIGATION_WIDGET_TESTS_2026-10-31.md`
- `docs/PROJECT_FILE_STRUCTURE.md`

Current source contains 13 sidebar destinations:
1. Dashboard
2. Bookings
3. Walker Management
4. Customers
5. Pets
6. Notifications
7. Support
8. Admin Users & Roles
9. Audit Logs
10. Reports & Analytics
11. Finance Operations
12. Settings
13. Service Locations

Findings:
- Standalone Live Operations sidebar entry is absent.
- Live Operations remains reachable through the Dashboard's `onOpenLiveOperations` callback, which pushes a dedicated `LiveOperationsScreen`.
- Dashboard Service Locations shortcut selects current destination index 12.
- Coupon-code route/menu is absent, consistent with the explicit no-coupon business decision. Do not restore coupon UI from historical folder references.
- Menu selection is currently index-based, and the screen switch repeats those numeric indexes. This creates index-drift risk if menu order changes.
- The shell has a `contentBuilder` injection point used by tests; it allows deterministic navigation-selection testing without Firebase.

**Navigation source result: PARTIAL PASS.** The duplicate Live Operations sidebar issue recorded in the earlier audit has been corrected in the inspected source. The remaining route/action coverage below is not complete.

## 4. Existing AdminShell widget test coverage

The current `admin_shell_test.dart` contains four tests:

1. Desktop sidebar omits duplicate Live Operations destination and confirms expected entries/logout tooltip.
2. Iterates all 13 sidebar destinations using the injected `contentBuilder`; confirms each selected index displays its deterministic test destination.
3. Mobile drawer navigates to Settings and closes after selection.
4. Logout confirmation can be cancelled safely.

Important limitation:
- Test 2 verifies that every sidebar item can select an index, but it intentionally replaces production screen composition with `contentBuilder`. It does **not** prove that the real `_buildContent()` switch maps each index to the correct production screen.
- The current tests do not verify Dashboard → Live Operations route push, Dashboard → Service Locations shortcut, positive logout/sign-out flow, or actual route return behavior.
- No dedicated AuthGate test file was present in the PR #51 changed-file listing. This is a bounded listing observation, not proof no such test exists elsewhere in the repository.

## 5. Route and action regression matrix

| Entry/action | Source mapping | Existing direct test evidence | Result / remaining gap |
|---|---|---|---|
| Dashboard | DashboardScreen | Shell renders Dashboard heading; Dashboard has its own tests | Partial; no complete production route contract |
| Dashboard → Live Operations | MaterialPageRoute to LiveOperationsScreen | No direct shell route test found in inspected test | Add route push/return test |
| Dashboard → Service Locations | Selects index 12 | No direct shell shortcut test found | Add actual production screen selection test |
| Bookings | Switch index 1 → BookingsScreen | Separate Bookings tests exist | Screen tested separately; shell mapping not directly asserted |
| Walker Management | Index 2 → WalkerManagementDashboardScreen | Walker widget/service tests exist | Screen tested separately; shell mapping not directly asserted |
| Customers | Index 3 → CustomerManagementScreen | Customer screen tests exist | UI/prototype data limitations remain |
| Pets | Index 4 → PetManagementScreen | Pet screen tests exist | UI/prototype data limitations remain |
| Notifications | Index 5 → NotificationCenterScreen | Notification screen tests exist | Delivery remains unconnected |
| Support | Index 6 → SupportCenterScreen | Support screen tests exist | Case backend remains unconnected |
| Admin Users & Roles | Index 7 → AdminAccessControlScreen | Access-control tests exist | Prototype; role/security workflow not implemented |
| Audit Logs | Index 8 → AdminAuditLogsScreen | Audit screen tests exist | Prototype; live audit feed not proven |
| Reports & Analytics | Index 9 → ReportsAnalyticsScreen | Report screen tests exist | Catalog remains not connected |
| Finance Operations | Index 10 → FinanceOperationsScreen | Finance screen tests exist | Finance contract and mutation gate unresolved |
| Settings | Index 11 → SettingsGovernanceScreen | Settings screen tests exist | Policy-mapped preview; persistence/governance not connected |
| Service Locations | Index 12 → ServiceLocationScreen | Multiple zone/location widget tests exist | Zone workflow still blocked by backend contract/approval gates |
| Mobile drawer | Drawer item sets selected index and closes drawer | Settings selection/close test | Partial; test representative item only |
| Logout cancel | Confirmation returns false; no sign-out | Direct test exists | Covered |
| Logout confirm | Confirmation returns true then AuthService.signOut | No positive sign-out test found | Add injectable auth/sign-out dependency and success/failure tests |

The route mapping above is source-inspected. It is not evidence that each screen's business workflow is connected or production-authorized.

## 6. Screen implementation and integration coverage summary

This summary consolidates prior source audits; it does not re-run every feature audit.

| Admin area | Current evidence | UI / integration disposition |
|---|---|---|
| Dashboard | Live Firestore count/aggregate streams; alert-quality gaps documented | Partially connected; metrics and alert truth require source/contract improvements |
| Live Operations | Online Walker map and route display; stale GPS/session isolation gaps documented | Not safety-grade verified |
| Bookings | Firestore read-only snapshot; cancellation metadata displayed | Read-only; lifecycle mutations/assignment contract not connected |
| Walker Management | Streams and privileged mutation path exist; role/scope and Emulator coverage gaps remain | Partially connected; authorization/test gates open |
| Customers | Hard-coded examples in inspected screen | UI prototype |
| Pets | Hard-coded examples in inspected screen | UI prototype |
| Notifications | Hard-coded examples and local filters | UI prototype; delivery not connected |
| Support | Hard-coded cases and disabled actions | UI prototype; case intake/mutation not connected |
| Admin Users & Roles | Static role proposal | UI prototype; role/scope/MFA workflows not implemented |
| Audit Logs | Hard-coded examples | UI prototype; trusted event feed not proven |
| Reports & Analytics | Six report catalog entries marked Not connected | UI prototype; datasets/export/scheduling not connected |
| Finance Operations | Prototype and finance contract gaps | Not release-ready for financial mutation |
| Settings | Policy-mapped preview | Persistence and governance controls not verified |
| Service Locations | Existing screens/services/tests; zone callable/boundary/approval gaps remain | Partial; backend contract and authorization gates open |

No screen should be marked “Implemented & Verified” based on route presence, mock data, disabled controls or widget rendering alone.

## 7. Canonical file-tree reconciliation — sample classification

The canonical target in `docs/PROJECT_FILE_STRUCTURE.md` is approved as a target, but the document explicitly says it does not certify implementation. The current repository remains a hybrid of legacy `lib/screens/*` and feature-based `lib/features/*`.

| Target area | Current inspected paths | Classification |
|---|---|---|
| `lib/main.dart`, `lib/app/app.dart` | Existing app entry/composition | Existing / Correct |
| `lib/core/constants`, `errors`, `routing`, `theme`, `utils` | Shared concerns still partly in legacy paths | Move / Refactor; inventory imports first |
| `lib/features/auth` | AuthGate and AuthService remain under `lib/screens/auth` and `lib/services` | Move / Refactor |
| `lib/features/dashboard` | Dashboard and shell remain under `lib/screens/dashboard` | Move / Refactor |
| `lib/features/bookings` | Booking UI/data source remain under `lib/screens/bookings` | Move / Refactor |
| `lib/features/live_operations` | Live UI remains under `lib/screens/live` | Move / Refactor |
| `lib/features/walkers` | Feature screens/services/widgets exist | Existing / Correct in part; reconcile remaining files |
| `lib/features/service_location` | Feature screens/services/widgets exist | Existing / Correct in part |
| `lib/features/settings` | Feature screen exists | Existing / Correct in part |
| `lib/features/customers`, `pets`, `support`, `notifications`, `access_control`, `audit`, `reports`, `finance` | Feature folders/screens exist in PR changed-file inventory | Existing / Correct in part; audit dependencies and ownership |
| `lib/data/reference/india_locations` | Runtime data paths require separate inventory/provenance check | Pending verification |
| `lib/shared/widgets`, `lib/shared/services` | Shared components/services not yet fully reconciled | Pending inventory |
| `lib/firebase_options.dart` | Preserve existing configuration | Existing / Correct; no change authorized |
| `lib/features/coupons` | Business decision explicitly says no coupon-code system | Not applicable — do not implement |
| `test/core`, `test/features`, `test/data` | Tests currently include legacy `test/screens` plus `test/features` | Move / Refactor in small verified batches |
| `docs/architecture`, `docs/qa`, `docs/testing`, `docs/ui` | Documentation organized across these directories | Existing / Correct; avoid duplicate sources |

This is a preliminary classification, not a complete recursive tree audit. Do not create empty target directories or bulk-move files. Before each move, inspect imports, tests, workflows, code ownership and external links; move a small batch and validate it independently.

## 8. Visual QA and responsive coverage

Existing evidence:
- AdminShell test exercises a 1440×1000 desktop viewport.
- AdminShell test exercises a 390×844 mobile viewport for drawer → Settings.
- A prior CI run exposed a 7.7px horizontal overflow in Settings at 390px; the Settings card header was corrected and a later CI run passed.
- Unified UI/UX design system requires mobile/tablet/desktop, accessible labels/focus, no overflow and no color-only status.

Remaining gaps:
- No comprehensive visual screenshot review for every Admin screen at mobile, tablet and desktop was established by this audit.
- No full tablet breakpoint route/layout matrix was established.
- No full keyboard-only and screen-reader audit was established.
- No verified map interaction/resize/marker accessibility audit was established.
- No cross-screen visual regression baseline was established.

A passing widget test or web build is not a substitute for reviewing rendered screenshots at the target breakpoints.

## 9. Exact-head CI and validation evidence

Historical evidence:
- The previous navigation follow-up documented CI run `41232609407` for then-current PR head `3887866fa13f33f81cb5c77d910b822c4b47eb48`: analyze passed, 355 tests passed, Web release build succeeded. That result belongs to that exact earlier head.
- The AdminShell test addition document records run `41231360615` with analyze PASS, 355 tests PASS and Web build PASS for the merge ref used in that run.
- Settings/Governance requirements commit `d3a74049d8f3dd686500674b50050515d2c53ffc` has GitHub Actions run #451 (`41243225423`) completed successfully. This is docs-only commit validation and does not prove any new runtime behavior.

This audit document commit is docs-only. No workflow run is claimed for it unless a matching exact-SHA run is independently observed. Do not inherit an earlier CI PASS as proof for a later commit.

## 10. Prioritized remaining work

### P0 — Before any privileged/live workflow is enabled
1. Team 01 resolves canonical role and geographic-scope contract; POL-021 approval remains required.
2. Team 01 publishes trusted booking, assignment, walk, GPS, alert and incident contracts.
3. Complete AuthGate and feature-level authorization tests against approved backend roles/scopes.
4. Keep all privileged actions blocked until trusted server authorization and audit behavior are verified.

### P1 — Navigation regression completion
1. Replace numeric menu indexes with stable destination IDs or typed route definitions, preserving existing behavior.
2. Add tests against actual production composition (not only injected contentBuilder) for all 13 menu-to-screen mappings.
3. Add Dashboard → Live Operations push/return test.
4. Add Dashboard → Service Locations shortcut test.
5. Add positive logout success and failure tests through an injectable auth dependency.
6. Add AuthGate tests for unauthenticated, missing Admin record, inactive Admin, active Admin, and backend read failure.
7. Verify mobile drawer selection for top, middle and bottom destinations; verify no overflow at 390px and tablet breakpoints.

### P2 — UI coverage and structure
1. Complete screenshot review for every screen at agreed mobile/tablet/desktop sizes.
2. Add keyboard, semantic label and screen-reader checks for critical workflows.
3. Create a complete recursive path-by-path migration matrix against the canonical target.
4. Migrate legacy screen/service paths only in small batches with import/test/workflow validation.
5. Keep disconnected screens explicitly labeled as prototypes/not connected until trusted data contracts are implemented.

## 11. Planned acceptance checklist — NOT EXECUTED

1. Sidebar contains exactly the approved 13 destinations and no coupon-code or duplicate Live Operations entry.
2. Every production menu destination maps to the intended screen.
3. Dashboard Live Operations action opens the detailed workspace and returns correctly.
4. Dashboard Service Locations action opens the intended destination.
5. All mobile drawer destinations can be reached and drawer closes after selection.
6. Logout cancel does not sign out.
7. Logout confirm signs out only after user confirmation.
8. Logout failure produces a safe recoverable message.
9. AuthGate handles unauthenticated, missing, inactive, active and backend-error states correctly.
10. No screen is authorized solely because it is visible in the sidebar.
11. All privileged screens/actions enforce backend role and geographic scope.
12. Loading, empty, error, denied, offline, stale and success states are explicit for applicable screens.
13. Prototype screens do not show fake records as live production data.
14. Dashboard alert and financial labels reflect their verified source/semantics.
15. Service Location form preserves State/UT → District → City → Zone; no Locality selector.
16. Only Zone has activation controls and boundary verification is required.
17. Coupon-code UI/route/behavior remains absent.
18. Mobile, tablet and desktop layouts have no horizontal overflow or clipped actions.
19. Keyboard and screen-reader semantics are verified for navigation and critical actions.
20. Canonical path migration is documented before files move; imports/tests/workflows remain valid.
21. Flutter format/analyze/full tests/Web release build run on the exact implementation SHA.
22. CI, screenshot and authorization evidence are linked to the exact commit.

All checks above are planned unless a specific historical test/CI result is explicitly described in this audit. No new tests are executed by this document.

## 12. Current disposition

**PARTIAL / NOT RELEASE-READY.**

- The duplicate Live Operations sidebar destination is removed in inspected source.
- The 13 sidebar entries have selection coverage using a test content builder, but actual production screen mapping is not fully covered by that test.
- Dashboard shortcuts and positive logout remain without direct shell tests in the inspected test file.
- AuthGate role/scope and session enforcement remain separate backend/security gates.
- Multiple screens remain prototypes or read-only; feature presence does not equal completed workflow.
- Canonical file-tree migration and comprehensive visual QA remain pending.
- No Admin runtime UI, route, Firebase, API, schema, Rules, Functions, provider or production configuration was changed by this audit.
- No tests or Emulator runs are claimed for this document.
- Keep PR #51 Open, Draft and Unmerged. Do not merge or deploy based on this audit.

# Admin Settings & Governance Audit — 2026-11-01

## Scope
Read-only source review on branch `ui/notion-brand-foundation-2026-10-28`.

Reviewed:
- `lib/features/settings/screens/settings_governance_screen.dart`
- `test/features/settings/settings_governance_screen_test.dart`
- `lib/screens/dashboard/admin_shell.dart`
- `lib/features/access_control/screens/admin_access_control_screen.dart`
- `lib/features/audit/screens/admin_audit_logs_screen.dart`
- `lib/services/auth_service.dart`
- `lib/screens/auth/auth_gate.dart`

Repository searches covered FCM, shared preferences, locale persistence, MFA, session timeout and admin membership usage.

No runtime code, Firebase, Firestore Rules, production configuration, merge or deployment changes were made. Tests and Emulator were not run.

## 1. Settings & Governance screen

- AdminShell exposes Settings and routes it to `SettingsGovernanceScreen`.
- The screen explicitly describes itself as a policy-mapped preview; no configuration changes are saved.
- Five sections are shown: Language & accessibility, Security & sessions, Notification channels, Data privacy & retention, Company support channels.
- Language preference persistence is not configured; its action is disabled.
- Security section identifies POL-021 as Draft and says MFA, session expiry, re-authentication and recovery need approved values and server enforcement. It links to the role-matrix prototype; it does not configure security settings.
- Notification channels are marked Not configured; the screen correctly says channels should only be shown as available after provisioning and verification. It links to the prototype Notification Center.
- Data retention/deletion controls are disabled pending approval.
- Company support contact editing is disabled and no phone number or 24/7 support coverage is invented.
- No settings repository, persistent preference store, remote configuration source, environment configuration editor or settings mutation callable is connected in the inspected screen.

## 2. Authentication and session boundary

- `AuthService.signInAdmin` signs in with Firebase Auth, then reads `admin_users/{uid}` and requires the document to exist and `isActive == true`; on membership verification failure it signs out and rethrows.
- `AuthGate` independently checks the same membership existence/active flag and fails closed to the login screen if it cannot verify membership.
- Neither inspected entry point enforces a role, geographic scope, MFA challenge, session age/expiry, re-authentication or account recovery workflow.
- AuthService source comment explicitly leaves role-specific permissions to Admin feature gates and trusted Firebase callables. This does not prove every feature gate/callable is implemented or consistently enforced.
- AdminShell navigation itself is common to all active Admin members; hiding a navigation item is not an authorization boundary.

## 3. Related governance surfaces

- Admin Users & Roles is a UI-only prototype aligned with POL-021, which the screen labels Draft. Role grants, scope changes, disable/revoke and MFA controls are disabled.
- Audit Logs is a UI-only prototype with four hard-coded example entries. Search/result filters are local-only; Export is disabled. It does not read live `audit_logs` in this screen or prove append-only/tamper-resistant storage.
- Earlier source audits found AuthGate/AuthService active-membership-only checks and no complete role × action × geographic-scope gate in AdminShell. Treat those as implementation blockers until the backend and Emulator contracts are verified.

## 4. Repository search observations

- No `FirebaseMessaging` usage was found by the Admin repository search, so push provisioning/delivery cannot be claimed from this source snapshot.
- No `SharedPreferences`, `setLocale`, or `Locale(` usage was found in the searched Admin source; language preference persistence was not identified.
- No `signInWithMultiFactor` or `multiFactor` usage was found; MFA is not demonstrated by the inspected Admin client.
- No connected settings persistence/configuration service was identified in the matched Settings screen paths.

Search findings are bounded to the Admin repository and searched terms; they do not prove the wider Firebase project or external identity provider lacks these capabilities.

## 5. Required implementation gates

1. Finalize POL-021 with exact role × action × geographic scope matrix, role hierarchy, approval separation, privileged action controls and emergency access rules.
2. Reconcile Team 01 D01–D05 decisions and exact callable/Firestore contracts before enabling any role, scope or security control.
3. Require backend-enforced authorization for every read/write; client navigation and disabled buttons are UX only.
4. Define MFA requirement and enrollment/recovery for privileged roles, step-up re-authentication for high-risk actions, session idle/max-age limits, revocation and device/session visibility.
5. Define language preference precedence (account/device), supported locale codes, persistence, fallback and RTL/accessibility behavior; do not expose an unpersisted selector as saved.
6. Provision and verify notification providers, tokens, consent, delivery receipts and retry controls before marking any channel available.
7. Approve privacy retention/deletion schedule, legal hold, evidence retention, export/redaction and data-subject request process before adding destructive controls.
8. Define verified company support contacts, staffed hours, ownership, escalation fallback and customer-facing publication approval.
9. Define append-only audit schema and trusted write path with actor, role, scope, action, resource, result, reason, request/correlation ID and server timestamp; restrict reads and exports by role/scope.
10. Add Emulator/integration tests for missing/inactive membership, role and out-of-scope denial, MFA/step-up, session expiry/revocation, settings authorization, privacy retention, notification provisioning and audit atomicity/tamper resistance.
11. Keep all configuration mutations disabled until policy approval, backend contract confirmation and Emulator evidence are attached.

## Status
- Settings & Governance screen: PRESENT as a preview.
- Settings persistence / remote configuration: NOT CONNECTED in inspected screen.
- Language preference persistence: NOT FOUND in searched Admin source; UI action disabled.
- MFA/session expiry/re-authentication: NOT VERIFIED; no MFA client usage found in search.
- Notification provider provisioning: NOT CONFIGURED in screen; no FirebaseMessaging usage found by repository search.
- Retention/deletion and support-contact mutation: DISABLED.
- AuthGate/AuthService: active Admin membership existence/status check only in inspected source; role/scope/MFA/session policy not enforced there.
- Role matrix and Audit Logs: UI-only prototypes; mutation/export controls disabled.
- Existing Settings widget tests: PRESENT for policy sections and disabled controls; NOT EXECUTED by this audit.
- Emulator/security/session/provider evidence: NOT RUN / NOT PROVIDED.
- Runtime/Firebase/configuration changes, merge, deployment: NONE.
- Admin PR #51 remains Draft and unmerged.
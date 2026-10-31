# Admin Settings & Governance — Implementation Requirements (Draft)

**Task:** ADM-P2-03  
**Date:** 2026-11-01  
**Status:** DRAFT — requirements only; source policies remain unapproved where noted. Not implemented, not tested.  
**Repository:** DOJOWALK/DOJO-WALK-Admin  
**Branch:** ui/notion-brand-foundation-2026-10-28  
**PR:** #51 — Draft, unmerged

## 1. Purpose and implementation boundary

Define the requirements for a secure, understandable Admin Settings and Governance experience. Settings must distinguish an individual Admin's personal preferences from company-wide operational configuration, privileged security controls, and policy-governed data/vendor settings.

Team 02 owns Admin UI requirements. Team 01 owns trusted backend authorization, persistence, configuration contracts, secret handling and enforcement. Policy owners/Founder approve business, security, privacy and governance decisions. API/Firebase integration remains deferred until approved contracts and cross-team readiness.

This document does not authorize changing production settings, changing roles, enabling MFA/session policies, selecting retention periods, configuring providers, or deploying any integration.

## 2. Evidence reviewed

Notion sources reviewed:

- **POL-021 — Access Control, Admin Roles & Privileged Account Security:** Draft, not approved/implemented/tested. Calls for least privilege, named accounts, MFA for privileged accounts where supported, session expiry/revocation/re-authentication, secure recovery, server-side role/scope enforcement, secret management, access review and security logging.
- **POL-014 — Privacy & Data Access:** Draft, not approved/implemented/tested. Requires privacy minimization, role/scope access, restricted location/identity/financial data, approved vendor use, access/deletion workflows, and truthful tracking states.
- **POL-020 — Data Privacy, Retention & Deletion:** Draft, not approved/implemented/tested. Requires a data inventory, approved category-specific retention, controlled deletion, legal holds, backup/vendor handling and restricted audit access.
- **POL-032 — Notifications, Communication Preferences & Messaging:** Draft, not approved/implemented/tested. Separates essential service/security messages from optional marketing; requires versioned approved templates, consent/preference evidence, delivery status and approved channels.
- **POL-018 — Business Continuity, Backup & Disaster Recovery:** Draft, not approved/implemented/tested. Requires documented backup scope, access, ownership, recovery targets, restore tests and evidence; no backup or restore capability is presumed.
- **POL-019 — Vendor, Third-Party Services & Integration Management:** Draft, not approved/implemented/tested. Requires vendor purpose/owner/data/access/cost/contract register, due diligence, least privilege, testing, approval, monitoring, fallback and offboarding.

Existing Admin source audit (2026-11-01):

- Settings screen is a policy-mapped preview; no settings changes were found to persist.
- Language preference persistence is not configured in the inspected path.
- Security policy POL-021 remains Draft; MFA, session expiry, re-authentication and recovery values/enforcement are not configured/verified in the inspected Admin flow.
- Notification channels are not configured in the inspected Settings path.
- Data retention/deletion controls and company support contact settings are disabled.
- AuthService and AuthGate check that an Admin record exists and is active; the inspected entry path does not enforce role, geographic scope, MFA, session age/expiry or re-authentication.
- AdminShell provides common navigation and is not an authorization boundary.
- Users & Roles and Audit Logs were previously audited as UI-only prototypes.

These are bounded findings from inspected Admin source paths, not proof that no related platform configuration exists elsewhere.

## 3. Settings taxonomy — keep separate

### A. Personal Admin preferences

Examples:
- Preferred interface language.
- Display timezone, if supported and clearly distinguished from server/reporting timezone.
- Notification preferences for Admin-user operational alerts, if approved.
- Accessibility/display preferences.

These affect only the signed-in Admin's own experience. They must not change company-wide customer language, notification templates, operational time, or another user's settings.

### B. Company-wide configuration

Examples:
- Company display name, approved logo/brand assets and official support contact details.
- Approved service communication channels and support hours.
- Approved operational defaults or configuration values exposed through a governed backend contract.

Changes require a defined owner, permission, validation, effective date, audit event and rollback/review path. Do not store secrets or credentials in ordinary settings documents.

### C. Security and access governance

Examples:
- Admin account lifecycle, role/scope grants, MFA policy, session/re-authentication policy, recovery, emergency access and access reviews.
- Security configuration and audit visibility.

These are privileged operations. A settings page must not make an ordinary Admin able to grant themselves access or weaken security controls.

### D. Privacy, retention and data governance

Examples:
- Data inventory references, approved retention schedule, deletion/legal-hold workflow and export restrictions.
- Privacy notice/consent version references and accountable owner.

The Admin UI may display approved policy status and links; it must not invent legal retention periods or enable destructive data actions without a separate approved workflow.

### E. Vendor and integration governance

Examples:
- Vendor/service register, owner, purpose, environment, data categories, permissions, approval/review dates, support route, outage impact and retirement status.
- Integration health and configuration status.

Show status as configured/verified only when trusted evidence supports it. Never display or reveal secret values.

## 4. General settings record and change governance

Before any setting is persisted, Team 01 must define its authoritative contract and decide which settings are user-scoped, company-scoped, environment-scoped or policy-controlled.

Candidate metadata for a governed setting:

- Stable setting key and schema/version.
- Scope/owner (user, company, environment or governed policy).
- Current value or safe masked representation.
- Data type, allowed values and validation rules.
- Effective date/time and timezone where relevant.
- Last changed by and server timestamp.
- Change reason/reference and approval evidence where required.
- Version/concurrency token and rollback/review reference.
- Sensitivity classification and read/write permissions.

Requirements:
- Validate on both client and trusted backend.
- Reject unknown keys and unsupported values; fail closed for privileged settings.
- Avoid storing secrets in client-readable settings. Use approved secret management and expose only non-sensitive status/metadata.
- Use optimistic concurrency or an equivalent conflict-safe contract; show when another Admin has changed a setting.
- Make effective/pending/rejected/failed states explicit. Do not optimistically show a value as saved before backend confirmation.
- Record successful and denied privileged changes through the approved audit event contract.
- Separate propose, review, approve and execute where separation of duties is required.
- Provide a controlled rollback path for reversible configuration; never imply rollback reverses already-sent messages, completed payments or other external side effects.

## 5. Personal preferences requirements

- Language preference is per Admin account and persists only after a trusted save succeeds.
- If a language translation is incomplete, show a clear fallback; do not mix untranslated policy text in a misleading way.
- Display timezone preference must not silently alter source timestamps, financial date basis or company-wide timezone.
- Use an explicit timezone identifier, not a free-form label, if timezone selection is approved.
- Personal notification preferences must not suppress mandatory security or critical operational alerts where policy requires delivery.
- Essential service/security notifications and optional marketing consent are different concepts; Admin alert preferences must not be conflated with customer marketing consent.
- Provide loading, saved, unsaved, save-failed and unavailable states.
- Do not claim a preference is synchronized across devices until persistence and session behavior are verified.

## 6. Company profile and support configuration

Potential editable fields, only after approval:

- Legal entity/company name versus public display name (keep distinct).
- Approved logo/brand asset reference.
- Official support email/phone and escalation contact references.
- Public support hours and timezone.
- Approved website/help/privacy-policy links.
- Locale/language availability metadata.

Requirements:
- Validate formats and ownership/verification of contact channels.
- Do not invent or hard-code a personal phone number, email address or emergency contact.
- Clearly show which details are customer-facing and which are internal-only.
- Changes to legal entity details, payment/settlement identity, privacy notices or emergency contacts require their own approval and audit path.
- A company profile edit must not change Firebase project identity, domain ownership, payment provider account, or legal entity records implicitly.
- Emergency contacts and escalation rotas must be separately verified and tested before use; a saved text field is not proof that a contact route works.

## 7. Security and account governance

The Admin UI may expose approved self-service or review workflows, but security enforcement remains server-side.

Required design areas:

- Named individual Admin accounts; no shared human Admin login.
- Account invitation, activation, suspension, deactivation and offboarding states.
- Role and geographic scope assignment with approval and separation of duties.
- Privileged MFA enrollment/status and recovery status, only when supported by the identity provider and approved policy.
- Session expiry, session revocation, sensitive-action re-authentication and recovery policy.
- Access review records and emergency/break-glass access with reason, expiry and after-action review.
- Service-account/CI secret governance metadata, never secret values.
- Security event visibility and audit links for privileged changes.

Rules:
- Login success is not authorization. Enforce active account + canonical role + assigned scope + permitted action + current resource state at the backend.
- Do not equate Super Admin with Central Admin, Founder or Finance.
- No self-granting roles, self-approval, or client-side privileged writes.
- Do not let the Settings screen change security rules, IAM, production secrets or deployment permissions through a generic key/value editor.
- Passwords, PINs, OTPs, tokens, API keys and service-account credentials must never be displayed, copied into logs, or requested through support.
- Recovery must verify identity and must not bypass role/scope checks.
- High-risk access changes must be attributable and auditable.

All exact roles, MFA requirements, session durations, review intervals and recovery rules remain pending approval in POL-021 and Team 01 mapping.

## 8. Notifications and communication configuration

- Distinguish Admin operational alerts from Customer/Walker notification delivery and from optional marketing preferences.
- Channel availability (in-app, push, email, SMS, phone) must reflect actual provider configuration and approval; do not show a channel as active merely because a toggle exists.
- Template configuration must include template ID/version, category, language, owner, approval status, allowed variables and effective status.
- Essential service/security messages must not be disabled by optional marketing preferences.
- A delivery receipt is not proof of reading or understanding.
- Changes to customer-facing templates, language variants, sender identity, channel order, retry limits or emergency communication require policy/provider approval and test evidence.
- Do not expose provider credentials or unrestricted message payloads in Settings.
- Display unavailable/unconfigured/degraded states truthfully. Urgent safety response must not rely solely on push notification delivery.

## 9. Privacy, retention, deletion and backup governance

- Show the approved policy/version and responsible owner; do not present a Draft policy as approved.
- Retention controls must be data-category-specific and based on an approved schedule. No duration is specified by this document.
- Deletion controls must identify requester, verified authority, scope, approval, legal-hold check, execution status and post-action verification.
- A deletion request is not the same as completed deletion.
- Backup and vendor copies must be considered; do not claim global deletion until primary stores, storage, indexes, caches, exports, analytics, vendors and backup lifecycle are checked as applicable.
- Legal holds must restrict deletion/use according to approved process and have an accountable owner/review.
- Backup configuration status and restore-test evidence must come from the responsible platform/backend source; a UI toggle is not proof of a backup.
- Restrict precise location, identity documents, incident evidence, payment data and audit details to approved roles and purposes.

## 10. Vendor and integration register

For each service, the approved register should capture:

- Vendor/service and business purpose.
- Internal owner and backup owner.
- Environment(s) used.
- Data categories and data location where known.
- Required permissions and service identity.
- Contract, privacy/security review and approval references.
- Cost/renewal terms and support/escalation route.
- Health signal, alert owner, fallback and outage impact.
- Last review, material change history and retirement/offboarding steps.

The Settings UI should show only safe metadata and current verified status. Vendor status must not be inferred from a successful sign-in or a configured API key alone. Production activation requires documented due diligence, data-flow/permission review, positive/negative/failure tests and authorized approval.

## 11. Audit, access review and operational evidence

- Every privileged settings change must have a linked audit event with actor, action, target, outcome, timestamp and approved reason/reference.
- Denied privileged changes should be recorded where the trusted security event source supports it.
- Access reviews must identify reviewer, accounts/roles/scopes reviewed, decision, exceptions and completion evidence.
- Emergency access must have expiry and post-use review.
- Settings history must show who changed what and when, without exposing secret values or unnecessary personal data.
- Do not allow ordinary Admins to edit/delete audit history or erase their own change evidence.
- Security, privacy, vendor and backup reviews should link to source evidence and current status; a checklist tick without evidence is not a verification.

## 12. UI states and accessibility

Every settings section must support:

- Loading and initial configuration unavailable.
- Read-only / insufficient permission.
- Draft or pending approval.
- Unsaved changes and validation errors.
- Save in progress, confirmed save, conflict and save failure.
- Provider unavailable/degraded where applicable.
- Masked/hidden sensitive values with safe reveal only if explicitly approved.
- Clear distinction between personal preference, company configuration and privileged governance.

Additional requirements:
- Confirm destructive or high-impact changes with a concise explanation and required reason.
- Do not use confirmation dialogs as a substitute for backend authorization.
- Provide keyboard and screen-reader labels, adequate contrast, responsive mobile layout and accessible error messages.
- Avoid a generic unrestricted “advanced settings” JSON editor.

## 13. Planned acceptance checklist — NOT EXECUTED

1. A personal preference change affects only the signed-in Admin.
2. Personal language preference persists only after backend confirmation.
3. Display timezone does not alter authoritative timestamps or financial date basis.
4. Essential security/critical alerts cannot be disabled through optional marketing controls.
5. Company-wide settings require the approved role and scope.
6. Unapproved users cannot change legal/company identity or customer-facing support details.
7. A privileged setting cannot be changed by direct client/database write.
8. Role grant/revoke and geographic scope changes require approved workflow and audit evidence.
9. No user can grant themselves a role or approve their own conflicted request.
10. MFA/session/recovery status is shown only from authoritative identity-provider evidence.
11. Session revocation and sensitive-action re-authentication are enforced server-side where required.
12. No password, OTP, token, private key or service-account secret appears in UI, logs, repository or client bundle.
13. Notification channel status reflects actual provider configuration and test evidence.
14. Customer notification templates are versioned, localized and approved before activation.
15. Customer marketing consent remains separate from essential service/security messages.
16. Retention periods cannot be changed or displayed as approved without an approved schedule.
17. Deletion request, legal hold, execution and verification states remain distinct.
18. Backup status is not reported as successful without independent job evidence; restore is tested separately.
19. Vendor records include owner, purpose, data, permissions, approval and offboarding evidence.
20. Provider outage or stale health status is visible and does not appear healthy by default.
21. Privileged setting changes and denied attempts are audited where supported.
22. Access reviews capture reviewer, scope, decision and exceptions.
23. Read-only, denied, conflict, validation, save-failure and unavailable states are tested.
24. Mobile, keyboard and screen-reader accessibility are verified.
25. CI Static Analysis, full test suite and Flutter Web build are tied to the exact implementation commit.

All checks above are planned. None is marked PASS or executed by this document.

## 14. Dependencies and decisions required

| Dependency | Required decision/evidence | Owner |
|---|---|---|
| Role/security policy | Canonical roles, scope, MFA, session, re-authentication, recovery, review cadence | Founder/policy owner + Team 01 |
| Settings data contract | User/company/environment scope, keys, validation, versioning and persistence | Team 01 |
| Audit contract | Trusted event write/read, change history, denied attempts and access logging | Team 01 |
| Notification governance | Categories, essential vs optional, channels, templates, languages, delivery/retry | Founder/Operations + Team 01 |
| Privacy/retention | Data inventory, retention, legal holds, deletion and backup rules | Privacy owner + Founder/legal/finance |
| Vendor governance | Vendor register, due diligence, cost, permissions, support, exit plan | Service owner + policy approver |
| Backup/DR | Backup evidence, RTO/RPO, restore tests, owners and alerting | Team 01 + Founder |
| Admin UI | Navigation, read/edit states, validation, confirmation and accessibility | Team 02 |

## 15. Implementation sequence after approval

1. Approve POL-021, POL-014, POL-020, POL-032, POL-018 and POL-019 decisions relevant to each setting.
2. Team 01 defines versioned settings, audit and security contracts; verifies server-side role/scope enforcement.
3. Confirm identity-provider capabilities for MFA, sessions, recovery and revocation before designing live controls.
4. Build personal preferences separately from company-wide and privileged governance settings.
5. Implement approval, audit, conflict, rollback and failure states against trusted contracts.
6. Add unit/widget tests, direct authorization negative tests, Emulator integration and provider sandbox tests as relevant.
7. Verify retention, backup, restore and vendor status using real evidence.
8. Run Static Analysis, full test suite and Flutter Web build on the exact implementation commit.
9. Keep PR #51 Draft until policy approvals and evidence are complete.

## 16. Current disposition

- Documentation-only deliverable.
- No Admin runtime/UI changes.
- No API or Firebase integration.
- No Firestore schema/rules/indexes/functions, identity-provider, notification provider, vendor, backup or retention configuration changes.
- No production setting changed.
- No tests, Emulator runs or CI are claimed for this document.
- PR #51 remains Draft and unmerged.

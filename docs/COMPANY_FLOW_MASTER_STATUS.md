# DOJO WALK Company Flow — Master Status

Last updated: 2026-10-17  
Current phase: Audit and shared-contract definition.  
Main principle: one company workflow across Admin, Customer, Partner, Booking, Service Locations, and Firebase security.

## Canonical flow

Company Identity → Admin/Auth & Permissions → Service Locations → Customer & Pets → Partner/Walker → Unified Booking Lifecycle → Support/Communication → Reports/Audit → Backend Security → Tests/Release.

## Step tracker

| Step | Work | Status | Evidence / blocker |
|---|---|---|---|
| 46 | Firestore Rules Emulator tests | User-confirmed PASS | Exact GitHub Actions run ID/link still needs capture; not independently verified in this chat. |
| 47 | Admin auth vs Firestore role-policy audit | Finding documented | AuthGate and AuthService check active status, not role; define policy before fix. |
| 48 | Company Flow and shared-ID architecture baseline | Documented, proposal only | Audit existing schemas before deciding field/collection names or migrations. |
| 49 | Cross-app ID/schema compatibility audit | Pending | Compare Admin, Customer, Partner, and Firebase repos with exact code evidence. |
| 50 | Unified booking status contract | Pending | Inspect current booking models/rules in all apps before proposing changes. |
| 51 | Emergency reassignment/backup walker lifecycle | Pending | Define operational policy and audit current implementation. |
| 52 | Admin joining and role-scoped access | Pending | Requires approved role/permission matrix and matching Firestore Rules tests. |
| — | Official LGD row-level reconciliation and verified geographic boundaries | Blocked/pending | No production location import or activation until resolved. |
| — | Production rules deployment state | Unknown | Workflow configuration alone does not prove deployed rules revision. |

## Safety gates

- No production Firestore writes, location imports, service activations, or rules deployments without explicit approval.
- Never call a CI run PASS without inspecting its result or clearly marking it user-confirmed.
- Preserve PR #6 until data, geometry, authorization, and integration gates are resolved.
- Audit existing schemas before adding canonical companyId fields or migrating records.


## Step 49 — Cross-app ID & Booking Schema audit (2026-10-17)

- [x] Confirmed Customer, Admin, and Partner code paths all use the shared top-level bookings collection.
- [x] Recorded observed booking fields and the current Firestore document ID / embedded bookingId pattern.
- [x] Found a status vocabulary/filter risk: Partner writes pending/accepted/picked_up/walking/completed while Admin filters include Walker Assigned/Walker Accepted/Walk In Progress.
- [x] Recorded that the inspected Admin walker-action service checks active super_admin in its transaction; broader UI/Rules alignment remains open.
- [ ] Full audit of all booking writes, assignment/cancellation/reassignment paths, rules, indexes, and server functions remains pending.
- [ ] Company ID contract is not established; do not add a companyId field or migrate records until all repos are audited.
- [ ] Define canonical booking statuses and transition rules, then add Emulator-backed tests before coordinated code changes.
- [ ] No code/rules/index/production changes. Partial audit only, not a full compatibility sign-off.
- Report: [Step 49 ID & Schema Audit](COMPANY_FLOW_STEP_49_ID_SCHEMA_AUDIT.md)

# DOJO WALK Company Flow — Step 48

Date: 2026-10-17  
Status: Architecture baseline drafted — implementation not yet audited end-to-end.

Purpose: Keep Customer, Partner, Admin, Booking, Service Locations, and security within one coherent company workflow rather than isolated modules.

## Canonical company flow

1. Company Identity — establish one canonical company document/ID for DOJO WALK. Do not generate unrelated company IDs separately inside Admin, Customer, Partner, and Booking apps.
2. Admin Flow — authentication and role/permission checks, company profile and settings, Service Location management, and audit trail.
3. Service Locations — Country → State/UT → District/City → Area/Sub-district → optional Locality/Village. Only verified boundaries may be activated; official LGD reconciliation and authoritative boundary checks remain pending.
4. Customer Flow — login/profile → pets → saved address → booking request.
5. Partner/Walker Flow — login/onboarding and document review → work-zone eligibility → assignment offer → accept/reject → pickup → live walk → completion.
6. Unified Booking Flow — one shared Booking ID and agreed status contract across Admin, Customer, and Partner. Booking creation → assignment → acceptance → pickup → live walk → completion/cancellation/support. Emergency reassignment and backup walker logic must be audited before implementation is claimed complete.
7. Backend & Security — Firestore Rules, role permissions, company scoping, location scoping, trusted state transitions, and audit records. Client UI visibility is not a substitute for server-side authorization.
8. Testing & Release Gates — cross-app ID/schema compatibility tests, Emulator-backed authorization and booking lifecycle tests, and exact CI run URLs/IDs. No production activation/import/deployment until required audits pass.

## Shared ID and record contract

- Company ID: canonical business/tenant reference. Exact collection and field names must be checked against existing Firebase schema before code changes.
- Booking ID: same identifier across Admin, Customer, Partner, support, and operations for one booking.
- User/Customer ID: Firebase Auth UID should remain the identity key where the existing schema already uses it.
- Walker/Partner ID: map consistently to authenticated partner identity; do not invent a second identity key without schema audit.
- Service Location IDs: preserve parent links and hierarchy; do not rely on display names as identifiers.
- Audit metadata: privileged changes should record actor, timestamp, action, and affected record using trusted/server-validated values where required.

## Cross-company / tenant isolation

Even if DOJO WALK is currently operated as one company, company ownership should not be bolted onto individual apps independently. Before adding a companyId field, audit existing schemas, Firestore Rules, indexes, and all three app repositories. Any field migration/backfill must be separately planned and tested; do not bulk-write production records as part of this architecture note.

## Five tracked workstreams

1. Master status/steps: maintain a central step tracker and evidence links.
2. Cross-app IDs: audit Company, User, Walker, Booking, and Service Location identifiers across Admin/Customer/Partner.
3. Emergency reassignment: define when and how a booking can be reassigned and who is notified.
4. Unified booking operations: align lifecycle statuses and allowed transitions across apps.
5. Admin joining/permissions: define onboarding, active status, roles, scoped access, and rules/tests.

## Immediate next sequence

1. Audit current Company/Profile/Settings models and Firestore collections before creating any schema.
2. Audit ID and status usage across dojo-admin, dojo-walk-customer, dojo-partner, and dojo-firebase.
3. Produce a compatibility table with exact file/collection/field evidence.
4. Resolve schema conflicts before changing production-facing code.
5. Add Emulator/CI tests for approved contracts, then implement one controlled change at a time.

## Safety

No new Firestore collection or field is declared final by this document. No code/security rules changed. No production writes, imports, activations, or deployments. Existing Service Location official-data reconciliation and authoritative boundary verification remain blockers.

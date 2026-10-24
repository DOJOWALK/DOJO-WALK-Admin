# DOJO WALK — Target Company Flow and Implementation Roadmap

Date: 2026-10-24  
Status: **Planning contract only** — current Admin app, deployed Firestore Rules, Firebase data, and production behavior are intentionally left unchanged.

## 1. Instruction and safety boundary

The current Admin app and Firestore setup are the existing baseline. Do not replace, migrate, deploy, merge, or modify production behavior just to make the target model look complete. Prepare the target architecture and implementation in review branches, with tests and compatibility steps, then ask for approval at the release gates.

No production accounts, roles, rules, documents, bookings, walkers, or location records are changed by this document.

## 2. Company operating hierarchy

**Founder / CEO → Central Admin → Area Manager → Supervisor → Walker / Partner**

Customer remains a separate app and customer-facing flow.

### Authority interpretation

- **Founder / CEO:** final company authority; approves company-wide policies, pricing/discount limits, coupon rules, payout/refund/cancellation exceptions, service-area launch approvals, and appointments/suspensions of Central Admin. Every high-risk action must record actor, target, reason, timestamp, and audit event.
- **Central Admin:** manages day-to-day company operations, location setup, booking operations, walker verification, customer support, reconciliation, and Area Manager assignments within Founder-approved policy. Cannot exercise Founder-reserved powers or grant itself Founder authority.
- **Area Manager:** manages only explicitly assigned Area(s) and their verified descendants. Handles local bookings, walkers, attendance/availability, complaints, and escalation. Cannot access unrelated Areas or expand its own scope.
- **Supervisor:** operational reporting line under an Area Manager. Supervisor handles only tasks and records explicitly assigned to them within the relevant Area. This is an operational level in the company hierarchy; do not silently grant it global Admin permissions. Its exact UI permissions and whether it needs a distinct authenticated role must be decided and tested before implementation.
- **Walker / Partner:** uses the Partner app; sees only their own onboarding, availability, assigned walks, and permitted walk records.
- **Customer:** uses the Customer app; sees only their own profile, pets, addresses, bookings, payments and permitted support interactions.

## 3. Admin app structure to prepare

Keep one Admin app with role-appropriate navigation; do not build separate Admin apps for each management level.

1. **Founder Control Center** — company-wide overview and Founder-only approvals/settings.
2. **Central Admin dashboard** — operational overview and permitted management actions.
3. **Area Manager dashboard** — assigned-Area-only operational view.
4. **Supervisor work queue** — assigned tasks and Area-bounded records, subject to a separately reviewed permission contract.
5. **Shared modules** — Dashboard, Bookings, Walkers/Partners, Service Location, Live Operations, Support/Complaints, Coupons/Payments as allowed by role.

The UI may hide unavailable actions, but UI visibility is never the security boundary. Firestore Rules and every privileged backend callable must independently enforce role and data scope.

## 4. Required authorization contract

- Default deny; explicit module + action + data-scope permissions.
- The target company roles are Founder/CEO, Central Admin and Area Manager. Supervisor is not automatically treated as a global Admin role; settle its least-privilege role model before coding.
- Never silently convert existing `super_admin` users into Founder or Central Admin. Keep the current legacy gate until a reviewed, tested migration is approved.
- Role grants, revocations, Area assignments and privileged changes must be server-owned and audited. Users cannot grant themselves roles or scopes.
- Area access is based on canonical service-location IDs and verified ancestry, not free-text `area`, `zone`, city, or PIN alone.
- Revocation must take effect in Rules and backend callables; stale UI state is not authority.
- Founder-only actions must be denied to Central Admin and all lower levels even if they call an API directly.

## 5. Dependency order — prepare in this order

### Phase A — Admin baseline and UI
- Preserve the current app and current production behavior.
- Finish reviewing Dashboard, Add Location and Live Operations screens against the target hierarchy.
- Mark every action with its intended role and scope.
- Wire loading, empty, error and permission-denied states; do not present mock data as live data.
- Run build and existing tests on the exact review commit.

### Phase B — Firebase authorization contract
- Inventory legacy `admin_users/{uid}`, current Rules, and each privileged callable.
- Design the server-owned canonical membership/role and Area-assignment model.
- Test self-elevation denial, role revocation, cross-Area denial, Founder-only action denial and audit events in emulators.
- Keep legacy authorization active until the coordinated compatibility plan is approved; no one-repository role flip.

### Phase C — Trusted location-to-booking link
- Customer currently writes booking documents directly from `booking_confirmation_screen.dart`; preserve compatibility while designing the migration.
- Verify the saved customer address schema and whether it contains a canonical verified Locality reference.
- Design trusted booking creation that derives Area server-side from verified address/location ancestry. Do not trust client-submitted Area ID, price, status, walker assignment or payment status.
- Migrate Customer to the callable with retry/idempotency handling before removing the old direct-write path.
- Do not expose unresolved legacy bookings to Area Managers; reconcile ambiguous records explicitly.

### Phase D — Walker and Supervisor scope
- Inventory existing walker location fields and assignment data.
- Introduce reviewed, server-owned canonical Area assignments; do not infer permission from free-text location fields.
- Define Supervisor's exact task permissions and assigned scope.
- Dry-run backfills, report ambiguous records, manually reconcile uncertain assignments, and audit migration batches.

### Phase E — Release gates
- Emulator tests pass for Rules and Functions on the exact commit.
- Admin, Customer, Partner and Firebase contracts are compatible.
- Staged deployment and post-deploy checks are documented.
- Founder/CEO approves high-risk role/policy changes and first service-area launch.
- Only then request explicit approval to merge/deploy. Never delete branches containing unmerged work.

## 6. Acceptance checklist

- [ ] Existing production Admin login and Firestore behavior remain unchanged until approved cutover.
- [ ] Founder/CEO can perform Founder-reserved actions; lower roles cannot.
- [ ] Central Admin has operational access without Founder authority.
- [ ] Area Manager sees only assigned Areas and permitted descendants.
- [ ] Supervisor is limited to explicitly assigned work and scope.
- [ ] Walker/Partner and Customer data remain tenant/owner-scoped.
- [ ] No self-grant or client-controlled role/Area assignment.
- [ ] Booking Area is derived from trusted verified location data.
- [ ] Ambiguous legacy bookings/walker assignments are quarantined for reconciliation, not guessed.
- [ ] Rules + callable emulator tests, build, and integration tests pass on the exact release candidate.
- [ ] Production deploy/merge is separately approved and verified.

## 7. Current status

This file records the target flow and dependency order only. It does **not** mean the role system, Supervisor permissions, trusted booking callable, Area Manager scope, production Rules, or migration are implemented. Continue with review-branch documentation and source checks while preserving the current production setup.


## 8. Verified source-review findings — 2026-10-24

These findings are source-review evidence, not production deployment verification:

1. **Legacy Admin identity gate remains:** `lib/core/auth/admin_identity.dart` currently allows entry only when `isActive == true` and `role == 'super_admin'`. This is a UI gate, not a replacement for Firestore Rules or callable authorization. Do not switch it to target roles until membership schema, role grants, scope checks, compatibility, and emulator tests are ready together.
2. **Service Location writes use trusted callable:** the reviewed Add Location save path routes named-location saves through `saveServiceLocationWithNameIndex`; new locations are intended to remain inactive until their required review/verified-boundary conditions are satisfied. Boundary drafts and import metadata have separate paths and need their own rules/permission review.
3. **Hierarchy mismatch remains a blocker:** the current Admin/Firebase location model has historically represented City directly under State (with District/City not yet separated into the target canonical chain). The requested State → District → City → Area → Locality model needs a coordinated Admin + callable + Rules + import contract; a UI-only dropdown change is insufficient.
4. **Booking authorization migration is not ready:** the Customer app's reviewed confirmation screen writes booking documents directly to Firestore and supplies a pickup address ID/map. The canonical saved-address schema and verified Locality linkage are not yet confirmed. Do not change production Rules to require a server-derived Area until a trusted booking-creation path and coordinated Customer migration are tested.
5. **Live Operations is not yet a verified live feed:** Dashboard embeds the Live Operations screen, and the UI has a My Location affordance. Walker-nearby/live-feed information must remain explicitly unknown or pending until trusted location feeds, consent, freshness, scope checks, and backend actions are verified.

### Review-commit CI evidence

For permission-matrix commit `78f085663656b250bfee797a423557f7763abbac`, the following GitHub Actions checks completed successfully:

- Service Location Geometry Tests — run `40102760422` (#694).
- Admin Web Build Check (No Deploy) — run `40102760408` (#856).
- Admin Main Full Validation (No Deploy) — run `40102760396` (#177).

These results validate that commit's CI checks only; they do not prove production deployment, complete role authorization, or that later commits have passed CI.

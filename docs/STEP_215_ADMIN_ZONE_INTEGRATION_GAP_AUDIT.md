# STEP 215 — Admin Zone Integration Gap Audit

**Date:** 2026-10-27  
**Status:** Audit findings only — no production code changed  
**Scope:** Compare the current Admin default branch with the proposed Firebase Zone workflow in Firebase PR #39.

## Executive finding

The current Admin Service Location UI and boundary service still implement the legacy City/Area/Locality model. They are not yet a complete client for the Zone-only workflow specified by Firebase PR #39. Do not merge or deploy the backend Zone workflow on the assumption that the current Admin UI can operate it end to end.

## Evidence reviewed

- Admin default-branch `lib/features/service_location/widgets/add_location_dialog.dart`
- Admin default-branch `lib/features/service_location/services/service_location_boundary_service.dart`
- Firebase PR #39 `functions/src/index.ts` and `docs/zone-approval-workflow-contract.md`
- Firebase PR #39 `firestore.rules`

This is a source review. No local Flutter build, emulator test, or production operation was run as part of this audit.

## Confirmed gaps

### 1. Location form is legacy
The Add Location dialog exposes Country, State, District, City, Area/Sub-district, and Locality/Village. The approved Zone hierarchy is State/UT → District → City → Zone, with no Locality dropdown. The Admin form needs a Zone-specific flow rather than exposing the legacy hierarchy as service-area setup.

### 2. Boundary service rejects Zone
The current Admin boundary service supports only `city` and `area` as boundary location types. It rejects `zone`. It must be deliberately updated for Zone boundary draft, verification, revision, and review lifecycle; simply changing the dropdown label is insufficient.

### 3. Legacy activation path remains a separate contract
The Firebase PR #39 contract has Zone-specific callables and fields, including:
- `saveServiceLocationWithNameIndex`
- `reviewServiceLocationBoundary`
- `submitServiceZoneForFounderReview`
- `decideServiceZoneFounderApproval`
- `activateServiceZone`
- `requestServiceZoneDeactivation`
- `setServiceLocationStatus`
- `suspendServiceZoneForEmergency`

The Admin client must explicitly call these functions with their exact payloads and handle the returned workflow states. Existing City/Area activation logic is not evidence that the Zone callables are wired.

### 4. Role boundaries must be reflected in UI and server calls
- Central Admin: create/edit Zone drafts, manage boundaries, submit for Founder review, execute activation/deactivation only after required approval.
- Founder/CEO: sole business approver for approval decisions.
- Technical Super Admin: technical/read access only; must not act as Central Admin or Founder by role substitution.
- Emergency suspension: Central Admin only, with mandatory reason and severity.

Hiding a button is not a security boundary; backend callable authorization and Firestore Rules remain authoritative.

### 5. Emergency notification delivery is incomplete
The backend contract records a durable Founder inbox notification for emergency suspension. Push/email delivery is not configured by that callable. The Admin implementation should display inbox items and clearly distinguish a queued inbox notification from a delivered push/email alert.

## Required implementation sequence

1. Define Zone models and callable request/response contracts from the Firebase PR #39 implementation.
2. Replace the legacy Add Location service-area flow with State/UT → District → City → Zone.
3. Add Zone boundary editing/review with verified polygon and City containment checks.
4. Add Central Admin submission and Founder review screens with revision/hash-aware stale-approval errors.
5. Add activation, deactivation request/approval/execution, emergency suspension, and reactivation states.
6. Add role-specific UI while retaining server-side authorization as the security control.
7. Add Admin unit/widget tests for all workflow states and negative authorization cases.
8. Add emulator-backed integration tests covering the Admin-to-callable contract.
9. Run formatting, analyze, unit/widget tests, Web build, and relevant emulator/CI tests on the exact final commit.
10. Keep all PRs Draft/unmerged until independent review and acceptance. No production deployment is authorized by this audit.

## Acceptance checklist

- [ ] Only State/UT → District → City → Zone appears in the service-area creation flow.
- [ ] Zone is the only service activation unit.
- [ ] Zone boundary service accepts Zone and rejects unsupported legacy service-area types in the Zone workflow.
- [ ] Central Admin can create/edit and submit a Zone draft.
- [ ] Founder-only decisions cannot be performed by Central Admin or technical Super Admin.
- [ ] Stale revision or boundary hash is surfaced as a recoverable review error.
- [ ] Activation is unavailable until current Founder approval and verified boundaries pass server checks.
- [ ] Deactivation follows Central Admin request → Founder approval → Central Admin execution.
- [ ] Emergency suspension requires reason/severity and presents the queued Founder inbox notification state honestly.
- [ ] Reactivation requires a fresh Founder decision and a separate activation action.
- [ ] Legacy City/Area controls cannot bypass Zone workflow.
- [ ] CI and emulator checks pass on the exact final commit SHA.

## Safety decision

**Do not merge or deploy on the basis of this audit alone.** This document records integration gaps; it does not claim that the Admin implementation is fixed or that end-to-end tests pass.

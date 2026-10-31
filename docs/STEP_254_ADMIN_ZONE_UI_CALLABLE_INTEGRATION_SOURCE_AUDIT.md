# Step 254 — Admin Zone UI → Callable Integration Source Audit

**Date:** 2026-10-31  
**Repository:** `DOJOWALK/DOJO-WALK-Admin`  
**Branch:** `integration/zone-functions-emulator-pinned`  
**Admin head reviewed:** `22ea2dc2449e05dde57b009b360c03577f41fa3b`  
**Firebase contract reviewed read-only at:** `04acc1bb11b38326fba4cf22d3a70553ff50c625`  
**Scope:** Source and contract audit only. No Firebase files were changed. No emulator E2E test was executed in this step.

## 1. Result

**The Admin Zone UI is not yet connected to the Zone workflow service.** The service class contains callable methods, but the inspected screens are explicitly UI-only prototypes with example data and disabled actions. Therefore Admin UI → Firebase Callable HTTP E2E remains **NOT VERIFIED**.

## 2. Admin source findings

### Existing client service
`lib/features/service_location/services/service_zone_workflow_service.dart`

- Uses `FirebaseFunctions.instanceFor(region: 'asia-south1')`.
- Uses `httpsCallable(name).call(payload)`, i.e. the FlutterFire callable client path.
- Provides wrappers for save, submit, boundary review, Founder decision, activation, deactivation, emergency suspension and reactivation.
- Reads `service_zones` through Firestore snapshots.
- No injected service dependency or callable invocation is visible in the inspected UI prototypes.

### UI screens inspected
- `add_zone_screen.dart`: explicitly UI-only; example hierarchy catalog; polygon stays in local memory; Save Draft / Submit remain disabled; no service import or callable invocation.
- `boundary_review_screen.dart`: explicitly UI-only; illustrative rows; no live boundary read/review action.
- `zone_approval_queue_screen.dart`: explicitly UI-only; illustrative queue; no live request or Founder decision action.
- `zone_details_screen.dart`: explicitly UI-only; example values passed from directory; lifecycle actions disabled.
- `suspended_zones_screen.dart`: explicitly UI-only; local example rows; no live status mutation.
- `zone_directory_screen.dart`: local example records and prototype filters; no live service subscription observed.

Existing service unit test `test/features/service_location/service_zone_workflow_service_test.dart` tests only `ServiceZoneRecord.fromMap`; it does not invoke any callable.

## 3. Firebase callable contract comparison (read-only)

All reviewed functions use region `asia-south1`.

| Admin method | Callable | Payload shape | Backend role / gate |
|---|---|---|---|
| `saveDraft` | `saveServiceLocationWithNameIndex` | `locationType: zone`, optional `locationId`, `payload: {stateId,districtId,cityId,name}` | Active `central_admin` for Zone writes |
| `submitForFounderReview` | `submitServiceZoneForFounderReview` | `{zoneId}` | Active `central_admin`; requires current verified boundary |
| `reviewBoundary` | `reviewServiceLocationBoundary` | `{boundaryId, decision: verified|rejected, notes}` | Active `central_admin`; notes required (1–2000 chars) |
| `decideFounderApproval` | `decideServiceZoneFounderApproval` | `{zoneId, decision, notes}` | Active `founder`; decision/state/revision/hash must match |
| `activate` | `activateServiceZone` | `{zoneId}` | Active `central_admin`; requires Founder approval for exact revision and verified boundary hash |
| `requestDeactivation` | `requestServiceZoneDeactivation` | `{zoneId, notes}` | Active `central_admin`; current active Zone |
| `deactivate` | `setServiceLocationStatus` | `{locationType: zone, locationId: zoneId, isActive: false}` | Active `central_admin`; backend additionally checks Founder-approved current revision/hash |
| `emergencySuspend` | `suspendServiceZoneForEmergency` | `{zoneId, reason, severity}` | Active `central_admin`; reason and SEV-1..SEV-4 required |
| `requestReactivation` | `requestServiceZoneReactivation` | `{zoneId, reason}` | Active `central_admin`; requires suspended Zone and verified boundary |

### Contract risks to preserve in implementation

1. Founder decision is a separate authority: `founder` is required by the callable. A `super_admin` must not be treated as Founder.
2. Boundary review is a Central Admin action and requires a non-empty note. The UI must not imply that map preview or local polygon shape validation is server verification.
3. Zone activation requires the current Founder-approved revision and boundary hash. A generic status toggle must not be used for activation.
4. Normal deactivation is a two-stage flow: Central Admin submits the request, Founder approves the exact revision/hash, then Central Admin invokes the status callable.
5. Emergency suspension is a separate immediate safety path; reactivation requires a fresh Founder decision.
6. Zone save payload must use the canonical State → District → City parent IDs and must not send activation or boundary-verification fields.

## 4. Integration blockers

- No production UI screen currently constructs or calls `ServiceZoneWorkflowService`.
- No Admin Zone callable integration test exists in `integration_test/`.
- Current workflow's real FlutterFire integration test covers Walker service only; it does not exercise Zone callable HTTP requests.
- Current Zone service unit test only tests the read-model parser.
- Existing Add Zone UI uses placeholder hierarchy values; it cannot safely submit real backend IDs until connected to the approved catalog.
- Boundary review UI has no live boundary document/evidence loading and no authenticated review action.
- Approval queue has no live request query or Founder-only decision action.

## 5. Next implementation sequence

1. Add focused service-level emulator integration coverage for Zone callables using the existing pinned emulator workflow; use a dedicated named Firebase app and `useFunctionsEmulator` with the Functions emulator host/port. Do not mock `httpsCallable`.
2. Verify unauthenticated and wrong-role requests are rejected by the actual callable HTTP endpoint.
3. Verify a Central Admin can create an inactive Zone draft only when the canonical parent fixtures exist; verify no partial document/index writes on failure.
4. Verify boundary review, submission, Founder decision and activation gates with exact fixture revision/hash and required roles.
5. Verify deactivation request → Founder approval → status callable, plus emergency suspension and reactivation gates.
6. Only after service-level callable coverage passes, wire the UI screens to the service with role-aware controls, live Firestore read models and real catalog data.
7. Add widget/integration coverage for the actual UI route and action path. Preserve all existing prototype safety labels until the live path is proven.

## 6. Safety and status

- Firebase repository: read-only inspection only; no commit or modification.
- PR #52: remains open and draft; do not merge.
- PR #51: unchanged.
- Main branch: unchanged.
- No deployment or production project access was used.
- No E2E PASS claim is made.

**Outcome: SOURCE AUDIT COMPLETE; UI CONNECTION AND CALLABLE E2E ARE STILL BLOCKED / NOT VERIFIED.**

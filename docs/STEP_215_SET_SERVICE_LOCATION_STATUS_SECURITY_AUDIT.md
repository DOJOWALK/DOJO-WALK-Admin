# Step 215 — setServiceLocationStatus Security Audit

Date: 2026-10-18

## Scope
Audited the trusted-location callable implementation against the Admin client call sites and the feature-branch Firestore Rules. This is a read-only source audit. No code changes were made in Firebase, no deployment was triggered, and no PR was merged.

## Sources inspected
- Firebase `functions/src/index.ts`, branch `feature/trusted-location-activation`, blob SHA `ff234380a82be6daa0430702bd5a222f8776c0c7`
- Firebase `firestore.rules`, same branch, blob SHA `5d179e99def9c66e402596e54bd9d667e654131b`
- Admin `lib/features/service_location/services/service_location_service.dart`, branch `step-119-boundary-geometry`, blob SHA `a0d4643fd16198f895c2cce56f0942b4ec1b9041`

## Results
1. **Request shape matches.** Admin sends `locationType`, `locationId`, and boolean `isActive`; the callable validates all three and restricts the location type to Country, State, City, Area, or Locality.
2. **Authorization is server-side.** The callable requires Firebase authentication and an active `admin_users/{uid}` record whose role is exactly `super_admin`. It checks the admin again inside the transaction to detect a role/status change during validation.
3. **City/Area cannot bypass boundary activation.** Attempts to activate City or Area through this generic status callable are rejected; the dedicated `activateServiceLocation` callable is required. Admin calls that dedicated callable for activation and uses this status callable for deactivation.
4. **Parent/child invariants are checked.** Activation requires an active parent. Locality activation verifies persisted Country → State → City → Area ancestry and matching IDs. Deactivation is blocked when active children/descendants remain, including explicit Country/State descendant checks.
5. **Concurrent hierarchy protection is implemented.** The callable updates `activationGuardAt` on the target and relevant ancestor records in the transaction, helping serialize activation against ancestor deactivation. Rules prevent ordinary client updates from changing the status fields directly; status transitions are expected to go through the trusted callable.
6. **No direct client status-write bypass was found in inspected location Rules.** Country/State updates require `isActive` to remain unchanged; City/Area/Locality updates similarly require `isServiceActive` to remain unchanged. Deletes are denied for these location records.
7. **Remaining verification is test-based.** This source review does not prove the latest PR head's emulator tests pass now. Current CI results should be checked, particularly negative tests for inactive/mismatched parents, non-super-admin callers, attempts to activate City/Area via the generic callable, active-child deactivation, and concurrent parent/child status changes.

## Conclusion
The inspected callable and Admin request contract are compatible, with the main security invariants enforced server-side. This is not approval to deploy: the trusted-location feature branch and Admin integration still require reviewed merge sequencing, current CI confirmation, and production Rules-version verification.

## Next step
Audit field-by-field direct-write payloads for Countries, States, Cities, Areas, Localities, name indexes, import records, and boundary drafts against Rules allowlists. Check current emulator CI evidence before any release recommendation.

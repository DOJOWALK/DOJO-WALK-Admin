# DOJO WALK Location Master — Step 91
## Locality Status Transition Hardening
Date: 2026-10-17

### Scope
Closed the Step 90 gap that allowed direct client writes to `service_localities.isServiceActive` and could race Area deactivation.

### Changes made
- Extended Firebase callable `setServiceLocationStatus` to accept `locationType: locality`.
- Locality activation now checks that Country, State, City, and Area all exist and are active, and verifies the saved parent IDs match the full hierarchy.
- Locality activation writes ancestor guard fields for Country, State, City, and Area in the same Firestore transaction. This conflicts with concurrent ancestor deactivation transactions and forces a retry/revalidation.
- Locality deactivation is also handled by the trusted callable and written to the status audit collection.
- Firestore Rules now require a Locality to be created inactive and prevent direct client changes to its service-active status.
- Admin's `setLocalityServiceStatus` now delegates to the callable. Saving a new Locality starts it inactive; editing a Locality preserves its existing activation state instead of trying to flip it through a direct client write.
- Added Rules Emulator coverage for direct Locality status-flip rejection and already-active Locality creation rejection.
- Added callable Emulator coverage for full Locality ancestry validation and the concurrent Area-deactivation/Locality-activation race.

### Validation
- [x] Firebase callable/geometry build and Emulator tests passed on commit `fbe97da47681dbe3516405b0315a1d68168cb622`: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39026189293
- [x] Firestore Rules Emulator tests passed on the same commit: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39026189233
- [x] Admin analysis passed in run `39026222473`, but unit tests exposed two tests still expecting client-side Locality activation checks; those tests were updated to verify trusted-backend delegation.
- [ ] Admin Flutter validation rerun `39026320960` is in progress on commit `60894fa037595c916e818ea78fa4948ef2a5158b`: https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39026320960. Final Step 91 PASS depends on this result.
- [!] No production deployment or production Firestore write was performed.

### Result
The Firebase Rules and backend race tests pass. Admin-side CI is pending; do not treat Step 91 as fully validated until that run completes. Official LGD row-level reconciliation and authoritative contiguous boundary verification remain separate release gates.

### Next
Step 92 — audit location create/edit/reparent paths and verify that active descendants cannot be made inconsistent through non-status edits.


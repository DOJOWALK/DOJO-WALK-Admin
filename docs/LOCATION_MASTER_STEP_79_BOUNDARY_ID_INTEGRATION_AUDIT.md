# DOJO WALK Location Master — Step 79: Boundary ID Integration Audit

Date: 2026-10-17  
Status: Audit finding confirmed in inspected source; fix not yet applied.

## Scope
Inspected the Admin Service Location boundary save/verification path and the Firebase activation contract on the current working branches. This is a source-code audit, not a live Firestore reproduction.

## Evidence
- Admin branch: `restore/india-location-reference-data`
- `lib/features/service_location/screens/service_location_screen.dart`: `saveBoundary` awaits `_boundaryService.saveDraft(boundary)` but does not retain the returned boundary ID.
- `lib/features/service_location/services/service_location_boundary_service.dart`: `saveDraft` persists a pending boundary and returns its document ID.
- The `verifyBoundary` transaction updates the boundary document's `verificationStatus`, `verifiedBy`, `verifiedAt`, notes and timestamp. In the inspected transaction, it does not update the owning City/Area document's `verifiedBoundaryId`.
- Admin `service_location_service.dart` has a helper that can find verified boundaries by `locationId` and `locationType`; the activation callable, however, requires the location document to already contain `verifiedBoundaryId` and loads that exact boundary document.
- Area verification checks the parent City document's `verifiedBoundaryId`, so the parent reference must remain trustworthy.

## Finding
There is an integration gap in the inspected Admin boundary verification path: verification does not visibly bind the newly verified boundary ID back to the owning City/Area location document. This can leave the activation callable without the required reference. The issue is source-evidence confirmed; runtime failure has not been reproduced against live Firestore.

## Safe fix plan
1. During verification, transactionally read the boundary and owning location document.
2. Confirm the boundary's location ID/type matches the owner and ensure the boundary is still pending.
3. Verify parent containment and parent boundary reference for Areas.
4. Mark the boundary verified and write its exact document ID to the owner's `verifiedBoundaryId` in the same transaction.
5. Ensure replacement/rejection paths cannot leave a stale verified reference. Do not automatically activate a location during verification.
6. Add regression tests for City and Area binding, wrong owner/type, missing owner, rejected/pending states, and activation using the saved reference.
7. Run Admin Flutter validation and Firebase Emulator tests/CI. Keep production activation blocked until all release gates pass.

## Current release gates
- [x] Admin/Firebase callable name, region and argument contract match in source.
- [x] Boundary ID integration gap documented with source evidence.
- [ ] Apply fix and add regression tests.
- [ ] Run Admin analyze/tests/Web build and Firebase Emulator tests/CI.
- [ ] Obtain current checksum-verifiable official LGD export and complete row-level reconciliation.
- [ ] Verify authoritative contiguous City/Area polygons.
- [ ] Confirm deployment revision before any production use.
- [ ] No production import, activation, deployment, or merge performed as part of this audit.

## Next
Step 80 — implement the transactional verified-boundary reference binding and tests, then validate on a non-production/emulator path.

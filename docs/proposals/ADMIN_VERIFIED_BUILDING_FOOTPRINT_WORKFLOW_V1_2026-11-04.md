# DOJO WALK — Admin Verified Building Footprint Workflow v1 (Proposal)

**Status:** Proposal only — no runtime implementation or Firestore schema is approved by this document.
**Date:** 2026-11-04
**Decision owner:** Founder / CEO
**Related:** Firebase PR #80 (Zone → Booking integration contract); Firebase PR #71 (Zone lifecycle)

## 1. Purpose

Provide a controlled way for DOJO WALK Central Admin to create, review and verify the outline of a building associated with a saved customer pickup address. Booking may use a verified building footprint to apply the Founder-approved Zone rule:

- Calculate the share of the **entire verified building footprint** intersecting each eligible Zone.
- Select a Zone only when exactly one eligible Zone contains strictly more than 50% of the footprint.
- If no strict majority, exact tie, invalid geometry, missing verified footprint, overlapping eligible Zone polygons or numerical ambiguity occurs, require Admin review and do not confirm the booking.

A saved pickup GPS point is not a building footprint and cannot establish the majority-of-house result.

## 2. Existing Admin capability audit

The current Admin code already has:
- `ServiceBoundaryEditor`: Google Map polygon drawing, Undo, Clear, Fit Boundary, coordinate return and basic polygon validation.
- `ServiceBoundaryDialog`: source metadata and pending-boundary submission.
- `ServiceLocationBoundary`: a service-location boundary model in `service_location_boundaries`.
- Existing model validation currently permits only `city` and `area` location types; it explicitly does not model a customer building footprint.

**Recommendation:** Reuse the map interaction pattern and geometry validation ideas, but create a separate Building Footprint feature/model/workflow. Do not store house footprints as City/Zone service boundaries, do not overload `locationType`, and do not change Zone lifecycle semantics.

## 3. Proposed Admin workflow

### Step A — Open a footprint review case
1. Central Admin opens a restricted **Address Footprint Review** queue.
2. A case is created only for an existing saved address selected through a permitted support/operations workflow.
3. Admin sees the minimum address context needed to identify the building. Do not expose unrelated customer profile or pet data.
4. The case is tagged with the address owner UID and address ID server-side; never accept owner UID from an Admin client payload as authority.

### Step B — Draw or import the building outline
1. Open the map at the saved pickup coordinate; show the point as a locator, not as the footprint itself.
2. Admin draws the exterior building footprint as a closed polygon, with Undo, Clear, Fit, vertex count and area preview.
3. For apartment complexes, outline the individual building structure containing the unit, not the whole society boundary. If the exact building cannot be identified, stop and request more evidence.
4. An import workflow may be supported later for authoritative cadastral/GIS GeoJSON, with source metadata and deterministic coordinate normalization.
5. Do not treat customer-drawn geometry, the pickup pin, a radius or an unverified map trace as trusted evidence.
6. Before using any third-party imagery as a tracing source, confirm its terms permit the intended derived geometry and storage. Prefer permitted authoritative GIS/cadastral data or verified field-survey evidence.

### Step C — Record provenance and submit for review
Required proposed metadata:
- `sourceType`: `government_gis`, `government_cadastral`, `field_survey`, or `permitted_manual_map_trace`.
- `sourceName` and `sourceReference` (or evidence reference).
- `capturedBy`, `capturedAt`, `createdAt`.
- `addressId` and server-bound `ownerUid`.
- `geometryFormat`, canonical coordinate order, geometry hash and vertex count.
- Optional review notes; no sensitive documents in free-text notes.

Submission creates a **pending** footprint version only. It does not make the footprint usable for booking.

### Step D — Independent verification
1. A reviewer with explicit footprint-review permission receives an assigned case.
2. The submitter cannot verify their own footprint.
3. Reviewer checks that the polygon is the correct individual building, follows its exterior outline, matches the saved pickup location/building identity, has acceptable source evidence, and is not obviously shifted, incomplete or self-intersecting.
4. Reviewer may approve or reject with a required reason.
5. Approval creates an immutable verified version with reviewer UID, timestamp, source evidence reference, canonical geometry hash and version.
6. Any geometry edit after approval creates a new pending version; it must not silently mutate the verified version.

**Important:** Admin approval confirms the footprint evidence and geometry under DOJO WALK's review process. It does not claim government cadastral certification unless the source itself is an authoritative government record.

## 4. Proposed UI states

- `not_requested`
- `draft`
- `pending_review`
- `verified`
- `rejected`
- `stale` (saved address changed, source evidence invalidated, or the verified building association needs re-check)
- `superseded` (a newer version is active)

The UI must show the active version, prior versions, submitter, reviewer, evidence source, timestamps and review reason. A pending/rejected/stale/superseded version must never be used by Booking.

## 5. Proposed data model — not yet approved

Suggested server-owned collection: `building_footprints/{footprintId}` or a versioned subcollection beneath an address record. The final path must be chosen after Rules/index review.

Suggested fields:
- `schemaVersion`
- `footprintId`
- `ownerUid` (server-bound)
- `addressId` (server-bound)
- `geometry` (canonical polygon; not a client-authored trusted value)
- `geometryHash`
- `geometryVersion`
- `verificationStatus`
- `sourceType`, `sourceName`, `sourceReference`
- `submittedBy`, `submittedAt`, `reviewedBy`, `reviewedAt`, `reviewNotes`
- `createdAt`, `updatedAt`
- `isCurrent` or an explicit current-version reference maintained transactionally

Do not persist duplicate customer PII, pet data, phone numbers or unnecessary address text in the footprint record. Prefer references to the existing saved address.

### Trust and access boundary
- Admin UI submits a draft through an authenticated server operation; it must not write verified status directly.
- Server verifies active Admin role/permission and assignment before review.
- Customer and Partner clients cannot create, update, approve, query or enumerate footprint records.
- Booking backend reads the verified current footprint by the authenticated customer's owned address reference and validates its hash/version before resolution.
- Walker/Partner receives only the service task data needed to perform the walk; no building polygon or review evidence.
- Audit every create, submit, review, reject, supersede and address-reassociation event.
- A changed pickup address or a moved/replaced building invalidates the prior association until re-reviewed.

## 6. Majority calculation contract

For a verified footprint polygon (F) and the set of currently eligible Zone polygons (Z_i):

`share_i = area(F ∩ Z_i) / area(F)`

- The denominator is the entire building footprint, not only the part covered by Zones.
- A Zone qualifies only if `share_i > 0.5`.
- Exactly one Zone must qualify.
- Eligible Zone polygons must not overlap within the footprint; overlap is a conflict requiring review.
- Exact 50/50, no majority, invalid geometry, zero-area intersection, unsupported geometry, missing footprint or numerical uncertainty → Admin review required; no booking/task writes.
- A pickup point may be used as a locator and as a conservative fallback only when strictly inside exactly one eligible Zone and away from boundaries. This fallback must be labelled as point-based coverage and must not be represented as majority-of-house resolution.

Geometry must be computed on the server using a suitable geospatial library and a documented area model/projection appropriate to the local service area. Do not calculate area by raw latitude/longitude degree-squared arithmetic. Define precision, tolerance and rounding before enabling the resolver.

## 7. Synthetic Emulator acceptance plan

Use only synthetic addresses, synthetic users, synthetic polygons and a Firebase demo project. Tests must not use production Firebase credentials or production customer data.

### Authorization and ownership
1. Unauthenticated Admin draft submission is denied.
2. Inactive Admin is denied.
3. Active Central Admin with footprint-create permission can create a draft.
4. Admin without footprint-create permission is denied.
5. Reviewer without an active exact case assignment cannot review.
6. Submitter cannot review their own footprint.
7. Customer client cannot write a footprint.
8. Partner client cannot read/list footprint geometry.
9. User A cannot attach User B's address to a footprint.
10. Client-supplied `ownerUid`, verification status, reviewer UID or geometry hash is ignored/rejected.

### Geometry and provenance
11. Fewer than three distinct vertices is rejected.
12. Invalid latitude/longitude, NaN, infinity and out-of-range coordinates are rejected.
13. Self-intersecting, zero-area, repeated-edge and malformed polygons are rejected.
14. Missing source type/name/reference/evidence is rejected.
15. Unsupported or unapproved source type is rejected.
16. Geometry hash mismatch is rejected.
17. A valid synthetic building polygon can be submitted as pending.
18. Pending, rejected, stale and superseded footprints are never returned as trusted current footprints.

### Review lifecycle and consistency
19. Reviewer approval records reviewer UID, timestamp, evidence reference, version and hash.
20. Rejection requires a reason and does not activate the footprint.
21. Editing an approved footprint creates a new pending version; old verified version is not silently overwritten.
22. Two concurrent submissions cannot both become current verified versions.
23. Address reassociation or address-coordinate change invalidates the old association.
24. Replaying the same idempotency key and payload returns the same outcome; changed payload with same key is rejected.
25. Review against a stale version/hash is rejected.
26. Audit record is created for each successful state transition.

### Zone-majority resolver (synthetic geometry fixtures)
27. Footprint 70% in Zone A / 30% in Zone B resolves to Zone A.
28. Footprint 51% / 49% resolves to the 51% Zone.
29. Exact 50% / 50% returns Admin review required.
30. Footprint 49% / 49% with 2% outside service coverage returns no majority.
31. Footprint 60% in Zone A and 40% outside all eligible Zones resolves to A.
32. Overlapping eligible Zone polygons within the footprint return conflict; no selection.
33. Invalid/degenerate footprint returns Admin review required.
34. Missing verified footprint does not pretend the saved GPS point is a majority result.
35. Zone activation/deactivation or boundary revision race forces re-resolution before booking commit.
36. A changed footprint hash/version between resolution and commit rejects the commit.
37. A tie or near-tie inside configured numerical tolerance returns Admin review required.
38. No qualifying eligible Zone returns no service coverage; no booking/task writes.

### Required invariants
- No unverified footprint can influence booking eligibility.
- No client-provided Zone ID can override server geometry resolution.
- No denied/ambiguous result creates a Booking, Walk Task, payment capture or assignment.
- The resolver result records the Zone ID/revision/boundary hash, footprint ID/version/hash, area ratios, resolver version and resolution timestamp for audit.
- Every test must assert both the returned outcome and the absence of forbidden writes.

## 8. Implementation sequence

1. Founder reviews this proposal and confirms source/evidence policy and reviewer authority.
2. Finalize the Firestore schema/path, Rules, indexes and server operations.
3. Implement pure geometry helpers with deterministic unit tests, including the area/projection/tolerance decision.
4. Implement Firestore Emulator fixtures for ownership, roles, versioning, review and forbidden client access.
5. Implement Admin UI using the existing map-editor interaction pattern but a separate Building Footprint domain model.
6. Run all 38 synthetic acceptance cases against the demo Firestore Emulator; publish exact CI run/job evidence.
7. Only after all required tests pass, integrate verified footprint lookup into Booking Zone resolver.
8. Keep all PRs Draft/unmerged until reviewed; no production migration/deployment as part of this proposal.

## 9. Explicit non-goals

- No automatic footprint extraction from imagery.
- No customer self-approval.
- No radius-based Zone choice.
- No using society boundary as a substitute for an individual building footprint.
- No exposing building polygons to Partner/Walker or Customer apps.
- No modifying the existing Zone lifecycle approval process.
- No merging, deploying, migrating or writing production records.

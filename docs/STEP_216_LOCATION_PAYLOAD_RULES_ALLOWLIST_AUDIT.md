# Step 216 — Direct-write Payload and Firestore Rules Allowlist Audit

Date: 2026-10-18

## Scope and source revisions
Read-only comparison of Admin direct-write payloads with the trusted-location Firebase feature-branch Rules. No application or Rules code was changed, no import was run, and no deployment or merge occurred.

- Admin service: `lib/features/service_location/services/service_location_service.dart`, branch `step-119-boundary-geometry`, blob `a0d4643fd16198f895c2cce56f0942b4ec1b9041`
- Admin boundary service: `lib/features/service_location/services/service_location_boundary_service.dart`, branch `step-119-boundary-geometry`, blob `b3291cf5df8663365bffbc479ab298680fdf2e1f`
- Firebase Rules: `firestore.rules`, branch `feature/trusted-location-activation`, blob `5d179e99def9c66e402596e54bd9d667e654131b`

## Collection-by-collection findings

### 1. Countries — broadly aligned
Admin writes name, code, isActive, createdAt (on create), updatedAt; Rules allow those fields only on create and restrict update to name/code/status/updatedAt. Client-side status change is explicitly required to leave isActive unchanged, and deletion is denied. Activation is delegated to the callable. This aligns with the reviewed payload shape.

### 2. States — broadly aligned
Admin writes countryId, name, isActive and timestamps. Rules restrict fields, validate parent Country and require new records to start inactive. Updates cannot change countryId or status, and deletes are denied. Status transitions use the callable.

### 3. Cities — compatible shape; protected activation path
Admin serializes countryId/stateId/name/verifiedBoundaryId/isServiceActive and legacy/compatibility fields (state, country, boundary, boundarySource, boundaryVerified), with timestamps supplied by the shared transaction helper. Rules allow this documented field set, validate parent links and require create-time inactive status. Direct updates cannot change isServiceActive and enforce parent immutability; City activation uses the trusted boundary callable.

### 4. Areas — compatible shape; protected activation path
Admin serializes countryId/stateId/cityId/name/verifiedBoundaryId/isServiceActive and boundary compatibility fields. Rules allow the corresponding fields, validate Country/State/City ancestry, require new records to start inactive, and prevent direct client status changes or parent reparenting. Area activation is delegated to the trusted boundary callable.

### 5. Localities — broadly aligned
Admin writes countryId/stateId/cityId/areaId/name/pincode/isServiceActive and compatibility boundary fields. Rules allow these fields, validate the full parent chain and require inactive creation. Direct client status changes and parent reparenting are blocked; status transitions use the callable. A locality-specific polygon is not required by the current design.

### 6. Name indexes — significant Rules hardening candidate
Admin transaction writes fields `collectionPath`, `documentId`, normalized `name`, `parentIds`, and `updatedAt`; it may update/delete old index documents when a name changes. The Rules currently say only `allow create, update, delete: if isAdmin()` with no field allowlist, schema validation, or consistency check against the referenced location document. This is broader than necessary: a signed-in admin allowed by `isAdmin()` can tamper with indexes, potentially causing false duplicate-name blocks or undermining uniqueness bookkeeping. Recommend a dedicated validator for index shape/ID/target consistency and a carefully designed delete rule that still supports legitimate name changes.

### 7. Import audit records — create-only, but enum/size validation is weak
Admin creates `source`, `fileName`, `status`, `importedBy`, `importedAt`, and `verificationStatus`; it refuses to overwrite an existing record. Rules match the field list, bind importedBy to request.auth.uid, require importedAt == request.time, and deny update/delete. However, status and verificationStatus are only checked as strings; source/fileName/status lengths and allowed enum values are not constrained in Rules. Consider strict allowed values and reasonable length limits. Client-side checks are not a substitute for Rules validation.

### 8. Boundary drafts — payload is designed to match; test Rules against actual transactions
Admin draft save writes locationId, locationType, points, sourceType, sourceName, sourceReference, verificationStatus=pending, verifiedBy=null, verifiedAt=null, verificationNotes=null, updatedAt and (on create) createdAt. Resubmission writes pending status, clears verification metadata and updates updatedAt. Review/verification is routed through `reviewServiceLocationBoundary` callable rather than a direct client write. Rules delegate create/update to `validBoundaryCreate()` and `validBoundaryDraftUpdate()`, and deny deletion of verified records. The helper predicates must still be covered by emulator tests for the exact create, rejected→pending resubmission, and attempted verified-record tampering paths; this static comparison alone is not a test run.

## Risk summary
- **Priority hardening candidate:** `service_location_name_indexes` rules are broad `isAdmin()` writes with no schema/target checks.
- **Validation gap:** import status/verificationStatus accept arbitrary strings in Rules.
- **No obvious payload allowlist mismatch identified** for the five location collections or the documented boundary draft writes in the inspected source revisions.
- **Not release clearance:** latest emulator/CI status and production Rules version were not verified during this step. Keep the feature branch unmerged/un-deployed until these are checked and the index/import Rules concerns are addressed or explicitly accepted.

## Next step
Inspect and run the relevant Firestore Rules emulator tests (including negative cases) and check current CI for the exact feature branch. Then propose a minimal Rules patch for name indexes and import validation; do not deploy without explicit approval.

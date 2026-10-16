# DOJO WALK Location Master — Step 43

Date: 2026-10-17  
Branch: `restore/india-location-reference-data`  
PR: [#6](https://github.com/dojoplatform2026/dojo-admin/pull/6)

## Verification lifecycle guard — CI pending

The boundary verification transaction now enforces parent containment:
- **Area:** requires a valid parent City document and its referenced verified City boundary; Area polygon must be contained by it.
- **Locality:** when a Locality polygon is submitted for verification, requires its parent Area and referenced verified Area boundary; Locality polygon must be contained by it.
- Parent boundary references must point to a verified boundary belonging to the expected parent location and type.
- All required Firestore reads occur before the transaction writes the verified status.

CI: [workflow 38975978339](https://github.com/dojoplatform2026/dojo-admin/actions/runs/38975978339).

## Still pending

- Emulator-backed integration tests for the verification guard.
- Official LGD row-level reconciliation and authoritative polygon source/provenance review.
- Geodesic/antimeridian handling and proof of official boundary accuracy.
- No production import or activation until these gates pass.

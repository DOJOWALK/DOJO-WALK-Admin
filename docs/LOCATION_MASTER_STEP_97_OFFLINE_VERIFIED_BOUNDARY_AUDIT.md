# Step 97 — Offline Verified-Boundary Integrity Checks

Date: 2026-10-17

## Changes

- Extended required snapshot collections from five to six by adding `service_location_boundaries`.
- For active City and Area records, audit now resolves `verifiedBoundaryId` and checks boundary location ID/type, `verificationStatus=verified`, source name/reference, verifier, verification timestamp, minimum three points, finite latitude/longitude ranges, and three distinct points.
- CLI now imports and runs the shared pure audit core, so command-line reports and unit tests exercise the same implementation.
- Added regression tests for missing City boundary and malformed Area boundary metadata/coordinates. Updated synthetic sample and audit scope documentation.

## CI

- Step 96 Rules [39027844599](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39027844599) — PASS.
- Step 96 callable/geometry [39027844595](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39027844595) — PASS.
- Step 97 Rules [39028120030](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39028120030) — PASS.
- Step 97 callable/geometry [39028120018](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39028120018) — PASS.

## Limitations and safety

Basic coordinate/reference checks are not a replacement for the backend Turf polygon validity and Area-within-City geometry checks. They do not establish contiguous authoritative boundaries, provenance truth, fresh official LGD reconciliation, or the health of production records. No production export or scan, source write, import, activation, or deployment was performed.

## Next

Confirm both Step 97 CI runs. For real-data audit, obtain explicit authorization for a complete read-only export; keep the export and report outside Git.

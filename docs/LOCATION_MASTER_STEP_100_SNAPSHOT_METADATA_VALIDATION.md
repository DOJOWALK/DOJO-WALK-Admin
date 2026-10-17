# Step 100 — Snapshot Metadata Format Validation

Date: 2026-10-17

## Changes
- Added checks that export timestamps parse as dates and use an ISO-style timestamp prefix.
- Added checks for unknown collection names and malformed collection-list declarations.
- Declared counts must be non-negative integers matching the observed snapshot counts.
- Added a regression test for an invalid timestamp and unknown collection name.
- Updated Firebase offline audit documentation to explain the new report fields.

## CI
- Step 99 Rules [39028501969](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39028501969) — PASS.
- Step 99 callable/geometry [39028501939](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39028501939) — PASS.
- Initial Step 100 Rules run failed because the timestamp regex was over-escaped; fixed in commit `29c124229afd33e4484729e62a9a4230d7cdd457`.
- Step 100 Rules [39028867035](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39028867035) — PASS.
- Step 100 callable/geometry [39028867024](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39028867024) — PASS.

## Safety / limitations
This is still an offline JSON snapshot audit; no Firebase connection or production read/write was performed. Metadata format checks cannot prove export authenticity or completeness. Fresh official LGD row-level reconciliation and authoritative polygon geometry/containment review remain release gates.

## Next
Step 101: harden malformed collection-list metadata. Use real records only after explicit authorization for a read-only export kept outside Git.

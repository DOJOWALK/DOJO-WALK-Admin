# Step 193 — Legacy Service Status Read Compatibility

Date: 2026-10-19
Branch: `step-119-boundary-geometry`

## Change
- Added a shared status reader for District, City, Area, and Locality models.
- `isServiceActive` remains authoritative whenever the key exists, including an explicit `false`.
- Older documents without `isServiceActive` can still be read from legacy `isActive`.
- Added regression tests for legacy fallback and canonical-inactive precedence across City, Area, and Locality.

## Safety
- Admin source/model compatibility change and tests only; no Firestore records were migrated or written.
- No deployment or merge performed.
- CI results are pending.

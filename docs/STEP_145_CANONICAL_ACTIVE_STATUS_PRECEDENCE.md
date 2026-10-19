# Step 145 — Canonical Active Status Precedence

## Change
Added a regression test covering District, City, Area, and Locality when the trusted `isServiceActive` field is `true` but a stale legacy `isActive` field is `false`.

## Expected contract
When `isServiceActive` exists, it is authoritative. The legacy `isActive` field is only a fallback for older documents where the canonical field is absent.

## Safety
- Test-only change; no Firestore data changed.
- No merge or deployment performed.
- Admin PR #7 remains Draft while CSV write-path, hierarchy, source-data, and Firebase callable deployment gates remain unresolved.
- CI pending.

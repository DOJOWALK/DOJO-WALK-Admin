# Step 242 — Canonical District Status Precedence

Date: 2026-10-19

## Issue
The District model treated a record as active if either `isServiceActive` or legacy `isActive` was true. When the canonical field explicitly said `false` but the legacy field was stale `true`, Admin could display the District as active despite the trusted callable's canonical status.

## Change
- If `isServiceActive` exists, use it as the source of truth, including an explicit `false`.
- Read legacy `isActive` only when the canonical field is absent.
- Added a regression test for canonical inactive + stale legacy active.

## Safety
- Admin source and test only.
- No Firestore writes, import, activation, deployment, merge, or Partner/Customer migration performed.
- Admin PR #7 remains Draft/open.
- CI status must be verified before this step is marked passed.

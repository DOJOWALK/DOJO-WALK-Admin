# Step 187 — Require Explicit District Link During CSV Parent Check

Date: 2026-10-19
Branch: `step-119-boundary-geometry`

## Change
The read-only CSV parent-mapping check now:
- loads existing Service District records;
- matches the CSV District within the selected Service State;
- matches the Service City only when its `districtId` points to that exact District;
- reports legacy same-name Cities with no `districtId` as unresolved instead of silently treating them as a District match.

## Safety
- Preview and parent check remain read-only.
- No CSV import/write, activation, migration, Firebase deployment, PR merge, or Partner/Customer change was performed.
- CI verification is pending.

# Step 198 — Require Complete Sub-District Parent Chain

## Finding
The local-only LGD staging parser already checked that each Sub-District references an existing District and, when present, that its State code matches the District's State. It did not reject a Sub-District row when the State code column/value was missing.

## Change
- Reject Sub-District staging rows with a missing/blank State parent code.
- Added a regression test confirming the staging result fails closed and emits no JSONL output.

## Safety
- Read-only local staging parser only; no Firebase dependency or write path added.
- No import, activation, production data change, deployment, merge, or Partner/Customer change.
- CI verification pending.

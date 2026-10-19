# Step 195 — Admin District Index Parent-Field Contract

## Change
- Extracted the trusted-callable parent-field selection into a pure helper used by `ServiceLocationService`.
- Added regression tests for District-linked City (three parents), legacy City without District (two parents), blank District ID, legacy Area/Locality tuples, and unsupported types.
- The helper does not generate index IDs and does not switch Area/Locality to District-aware tuples; it makes the current payload contract explicit and testable.

## Safety
- Admin-only code and tests on draft branch `step-119-boundary-geometry`.
- Firebase production callable remains unchanged.
- No Firestore records changed; no production scan, migration, deployment, or merge performed.
- CI pending.
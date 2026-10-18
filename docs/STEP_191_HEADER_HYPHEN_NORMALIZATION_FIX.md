# Step 191 — CSV Header Hyphen Normalization Fix

Date: 2026-10-18
Branch: `step-119-boundary-geometry`

## Finding
The normalized-header regression test continued to fail in CI: the test reported `Required column missing: AREA` for a hyphen-separated header. The parser's separator expression was made explicit, using a hexadecimal escape for the hyphen character, so whitespace, underscore, and hyphen separators are removed consistently.

## Change
Parser fix commit: `3650650caf05f978efc80a08b6e117f66bbe21b0`.

## Verification
CI must complete for the latest branch head before this is marked passing. Earlier runs failed at the header normalization test; those failures are not being reported as passed.

## Safety
Parser-only change. No Firestore writes, production import, service activation/deactivation, deployment, schema migration, or PR merge.

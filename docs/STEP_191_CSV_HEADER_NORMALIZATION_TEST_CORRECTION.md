# Step 191 — CSV Header Normalization Test Correction

Date: 2026-10-18
Branch: `step-119-boundary-geometry`

## Finding
CI exposed a bad test assumption: `district_name` normalizes to `districtname`, not `district`, and `City-Name` normalizes to `cityname`, not `city`. The parser correctly requires the normalized required names `state`, `district`, `city`, and `area`.

## Correction
The regression fixture now uses ` STATE `, `dis-trict`, `ci_ty`, and `Area`. These variants normalize to the four required names under the parser's documented rules. No parser behavior or Firestore schema was changed.

Test correction commit: `561bac8f0403c0631195dd214e7d3a8c5c5c86d0`.

## Verification
CI must complete for the current branch head before this test can be marked PASS. Earlier Step 190 checks failed because the original test expected unsupported aliases.

## Safety
Test-only change. No production import, Firebase writes, activation/deactivation, deployment, schema migration, or PR merge.

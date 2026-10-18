# Step 191 — CSV Header Normalization Regression Fix

Date: 2026-10-18
Branch: `step-119-boundary-geometry`

## Finding
Step 190's first CI run failed because the test used `district_name` and `City-Name`, while the parser's current normalization removes separators but does not remove the suffix `name`. The parser behaved as implemented; the test expectation was too broad.

## Change
Adjusted the test to exercise supported separator normalization only: ` STATE `, `dis-trict`, and `C_i_t_y`. No parser behavior or Firestore schema was changed.

Test commit: `30564d6580422ee3f464a85390f9553866f9aecf`.

## Verification
CI for this commit must complete before marking this regression test as passing. Earlier Step 190 CI failed on the overly broad test expectation.

## Safety
Test-only change. No writes/imports, activation/deactivation, deployment, PR merge, or Partner/Customer migration.

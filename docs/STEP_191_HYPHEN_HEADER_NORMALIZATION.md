# Step 191 — Hyphen Header Normalization Coverage

Date: 2026-10-18
Branch: `step-119-boundary-geometry`

## Change
Strengthened the required-header normalization regression test so the Area header uses `A-r-e-a`. Along with the existing ` STATE `, `dis trict`, and `CI_TY` examples, this exercises surrounding whitespace/case, embedded spaces, underscores, and hyphens against the parser's documented separator-removal behavior.

Test change commit: `67318e23d4180682e06878647ed493e60faa9011`.

## Verification
The previous branch head `bc5023f4d765eb7e4484866bf8084f563a851af0` had both `geometry-unit-tests` and `build-web` passing. CI for this Step 191 commit must complete before this new change is marked PASS.

## Safety
Test-only change. No Firestore schema changes, writes, imports, location activation/deactivation, deployment, or Partner/Customer migration. Admin PR #7 remains Draft.

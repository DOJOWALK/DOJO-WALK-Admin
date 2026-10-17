# DOJO WALK Location Master — Step 65: State Master Reconciliation

Audit date: 2026-10-17  
Branch: `restore/india-location-reference-data`

## Purpose
This step does **not** repeat Step 60's source-CSV-to-generated-Dart comparison or Step 64's sub-district parent-reference audit. It checks whether the existing 36-record state/UT Dart master agrees with the 785-record district Dart master, and records the already-known coverage and Census-code flags.

## State master structural results
- State/UT records parsed: 36.
- Unique LGD state codes: 36; duplicate codes: 0.
- Classification: 28 States and 8 Union Territories.
- Nonnumeric LGD state codes: 0.
- Every state/UT LGD code represented in the state master appears in the district master: 36/36.
- State codes present in the district master but missing from the state master: 0.
- Every state/UT has at least one district record in this snapshot.
- State English names match all corresponding district records: 0 mismatches.
- State local-name values match all corresponding district records: 0 mismatches.
- State Census-code values match all corresponding district records: 0 mismatches.
- District records parsed: 785; unique `stateCode + districtCode` pairs: 785; duplicate pairs: 0.

## State Census-code quality flags
The state master preserves the supplied source values rather than correcting them:
- LGD state code 36, Telangana: Census code `00`.
- LGD state code 37, Ladakh: Census code `00`.
- LGD state code 38, The Dadra And Nagar Haveli And Daman And Diu: Census code `NA`.

These are source placeholders/exception values requiring authoritative reference verification before they are used for Census-based joins. Do not convert these values to numbers or infer replacements. Census codes should remain strings to preserve leading zeroes.

## Known cross-file coverage flags carried forward
From Step 64, the district master has 785 state-district pairs, while 783 pairs are represented in the archived sub-district snapshot. These two district pairs have no sub-district row in that snapshot:
- `state_code=19, district_code=315`
- `state_code=27, district_code=482`

This is a coverage difference to investigate, not proof of invalid district records. Step 64 also found one blank sub-district Census code and source sentinel values (`00000`, `000`, `NA`) in Census fields. These remain unresolved source-quality flags.

## Important scope and limitations
- Step 60 already compared all 7,151 archived sub-district CSV rows with the generated Dart records: 7,151 rows/keys on each side, zero missing keys, zero extra keys, zero compared-field differences. That comparison is not repeated here.
- The archived sub-district CSV records `last_updated=2024-10-07`. This audit does not certify that it is the latest official LGD release.
- The state Dart master is documented as deduplicated from the supplied LGD district CSV. Therefore, matching it against that district-derived data demonstrates internal consistency, not independent verification against a separate current official state master.

## Decision
**PASS for internal state-to-district consistency, WITH unresolved source-data flags.**

No raw files or reference records were changed. No production Firebase import, service-location activation, deployment, or PR merge was performed. Before production use, reconcile the archived source against a current official LGD export and resolve the Census-code/coverage flags using authoritative evidence; do not guess-fill missing or placeholder values.

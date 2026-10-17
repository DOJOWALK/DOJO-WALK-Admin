# DOJO WALK Location Master — Step 64: Saved LGD Snapshot Integrity Audit

Audit date: 2026-10-17  
Branch: `restore/india-location-reference-data`

## Outcome
**PASS WITH DATA-QUALITY FLAGS** for the archived snapshot's structural integrity and parent references. This is not a certification that the snapshot is the newest LGD release.

## Files audited
- Sub-district source: `/DOJO WALK Location Master/01_RAW_SOURCE/lgd_subdistricts_source_7151.csv`
  - Bytes: 1,109,638
  - SHA-256: `a5ffe900bea3c802b698a7a8c7a7125acffc273daa7c6e05482be83c4162c9e5`
  - Rows: 7,151; every row has `last_updated=2024-10-07`.
- District source: `/DOJO WALK Location Master/01_RAW_SOURCE/lgd_districts_source_785.csv`
  - Bytes: 89,622
  - SHA-256: `b8901c98350a4057d3371ce14228181e4bb12cc447f847490efee599a0e38b59`
  - Rows: 785.

## Checks that passed
- [x] Parsed all 7,151 sub-district rows using the 13 expected CSV columns.
- [x] No blank values in required administrative identity fields: state code/name, district code/name, sub-district code/name.
- [x] 7,151 unique sub-district codes; zero duplicate sub-district codes.
- [x] 7,151 unique composite keys (`state_code + district_code + subdistrict_code)); zero duplicate composite keys.
- [x] Administrative codes `state_code`, `district_code`, and `subdistrict_code` are all numeric strings; no non-numeric values detected. Preserve them as strings where appropriate rather than normalizing away formatting.
- [x] 36 distinct state codes and 783 distinct district codes / state-district pairs are represented in the sub-district file.
- [x] Every sub-district parent state/district pair exists in the 785-row district master: 0 missing parent pairs.
- [x] State and district English names match the district master for all shared parent pairs: 0 mismatches.
- [x] State-code/name/Census-code mappings and district-code parent/name mappings are internally consistent within the sub-district file.

## Data-quality flags — retain and document, do not silently edit
- [!] `district_name_local`: 198 rows blank/whitespace-only.
- [!] `subdistrict_name_local`: 3,860 rows blank/whitespace-only.
- [!] `subdistrict_census2011_code`: 1 blank value (CSV line 3273, including header).
- [!] `subdistrict_census2011_code`: 1,349 rows contain `00000`; treat as a source value requiring interpretation, not automatically a valid Census code.
- [!] `district_census2011_code`: 132 rows contain `NA` and 1,123 rows contain `000`; preserve the raw values and validate meaning against source documentation before transforming.
- [!] Census codes with leading zeroes occur in the snapshot (for example `08`, `03728`). Treat Census codes as strings to preserve leading zeroes.
- [!] The 785-row district master contains two state-district pairs not represented in this sub-district snapshot: `state_code=19, district_code=315` and `state_code=27, district_code=482`. This is a coverage difference to investigate; the absence of a sub-district row alone does not prove the district record is invalid.
- [!] Source rows are dated 2024-10-07. Current/latest official release reconciliation remains pending.

## Decision
- Keep the original CSV unchanged and preserve its SHA-256 above.
- Do not drop rows or fill blank fields by guessing.
- The prior source↔generated-Dart comparison remains valid for the fields that the Dart model represents.
- Do not import this snapshot into production Firestore, merge PR #6, deploy, or activate real service locations until current-source reconciliation and authoritative contiguous boundary validation are complete.

## Next step — Step 65
Audit the state master against the district and sub-district files, then prepare a single cross-file reconciliation table. Investigate the two districts with no sub-district entries and source-code sentinel values without changing raw data.

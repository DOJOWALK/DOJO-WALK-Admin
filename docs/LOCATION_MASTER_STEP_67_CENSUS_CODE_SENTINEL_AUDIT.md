# DOJO WALK Location Master — Step 67: Census Code Sentinel Audit

Audit date: 2026-10-17  
Branch: `restore/india-location-reference-data`

## Scope
Audited the saved raw district CSV (785 rows) and saved raw sub-district CSV (7,151 rows) for blank and sentinel-like values in Census 2011 code fields. Counts below are source-row counts unless explicitly stated as unique administrative entities. No raw data was changed.

## Results from the 7,151-row sub-district snapshot

| Field | Value | Rows | Distinct affected administrative entities |
|---|---|---:|---:|
| `state_census2011_code` | `00` | 609 | 2 state/UT codes: LGD 36 (Telangana; 594 rows) and LGD 37 (Ladakh; 15 rows) |
| `state_census2011_code` | `NA` | 3 | 1 state/UT: LGD 38 (Dadra and Nagar Haveli and Daman and Diu) |
| `district_census2011_code` | `000` | 1,123 | 125 distinct state-district pairs |
| `district_census2011_code` | `NA` | 132 | 20 distinct state-district pairs |
| `subdistrict_census2011_code` | `00000` | 1,349 | 1,349 distinct sub-district records |
| `subdistrict_census2011_code` | blank | 1 | 1 sub-district record: LGD state 12, district 718, sub-district 6559 (Gepen Circle) |

There are no blank state- or district-Census-code values in the saved sub-district snapshot. The Census code columns also contain normal-looking codes with leading zeroes (for example `08`, `03728`); keep these fields as strings.

## Results from the 785-row district master

- `state_census2011_code`: 35 rows use `00`; 3 rows use `NA`; no blank values.
- `district_census2011_code`: 125 district records use `000`; 20 use `NA`; no blank values.
- These counts are district-master row counts. They are consistent with the corresponding affected state/district identities in the sub-district snapshot; do not add row counts across the two files as if they were separate entities.

## Interpretation and safeguards
- `00`, `000`, `00000`, `NA`, and a blank value are **source values that need verification**, not enough by themselves to establish what the correct Census code should be.
- `00000` and other all-zero values may be source placeholders; this audit does not assert an official semantic definition for them.
- Never parse Census codes as integers, strip leading zeroes, or replace sentinels with guessed codes.
- The LGD administrative identifiers (state/district/sub-district codes) should remain separate from Census 2011 identifiers; do not use an unresolved Census field as the sole key for location identity.
- The archived sub-district snapshot still has `last_updated=2024-10-07`. This audit does not certify it as the latest official release.

## Decision
**PASS for source-field enumeration; UNRESOLVED for authoritative Census-code mapping.** Exact affected row/entity counts have been recorded. No source values were repaired or overwritten.

Next: verify these flagged codes against an authoritative Census 2011 mapping/reference and reconcile with a current official LGD export. If official verification is unavailable, preserve source values and mark them as unresolved. No production Firebase import, service-location activation, deployment, or PR merge was performed.

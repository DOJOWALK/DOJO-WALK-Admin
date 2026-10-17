# DOJO WALK Location Master — Step 68: Official Census Code Reference Check

Audit date: 2026-10-17  
Branch: `restore/india-location-reference-data`

## Official references consulted
1. Office of the Registrar General & Census Commissioner, India, **Census 2011 — Location Code Directory** (catalog reference `PC11_TV_DIR`): https://censusindia.gov.in/nada/index.php/catalog/42648
2. Census of India, **Administrative Atlas of India 2011**: https://www.censusindia.gov.in/census.website/data/atlas
3. Ministry of Panchayati Raj, **Local Government Directory (LGD)**: https://panchayat.gov.in/en/lgd/
4. LGD official download directory (interactive page with CAPTCHA): https://lgdirectory.gov.in/demo/downloadDirectory.do

The Census 2011 catalog describes the location directory as covering state, district, sub-district, village and town units. Its published historical state list uses 2011-era State/UT codes 01–35; the catalog also defines `00` as the country/India code. The Administrative Atlas states that it reflects the administrative setup as of 31 December 2010. Therefore, a post-2011 LGD state/UT should not be assigned a guessed 2011 state code simply to make a join work.

## Code-format findings
The Census coding description states:
- State/UT code: 2 digits.
- District code: 3 digits, beginning at 001.
- Sub-district code: 5 digits, beginning at 00001.
- Leading zeroes are significant and must be preserved.

These format rules mean that all-zero district value `000` and all-zero sub-district value `00000` do not represent ordinary valid assigned district/sub-district codes under the stated numbering conventions. Treat them as unresolved source placeholders/exception values, not as usable Census identities. The official catalog's country code `00` is not a valid state identity. The current files' `NA` values and blank value are not numeric Census location codes.

## Reconciliation against saved snapshot flags
Carried forward from Step 67:
- State Census code `00`: 609 sub-district rows (LGD state 36 Telangana: 594; LGD state 37 Ladakh: 15). The archived state master also uses `00` for Telangana and Ladakh.
- State Census code `NA`: 3 sub-district rows for LGD state 38, the post-2011 combined UT.
- District Census code `000`: 1,123 sub-district rows across 125 state-district pairs.
- District Census code `NA`: 132 sub-district rows across 20 state-district pairs.
- Sub-district Census code `00000`: 1,349 sub-district records.
- One blank sub-district Census code: LGD state 12, district 718, sub-district 6559 (Gepen Circle).

## What is and is not proven
**Supported by official reference formats:** `000` and `00000` are not normal assigned district/sub-district codes; `00` denotes India at country level in the Census directory; the historical Census 2011 administrative setup predates newer State/UT formations.

**Not established from the available evidence:** exact replacement Census codes for current LGD entities, the intended meaning of each `NA`, or whether the blank sub-district Census code should map to a specific 2011 unit. These require an exact authoritative concordance or source-specific clarification. The Census 2011 directory must not be treated as a current LGD master.

## Safe data policy
1. Preserve every raw source value as supplied.
2. Keep Census codes as strings; never trim leading zeroes or convert them to integers.
3. Do not use `00`, `000`, `00000`, `NA`, or blank Census values as join keys for location identity.
4. Use LGD identifiers for current administrative identity; keep Census 2011 identifiers as optional historical cross-reference fields.
5. Do not infer mappings for post-2011 Telangana, Ladakh, or the merged Dadra and Nagar Haveli and Daman and Diu UT without an authoritative concordance.
6. The saved LGD sub-district snapshot has `last_updated=2024-10-07`; a current official export has not yet been obtained in a checksum-verifiable form because the official download workflow requires an interactive CAPTCHA.

## Decision
**PARTIAL PASS — official code formats clarified; exact row-level mappings remain unresolved.** No data values were edited. No raw file changes, production import, service-location activation, deployment, or PR merge occurred.

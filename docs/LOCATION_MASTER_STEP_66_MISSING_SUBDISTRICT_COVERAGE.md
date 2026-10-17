# DOJO WALK Location Master — Step 66: Missing Sub-district Coverage Investigation

Audit date: 2026-10-17  
Branch: `restore/india-location-reference-data`

## Scope
This step follows Step 64/65 and directly inspects the archived raw district and sub-district CSV files. It does not repeat the full Step 60 CSV-to-Dart comparison and does not alter any source data.

## Exact raw-file results
- District master: 785 data rows.
- Sub-district snapshot: 7,151 data rows.
- The district master contains both target district records:
  - `state_code=19`, West Bengal, `district_code=315`, **Kolkata**, Census district code `342`.
  - `state_code=27`, Maharashtra, `district_code=482`, **Mumbai**, Census district code `519`.
- A direct scan of all 7,151 sub-district rows found **zero rows** whose `state_code + district_code` pair is `19 + 315` or `27 + 482`.
- The surrounding district codes are present in the sub-district snapshot: West Bengal has district codes 303–314 and 316–321 (plus later additions), and Maharashtra has 481 and 483–500 (plus 665). This confirms these two pairs are specifically absent, not a simple state-wide omission.

## Interpretation — unresolved, not automatically an error
The saved files prove the two parent districts exist in the district snapshot but have no child sub-district rows in the archived sub-district snapshot. The files alone do **not** establish whether this is an intentional LGD modelling/administrative exception, a source-export omission, or a version mismatch. Do not label either district invalid and do not synthesize child records.

## Required follow-up before production use
1. Obtain a current, authoritative LGD sub-district export or a verifiable official response for Kolkata (state 19 / district 315) and Mumbai (state 27 / district 482).
2. Compare the exact LGD district/sub-district codes and the export's effective/update date.
3. If the official source confirms no child records, document that as an accepted exception. If it supplies child records, preserve the new export separately and regenerate the derived reference data only after a reviewed diff.
4. Keep Census codes as strings and retain the source placeholders/blank values until authoritative mapping evidence is available.

## Decision
**PASS for reproducing the snapshot coverage finding; NOT RESOLVED for explaining the administrative cause.** The missing-child finding is confirmed from the raw CSV, but its reason is not proven.

No raw files or Dart reference records were changed. No production Firebase import, service-location activation, deployment, or PR merge was performed. The latest-official-source reconciliation remains pending because the official download flow has not yet yielded a fresh, checksum-verifiable export.

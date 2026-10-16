# Official LGD Export Reconciliation — Runbook

Status date: 2026-10-17  
Repository branch: `restore/india-location-reference-data`

## Goal

Compare the restored India reference records against a verifiable export from the live Government of India Local Government Directory (LGD). This is a source-validation step; it does not authorize a production import.

## Source hierarchy

1. Prefer a file downloaded directly from the live LGD portal: https://lgdirectory.gov.in/
2. Ministry overview: https://panchayat.gov.in/en/lgd/
3. OGD catalog/resource pages may help discover resources, but the pages reviewed on 2026-10-17 explicitly identified the site as a sandbox/testing environment and warned that data may be incomplete or inaccurate. Do not treat its displayed update dates alone as proof of a current authoritative export.

## Export requirements

Obtain three exports where available:
- State / Union Territory directory
- District directory
- Sub-district directory

For each downloaded file, preserve the original unedited file and record:
- Exact download date/time (IST)
- Page or download URL
- Entity/report name and any selected filters
- Original filename and format
- SHA-256 checksum
- Any date/version printed inside the export

If the portal asks for CAPTCHA, complete it manually in the browser. Do not attempt to bypass the CAPTCHA or substitute a sandbox file without clearly marking it.

## Comparison checklist

For each entity type, compare using LGD codes as identifiers—not names alone.

- Count rows and distinct LGD codes.
- Detect duplicate codes.
- Detect additions and removals relative to the restored snapshot.
- Detect name changes for matching codes.
- For districts, verify each state parent code and parent name.
- For sub-districts, verify each state and district parent code/name.
- Preserve codes as strings where source formats may contain leading zeroes; normalize types deliberately only where the reference model requires it.
- Report unmatched rows separately instead of silently dropping them.
- Review all differences before changing generated Dart files.

## Existing snapshot baseline (not a freshness claim)

| Entity | Existing count | Unique-code check |
|---|---:|---|
| States / UTs | 36 | 36 unique LGD codes |
| Districts | 785 | 785 unique district codes |
| Sub-districts | 7,151 | 7,151 unique sub-district codes |

Internal parent-code/name checks passed for the restored snapshot. That only establishes internal consistency; it does not establish current official completeness. A Ministry annual-report dashboard found during research showed different district/sub-district totals for its reporting point. Those totals are a comparison lead, not enough by themselves to prove the restored data is wrong because the snapshot dates and definitions may differ.

## Acceptance criteria

Do not mark reconciliation complete until:
- All three original exports are available and their source/date/checksums are recorded.
- Counts, duplicate checks, additions/removals, renames, and parent mappings have a reviewed result.
- Every discrepancy is either resolved or explicitly documented as an accepted, explained difference.
- A repeatable validation artifact and report are committed to the branch.
- The reference-data integration tests are added and CI passes.

## Current blocker / next action

The public LGD download page exposes a CAPTCHA-protected report flow. An automated current export has not been obtained in this pass. Next, obtain the three files through the live portal (manual CAPTCHA if prompted), then place the original exports in a review-only location or attach them to the working conversation so they can be reconciled. Until then, current-source reconciliation remains **PENDING**.

## Safety boundary

Do not overwrite the restored Dart data, merge PR #6, import the snapshot into production Firebase, or activate service boundaries based solely on internal consistency or OGD metadata.

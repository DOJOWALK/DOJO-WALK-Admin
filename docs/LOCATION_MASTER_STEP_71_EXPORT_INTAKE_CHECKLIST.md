# DOJO WALK Location Master — Step 71: Official Export Intake & Reconciliation Checklist

Date: 2026-10-17  
Status: READY FOR SOURCE FILE INTAKE; comparison awaits the original export.

## Goal
Make the next comparison reproducible and protect original government data. This step prepares the intake contract; it does not claim a fresh official export has been obtained.

## When the export file is available
1. Upload the original downloaded file here without editing it. Do not rename columns, open-and-resave the file, strip leading zeroes, or remove duplicate-looking rows before archival.
2. Keep one source file per original download. If downloads are state-wise, keep each source file separate and record the selected state/entity for every file.
3. Record source page/portal, download date and time (India time), original filename, file type, reported entity scope, and SHA-256 of the exact uploaded bytes.
4. Record sheet names (for spreadsheets), headers, row count, blank rows, and any preamble/footer lines. Do not assume the first sheet or first row is the data table without inspection.
5. Parse all LGD identifiers as strings. Never convert Census codes to integers because leading zeroes are meaningful.
6. Compare by LGD identity codes and parent chain first; compare names and version/status fields separately. Do not use Census codes as primary identity keys.
7. Produce separate lists for added, removed, renamed, reparented, duplicate-code, blank-code, and sentinel-value records.
8. Reconcile any changed/removed records against official documentation before editing Dart reference files.
9. Recompute generated Dart files only after the record-level diff is reviewed and accepted; retain the original source and checksums in the audit trail.

## Intake manifest template
Fill this in for every raw export:
- Source title/resource:
- Official portal URL:
- Download date/time (IST):
- Original filename:
- File type:
- Entity/scope selected:
- Original byte size:
- SHA-256:
- Sheet name (if spreadsheet):
- Header row / data start row:
- Parsed data row count:
- Known transformations (should be none for the archived original):
- Notes / download limitations:

## Acceptance gates
- [ ] Source provenance and exact downloaded bytes recorded.
- [ ] SHA-256 calculated from the uploaded original.
- [ ] File parses without silently dropping rows or columns.
- [ ] Export scope is clear and sufficiently complete for the intended comparison.
- [ ] Duplicate/missing IDs and parent-child relationships reported.
- [ ] Record-level diff reviewed; unresolved differences explicitly listed.
- [ ] Only after review: update reference data and run tests/CI.

## Explicit exclusions
- Third-party mirrors or catalog update dates alone are not official row-level proof.
- CAPTCHA is not to be bypassed.
- No inferred replacement values for missing Census codes.
- No fabricated Kolkata/Mumbai sub-district rows.
- No production import, activation, deployment, or merge.

## Current baseline to compare against
- State Dart: 36 records.
- District Dart: 785 records.
- Sub-district Dart: 7,151 records.
- Archived sub-district CSV source last_updated: 2024-10-07.
- Existing source-to-generated comparison is already recorded as passing; this intake step does not rerun or invalidate that result.

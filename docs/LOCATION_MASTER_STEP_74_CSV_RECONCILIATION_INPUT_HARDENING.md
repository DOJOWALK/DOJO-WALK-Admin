# Step 74 — LGD CSV reconciliation input hardening

Date: 2026-10-17  
Branch: `restore/india-location-reference-data`

## Change made

Reviewed the existing reconciliation helper against the export-intake checklist. The prior parser accepted duplicate header names (which can silently overwrite values in `csv.DictReader`) and silently ignored extra row fields not represented in the header. Those are unsafe for an authoritative data comparison.

Updated `tool/reconcile_lgd_csv.py` to reject:
- duplicate CSV header names;
- blank header names;
- records with extra fields beyond the declared header.

Existing safeguards remain: missing required columns, empty keys and duplicate keys are rejected. UTF-8 BOM support and string-preserving code values remain supported.

Expanded `tool_tests/test_reconcile_lgd_csv.py` from 3 to 8 tests. Added checks for BOM headers, duplicate headers, blank headers, extra row fields and empty files.

## Validation status

- [x] Change committed to this branch.
- [x] Test cases added for the new parser guards.
- [ ] These new tests have **not yet been run in GitHub Actions**; do not label this step CI-PASS until a workflow confirms it.
- [ ] Fresh official LGD export intake and row-level comparison are still pending.

Commits:
- Parser: `be17d7ae7fca040259f25516a333dc56dc18562d`
- Tests: `32bffb7d90ef3fc28b3ef815716a44102d1e09bb`

## Boundaries / safety

No reference-data rows or generated Dart files were changed. No current-official-data claim is made. No production import, deployment, service-location activation or PR merge was performed.

Next: check the workflow triggered by the test commit and fix any failures before moving to the next data gate.

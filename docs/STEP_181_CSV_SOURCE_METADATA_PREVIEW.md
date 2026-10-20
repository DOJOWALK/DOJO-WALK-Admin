# Step 181 — Preserve Source Metadata in Read-Only CSV Preview

Date: 2026-10-18
Branch: `step-119-boundary-geometry`

## Change made
Updated `LocationCsvRow` with an additive `sourceValues` map that retains every CSV column by its original trimmed header. The existing `values` map remains the same four normalized fields: State, District, City, Area.

This allows optional source fields such as State LGD Code, District LGD Code, and Source Version to remain visible to future preview UI work without silently dropping them.

## Regression test added
The CSV parser test now confirms:
- Existing `values` keys remain exactly State/District/City/Area.
- Optional source-code/version columns are retained in `sourceValues`.
- Code values such as `09` and `0123` remain strings with leading zeroes.
- Preview remains syntax validation only.

## Safety and scope
- No Firebase or production write path added.
- No new collection/schema, activation, deployment, or data import.
- This does not assert that source codes are authoritative or correct; that remains a source/version approval gate.
- Existing CSVs with just the four required columns remain compatible.
- Admin PR #7 remains Draft and unmerged.

## CI status
Latest code/test commit: `2f9210ef49fcc79a7caa91dd3d99708c5a2c4bcc`.
CI has been triggered; inspect the exact commit's build-web and geometry-unit-tests checks before treating this change as validated.

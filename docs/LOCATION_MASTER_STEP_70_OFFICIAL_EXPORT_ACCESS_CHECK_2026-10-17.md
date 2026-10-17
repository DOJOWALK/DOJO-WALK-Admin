# DOJO WALK Location Master — Step 70: Official LGD Export Access Check

Audit date: 2026-10-17  
Status: SOURCE DISCOVERY COMPLETE; ROW-LEVEL RECONCILIATION BLOCKED

## Purpose
Continue the official-source gate after Step 69 without modifying reference data or bypassing portal controls.

## Findings
1. The official OGD page for **LGD Districts** currently displays **Updated On 08/10/2026**. This is source-catalog metadata, not proof that we obtained or validated the underlying current CSV.
2. The official OGD Sub-Districts resource is discoverable, but the surfaced state-hosted copy did not expose a current downloadable file in the checked result. No checksum-verifiable fresh sub-district export was obtained in this step.
3. The official LGD Download Directory offers entity and state-based downloads, including all districts/sub-districts of a state, but presents a CAPTCHA. This audit does not attempt to bypass CAPTCHA or automated access restrictions.
4. The Ministry annual report's historical totals (as of 2025-12-31) are aggregate context only. They cannot identify which individual rows changed and cannot replace a row-level export.
5. Therefore, the existing snapshot dated 2024-10-07 remains the last locally verified source snapshot. Do not relabel it as current.

## Source references
- Official OGD LGD Districts resource: https://data.gov.in/resource/local-government-directory-lgd-districts
- Official LGD Download Directory (interactive CAPTCHA): https://lgdirectory.gov.in/demo/downloadDirectory.do
- Official LGD portal: https://panchayat.gov.in/en/lgd/
- Ministry Annual Report 2025–2026 (historical LGD dashboard, as of 2025-12-31): https://cdnbbsr.s3waas.gov.in/s316026d60ff9b54410b3435b403afd226/uploads/2026/02/20260224563334790.pdf

## Next required input
A person must download the official export through the normal LGD portal/official OGD download flow and upload the resulting raw CSV/XLSX into the project workflow. Preserve the original filename and bytes. Then record:
- download date/time and portal/resource page,
- original filename and file type,
- SHA-256 checksum,
- row/column counts and headers,
- comparison results against the archived source and generated Dart records.

If the official export can only be downloaded per state, keep each untouched original file and document its state/entity selection before combining copies for analysis. Do not silently deduplicate or normalize source values.

## Decision
- No new raw source data was downloaded or verified in this step.
- No Dart reference file was changed.
- No production import, deployment, activation, or PR merge.
- Keep PR #6 open until official row-level reconciliation and geographic boundary validation are complete.

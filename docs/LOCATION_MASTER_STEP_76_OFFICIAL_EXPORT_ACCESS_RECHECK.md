# DOJO WALK Location Master — Step 76: Fresh official LGD export access check

Date: 2026-10-17
Branch: `restore/india-location-reference-data`

## What was checked

- The official OGD LGD Districts resource page reports “Updated On 08/10/2026” and describes the dataset as a monthly-updated district-code dataset.
- The Ministry of Panchayati Raj LGD “Download Directory” page exposes an interactive CAPTCHA as part of the normal report/download flow.
- The OGD metadata date is not itself a downloaded row-level CSV and cannot be used as evidence that our local reference files match the current LGD records.
- The accessible public page did not provide a verifiable fresh sub-district export in this check. No CAPTCHA bypass was attempted.

## Validation pipeline

GitHub Actions run [39014213756](https://github.com/dojoplatform2026/dojo-admin/actions/runs/39014213756), run #354, completed with conclusion `success` on commit `baa05d463e44c1cc3cb3f0be5802709e3fef15a5`. Its `validate` job passed:
- Python LGD CSV reconciliation tests
- Flutter dependency installation
- Dart/Flutter analysis
- Flutter unit tests
- Firestore Emulator persistence smoke test
- Flutter Web release build

This verifies code/tests at that commit only. It does not establish that the saved 2024-10-07 source snapshot is current.

## Result

- CSV validation pipeline: PASS.
- Fresh official row-level reconciliation: BLOCKED pending a normally downloaded, untouched official export.
- Census sentinel-code concordance and Kolkata/Mumbai sub-district coverage: unresolved.
- Authoritative contiguous City/Area boundary verification: unresolved.

## Safe next action

Download the official LGD export through the normal portal workflow and upload the original file here. Then record the original filename, download time/source, byte size and SHA-256, inspect its headers/row count, and run the existing reconciliation tool against the old snapshot. Do not infer or repair codes without authoritative evidence.

No production Firebase import, service-location activation, deployment, or PR #6 merge was performed. PR #6 remains open.

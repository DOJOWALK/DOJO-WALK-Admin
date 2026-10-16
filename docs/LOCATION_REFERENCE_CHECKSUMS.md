# DOJO WALK India Location Reference Files — Integrity Manifest

Checked: 2026-10-16
Library folder: `/DOJO WALK Location Master/02_GENERATED_DART/`

These checksums were calculated from the exact Library files materialized for audit. They can be used to verify that restored repository copies are byte-for-byte identical. The source files have not yet been committed into the repository.

| File | Verified record count | Bytes | SHA-256 |
|---|---:|---:|---|
| `india_states.dart` | 36 | 6,871 | `bb2369850ddb9e78b1fdf0a5a8c1bc5c528d595f84b47d69926e046cfbae8850` |
| `india_districts.dart` | 785 | 215,355 | `d667c7a42b702c9c19215e2f3a41e5a5464112fb82c5d018cb1425b5b17d453e` |
| `india_sub_districts.dart` | 7,151 | 1,830,733 | `b42f4d9641da427b2a950f34ee5d5dd5bc2c2a1b917f46b44ffb878e22a2ea06` |

## Declared APIs

- States: `IndiaState`, `indiaStates`, `searchIndiaStates(...)`
- Districts: `IndiaDistrict`, `indiaDistricts`, `districtsForState(...)`, `searchIndiaDistricts(...)`
- Sub-districts: `IndiaSubDistrict`, `indiaSubDistricts`, `subDistrictsForDistrict(...)`, `subDistrictsForState(...)`, `searchSubDistricts(...)`

## Validation notes

- Counts were verified by counting constructor records in the Dart source, not inferred from filenames.
- The files preserve source code fields as documented in their headers; this manifest does not certify that the underlying source data is the latest LGD release.
- Restore into `lib/data/reference/india_locations/` only after confirming the intended import/API integration. After restore, recompute SHA-256 and compare with this manifest.
- Do not manually rewrite, sample, truncate, or normalize government codes during restoration.
- Flutter analysis/build and UP/NCR validation remain pending.

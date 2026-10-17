# DOJO WALK Location Master — Project Status

Last updated: 2026-10-16

## Current status

- [x] Previous structural audit recorded in the ChatGPT Library.
- [x] Boundary dialog metadata omission fixed in commit `c572371cfd74a9888a66b2e51e7af1e20c627b62`.
- [x] Project file structure documented in `docs/PROJECT_FILE_STRUCTURE.md`.
- [x] Generated Dart reference files located, record counts verified, and SHA-256 integrity manifest committed at `docs/LOCATION_REFERENCE_CHECKSUMS.md`.
- [x] Expected repository paths checked; all three generated reference files are still absent.
- [ ] Restore the exact three generated India reference Dart files into this repository; checksum manifest is ready.
- [ ] Verify all imports and model/API compatibility after restoring the files.
- [ ] Run `flutter pub get` and `flutter build web --release`; record the actual CI/build result.
- [ ] Reconcile reference counts and records against a current official LGD snapshot.
- [ ] Complete UP/NCR targeted review.
- [ ] Verify location boundaries and activation rules in the admin UI.
- [ ] Do not import reference data into production Firebase until the above checks pass.

## Reference data currently in the Library

Folder: `/DOJO WALK Location Master/02_GENERATED_DART/`

| File | Previous audited count | File size | Top-level declaration |
|---|---:|---:|---|
| `india_states.dart` | 36 State/UT records | 6,871 bytes | `IndiaState`, `indiaStates` |
| `india_districts.dart` | 785 district records | 215,355 bytes | `IndiaDistrict`, `indiaDistricts` |
| `india_sub_districts.dart` | 7,151 sub-district records | 1,830,733 bytes | `IndiaSubDistrict`, `indiaSubDistricts` |

These are the previously audited local counts. They are **not** a claim that the records have been reconciled against the latest official LGD export. The source snapshot currently available for sub-districts is dated 2024-10-07, and a fresh official-source reconciliation remains pending.

## Restore and compatibility check

Integrity manifest: [`docs/LOCATION_REFERENCE_CHECKSUMS.md`](LOCATION_REFERENCE_CHECKSUMS.md). It records measured counts, byte sizes, and SHA-256 hashes for the exact Library files. This makes it possible to verify byte-for-byte restoration.

The following expected paths were checked on the default branch and were not found:

- `lib/data/reference/india_locations/india_states.dart`
- `lib/data/reference/india_locations/india_districts.dart`
- `lib/data/reference/india_locations/india_sub_districts.dart`

The generated files were materialized from the Library for inspection. Their top-level names are `IndiaState/indiaStates`, `IndiaDistrict/indiaDistricts`, and `IndiaSubDistrict/indiaSubDistricts`. Repository code search did not return usages of those identifiers, so imports and integration still need an explicit check after restoration. No reference file has been committed back to the repository yet.

Do not recreate the 7,151 records by hand or replace them with sample/partial data. Preserve the exact Library files and official codes when restoring.

## Boundary dialog fix

The dialog supplies `verifiedBy: null` and `verifiedAt: null` when creating a pending boundary. This fixes the missing required constructor arguments in that call site; it does not prove that the entire application builds successfully.

Commit: `c572371cfd74a9888a66b2e51e7af1e20c627b62`

## Next planned step

Restore the exact three generated Dart files from the Library to `lib/data/reference/india_locations/`, confirm no conflicting names/imports, then run formatting, analysis/tests, and the web build. No production Firebase import or boundary activation is authorized by this status note.

## Boundary precision progress — 2026-10-17

### Step 118 (reported by project operator)
- Reported result: City/Area containment synthetic tests passed.
- Reported CI: Geometry & Callable Tests and Firestore Security Rules passed.
- Evidence limitation: the Step 118 run links and commit SHA were not available during this status update, so these results are recorded as operator-reported, not independently verified here.

### Step 119 — Geographic gap / boundary precision
- Status: **PENDING — NOT VERIFIED**.
- Reviewed the current Admin boundary model and boundary service source.
- The model validates coordinate ranges and requires at least three distinct points, but this alone does not prove polygon containment, gap tolerance, polygon topology, or edge-case behavior.
- No Step 119 test run or CI result was retrieved during this update.
- No boundary code was changed as part of this status-only update.
- Required next checks: locate the existing geometry/containment implementation and tests; add focused synthetic cases for tiny gaps, shared edges, just-outside points, duplicate vertices, and invalid coordinates; run the targeted tests and applicable CI; record run URL and commit SHA.

### Step 120 — planned
- Do not start or mark Step 120 PASS until Step 119 has reproducible test evidence.
- After Step 119 passes, test polygon minimum area/degenerate shapes and boundary-edge precision without changing production location data.

### Release safeguards
- Official LGD source reconciliation, authoritative boundary confirmation, Admin web build verification, and production activation remain pending.
- No production Firebase import or service-location activation is authorized by these synthetic tests.

### Step 119 investigation update — 2026-10-17
- Status remains: **BLOCKED / PENDING — no geometry test run verified**.
- Inspected `service_location_service.dart`: activation checks that the City/Area has a verified boundary record, but the reviewed activation path does not compare Area polygon coordinates against the parent City polygon.
- Inspected `service_location_boundary_service.dart` and `service_location_boundary.dart`: validation checks metadata, coordinate ranges and distinct-point count; these checks do not establish polygon containment or detect small geographic gaps.
- Repository code search did not locate an existing polygon-containment implementation or dedicated containment test file. This is a search finding, not proof that no such code exists anywhere in connected repositories.
- **Risk identified:** a boundary marked verified can pass the visible Admin activation gate without a demonstrated parent-polygon containment check. Do not use verification status alone as proof of geographic containment.
- No production code was changed and no tests/build were run in this investigation.
- Next action before Step 120: implement/review a shared geometry validator with synthetic unit tests (fully inside, shared edge, tiny outside gap, duplicate/degenerate vertices, invalid coordinates), wire it into the appropriate trusted validation path, then run tests and Admin web build. If validation is needed against direct/hostile client writes, enforce it in a trusted backend; Firestore Rules cannot reliably implement arbitrary polygon geometry.

### Step 119 — geometry helper draft on review branch (2026-10-17)
- Review branch: `step-119-boundary-geometry`.
- Added `lib/features/service_location/services/service_location_geometry.dart` with coordinate/ring validation, point-in-or-on-polygon checks, child-edge midpoint checks, and proper segment-crossing rejection.
- Added `test/features/service_location/services/service_location_geometry_test.dart` for fully-inside, shared-edge, tiny-outside-gap, duplicate/degenerate vertices, and invalid-coordinate cases.
- Commit with helper: `9e4b1e8a95443c11f0024e4f0310cec8dd57202b`.
- Commit with tests: `5e6cf8767584fa15148048ca7eb8771e87d2dd6b`.
- **Status: DRAFT / NOT RUN / NOT INTEGRATED.** Tests and Flutter Web build have not been run in this environment. The helper is not yet called by the activation service and is not sufficient to claim complete GIS topology validation; additional concave-polygon/edge-case review is required before production use.
- Do not merge or deploy until tests pass, geometry edge cases are reviewed, and the trusted activation path is wired to compare Area boundaries against the verified parent City boundary.

### Step 119 — focused CI added (2026-10-17)
- Added `.github/workflows/service-location-geometry-tests.yml` on the review branch.
- Workflow runs Flutter dependency setup, formatting check, and the focused geometry unit-test file on matching pushes/PRs.
- Workflow file commit: `83be0ea755ca4dd9e0b5347e2c0fc32bc18263cf`.
- CI outcome: **NOT VERIFIED YET**. The presence of a workflow file is not evidence that the run started or passed. No passing run URL has been confirmed.
- Geometry helper remains unintegrated into City/Area activation. Do not merge/deploy or mark Step 119 PASS until the workflow succeeds and parent/child boundary validation is integrated and reviewed.
- Draft review PR opened against `main`: #7 — https://github.com/dojoplatform2026/DOJO-WALK-Admin/pull/7. It is **open, draft, and not merged**.
- After opening the PR, the workflow-run lookup still returned no run; CI remains **pending/unverified**, not PASS.


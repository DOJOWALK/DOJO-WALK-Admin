# Step 232 — Service Location direct-write audit

Date: 2026-10-18
Branch: `step-119-boundary-geometry`

## CI gate
For code commit `158f6351bd071411d949d75d093edb73c266b570`, GitHub Actions reports:
- `build-web`: success (dependency install, complete project analysis, complete test suite, Flutter Web release build)
- `geometry-unit-tests`: success

## Files inspected
- `lib/features/service_location/services/service_location_service.dart`
- `lib/features/service_location/services/service_location_boundary_service.dart`
- `lib/features/service_location/screens/service_location_screen.dart`
- `lib/features/service_location/widgets/add_location_dialog.dart`

## Findings
1. Country, State, City, Area and Locality saves route through the trusted callable `saveServiceLocationWithNameIndex`. No direct named-location writes were found in the inspected service save path.
2. `service_location_imports` still has a direct client write in `saveImport`. It records import metadata only (source, filename, status, signed-in actor, server timestamp and verification status); it does not import country/state/city/area/locality documents or write name indexes. It refuses overwriting an existing import record.
3. Boundary drafts still use client Firestore transactions in `service_location_boundary_service.dart`: save/merge draft, request verification (status reset to pending), and delete a non-verified draft. These are separate from named-location saves and require a matching review of Firestore Rules and role expectations before changing them.
4. Boundary approval/rejection paths use trusted callable review actions; this audit did not change them.
5. The CSV UI explicitly disables import and says it is preview-only. It performs no bulk location writes; a trusted transactional import is not implemented.
6. The Add Location dialog showed no direct Firestore write calls in the inspected file.

## Security decision
Do not tighten Firestore Rules yet. Before doing so, compare the three direct boundary draft operations and import-metadata create against the current Firebase repository Rules and emulator tests. Do not deploy rules, change production data, or activate locations as part of this audit.

## Evidence
- Service source SHA after Step 231: `76a309ddb10d376c6218a921a63c4d811200fa99`
- Boundary service SHA: `b3291cf5df8663365bffbc479ab298680fdf2e1f`
- Screen SHA: `0744bd3cdc657bd0acdd939fe747398fdb8dfb2d`
- Add dialog SHA: `2be1b92c347c0e23449f8c7688eb8513bdae903b`

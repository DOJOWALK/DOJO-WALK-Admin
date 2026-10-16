# DOJO WALK Location Master — Step 36 Status

Date: 2026-10-17  
Branch: `restore/india-location-reference-data`

## Hierarchy safety tests added

- [x] Added `test/service_location_hierarchy_guard_test.dart`.
- [x] Test: an Area cannot be deactivated while an active Locality exists.
- [x] Test: an Area cannot be moved to a different City while child Localities exist.
- [x] Test: saving a Locality is rejected when its supplied City does not match the selected Area's parent chain.
- [x] Tests use `FakeFirebaseFirestore`; no production Firebase data is read or modified.
- [ ] GitHub Actions validation is pending for this commit. Do not mark Step 36 PASS until Python tests, Flutter analyze/tests, Firestore Emulator smoke test, and Flutter Web release build all succeed.

## Remaining safety/data gates

- Parent State/Country deactivation and wrong-parent checks need further coverage.
- Reparenting behavior for all hierarchy levels needs a broader audit.
- Official current LGD export reconciliation remains pending.
- Polygon checks are basic planar geometry validation only; authoritative source, containment, adjacency, and contiguous coverage are not yet proven.
- Keep PR #6 open; no production import, activation, or deployment.

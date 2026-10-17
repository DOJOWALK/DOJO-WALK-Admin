# DOJO WALK Location Master — Step 117
## Offset Polygon Area Stability — PASS

Date: 2026-10-17

- [x] Found a numerical-stability gap: absolute-coordinate shoelace products can cancel for a small polygon far from (0, 0).
- [x] Updated area calculation to translate coordinates relative to the first vertex before summation.
- [x] Added a regression test for a small polygon near 28.6139 latitude, 77.2090 longitude.
- [x] Geometry fix commit: `a97b9730aec1f6bb9d94b8be66dfd80d243dc69a`.
- [x] Test commit: `cb6beb5a949c6f0c35e3718429ef56329661b3de`.
- [x] Firebase Rules CI PASS: [39034649437](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39034649437).
- [x] Firebase Geometry/Callable CI PASS: [39034649439](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39034649439).
- [x] Firebase report: [Step 117](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/blob/feature/trusted-location-activation/docs/LOCATION_MASTER_STEP_117_OFFSET_POLYGON_AREA_STABILITY.md).
- [!] Synthetic tests only. Official LGD reconciliation, authoritative GIS boundary review and production data audit remain pending. No production export/live scan, write, import, activation or deployment.

Next: Step 118 — review numerical stability and boundary semantics in area-within-city containment checks.

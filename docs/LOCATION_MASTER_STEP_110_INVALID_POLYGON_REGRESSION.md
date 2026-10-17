# DOJO WALK Location Master — Step 110
## Invalid Polygon Regression Coverage — PASS
Date: 2026-10-17

- [x] Added synthetic geometry tests rejecting a self-intersecting bow-tie ring.
- [x] Added synthetic geometry test rejecting collinear/zero-area boundary points.
- [x] Initial CI exposed that the Turf validity helper alone did not reject both malformed test rings; added deterministic shoelace-area and non-adjacent segment-intersection checks before Turf validation.
- [x] Geometry fix commit: `86437086137d509d138bbfd57b0aa52dbb84bdc0`.
- [x] Firebase Firestore Rules CI PASS: [39031799876](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39031799876).
- [x] Firebase Callable/Geometry CI PASS: [39031799961](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39031799961).
- [!] Synthetic geometry tests only. They do not establish real-world boundary authority, contiguous coverage, official LGD alignment, or production behavior. No production export/live scan, write, import, activation or deployment.

Next: Step 111 — inspect trusted-location callable validation for additional concrete coverage gaps; continue to treat real-world authoritative boundary validation and official LGD reconciliation as separate release gates.

Last updated: 2026-10-17.

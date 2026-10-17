# DOJO WALK Location Master — Step 105
## Strict Snapshot Timestamp Calendar/Time Validation — CI Pending
Date: 2026-10-17

- [x] Step 104 timezone requirement verified by Rules CI [39029509094](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39029509094) and callable/geometry CI [39029509102](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39029509102) — PASS.
- [x] Auditor now checks actual calendar day/month, leap years, hour/minute/second ranges, and timezone offset ranges after the ISO timestamp shape check.
- [x] Added regression tests rejecting 30 February and hour 25 while accepting a valid leap-day timestamp.
- [x] Updated Firebase offline audit documentation.
- [ ] Step 105 CI pending; do not mark PASS until current Rules and callable/geometry workflows finish successfully.
- [!] Offline-only validation. No production export/live scan, write, import, activation, or deployment. Timestamp checks do not authenticate the export. Official current LGD reconciliation and authoritative polygon validity/containment remain release gates.

Next: verify Step 105 CI; if green, continue with another offline audit coverage gap.

Last updated: 2026-10-17.

# DOJO WALK Location Master — Step 109
## Fractional Timestamp Precision Boundaries — CI Pending
Date: 2026-10-17

- [x] Added regression cases accepting fractional seconds with one digit and nine digits.
- [x] Added a negative case rejecting a decimal point without following fractional digits.
- [x] Firebase test commit: `0928fac721b299bbe0c307fb2762799c7f04e8ba`.
- [x] Firebase audit-doc commit: `6d345056bdd6e01cd2e98da1ad131cab88af3ee3`.
- [ ] Firestore Rules and Callable/Geometry CI must be checked against the latest test/documentation commit before PASS.
- [!] Offline-only parser tests; no production export/live scan, write, import, activation or deployment. Official LGD reconciliation and authoritative polygon validation remain release gates.

Next: verify Step 109 CI; fix any regression before continuing.

Last updated: 2026-10-17.

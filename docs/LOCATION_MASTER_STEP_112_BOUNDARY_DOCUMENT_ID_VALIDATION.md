# DOJO WALK Location Master — Step 112
## Boundary Document ID Validation — CI Pending
Date: 2026-10-17

- [x] City/Area activation now validates a boundary ID against a conservative allowed-character and length policy before building a Firestore document path.
- [x] Parent City boundary IDs receive the same validation.
- [x] Emulator regression test checks a slash-containing boundary reference is rejected with `failed-precondition` and the City stays inactive.
- [x] Callable implementation commit: `e3273a5741ab7b674209bb5c9c1d2fe829675df2`.
- [x] Integration test commit: `a03b49515f3ed844b476c1061a78858403adfc87`.
- [x] Firebase audit documentation commit: `fcba4b2e49d6e63bd4bcb9f0e540f0f192f3ffb0`.
- [ ] Verify Rules and Callable/Geometry CI on the latest audit commit before PASS.
- [!] This is input/path validation only. No production export/live scan, write, import, activation or deployment. Current official LGD reconciliation and authoritative polygon verification remain separate release gates.

Next: verify CI; if green, mark Step 112 PASS and continue callable review.

Last updated: 2026-10-17.

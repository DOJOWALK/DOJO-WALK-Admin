# Step 104 — Explicit Snapshot Timestamp Timezone

Date: 2026-10-17

## Changes
- `exportedAt` now requires an ISO-style timestamp with seconds and an explicit timezone: `Z` or an offset such as `+05:30`.
- Timestamp without timezone is rejected and yields `INCOMPLETE_OR_UNVERIFIED`.
- Regression tests cover rejection without timezone and acceptance with a +05:30 offset.
- Updated offline audit documentation.

## Commits
- Core: `77b129b400b50e0df19c46fefde006725aa17cc3`
- Tests: `bb5520cdecd8b73cfc680f6f8721ba84e3b8aa3a`
- Documentation: `81acb9af53bf2ef8df7925ab2ae4ae2110f467ee`

## CI
PASS. Rules CI [39029509094](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39029509094) and callable/geometry CI [39029509102](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39029509102) passed on the documentation commit. Earlier code/test runs [39029493106](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39029493106), [39029493153](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39029493153), [39029497609](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39029497609), and [39029497684](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39029497684) also passed.

## Safety / limitations
Offline snapshot validation only. No production export, live Firestore scan, source write, import, activation, or deployment was performed. Timestamp format validation does not authenticate the export or prove completeness. Official current LGD reconciliation and authoritative polygon geometry/containment remain release gates.

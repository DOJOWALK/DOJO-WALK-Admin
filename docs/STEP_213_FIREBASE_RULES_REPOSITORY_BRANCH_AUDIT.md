# Step 213 — Firebase Rules Repository and Branch Audit

Date: 2026-10-18

## Scope
Audited the dedicated Firebase repository `dojoplatform2026/DOJO-WALK-Firebase`, including `firestore.rules` on `main`, `feature/trusted-location-activation`, `step-124-callable-boundary-verification`, and `step-138-partner-submission-negative-tests`. This is a source/branch audit only; no merge, deployment, workflow dispatch, or production data changes were performed.

## Repository and branch inventory
- Repository: https://github.com/dojoplatform2026/DOJO-WALK-Firebase
- Default branch: `main`; current branch head observed: `bafe724b628d7a4a79ae2569fdcc49827dca93f7`
- `main` Rules file: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/blob/main/firestore.rules
  - File blob SHA: `86ce54ab89a306be5d94904b409385960185be71`
- `feature/trusted-location-activation` Rules file: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/blob/feature/trusted-location-activation/firestore.rules
  - File blob SHA: `5d179e99def9c66e402596e54bd9d667e654131b`
  - Branch head observed: `80b9df5602d85fbbeb063071711743d7dfb37b6c`
- `step-124-callable-boundary-verification` has the same Rules blob as main (`86ce54ab89a306be5d94904b409385960185be71`).
- `step-138-partner-submission-negative-tests` Rules file blob SHA: `99b8a862b54dfb3a387d59219aa1554480cd4328`; branch head observed: `8d09fca9713799e4695cf7b446d575f1de2d9bb6`.

## Findings
1. Service-location collections and boundary helpers are present in the dedicated Firebase Rules source on main. Main includes explicit match blocks for service countries, states, cities, areas, localities, boundary documents, name indexes, and import audit records.
2. The trusted-location feature branch contains additional hierarchy validation helpers that verify parent-country/state/city/area relationships. The main/step-124 Rules blob does not contain those same parent-validation helper definitions at the same locations; therefore the feature branch contains meaningful security changes not yet present in main.
3. The feature branch has additional protections around verified boundary updates (including keeping verified boundary IDs unchanged during ordinary location updates) and has trusted location callables/integration tests described in draft PR #1.
4. The trusted-location PR remains draft/unmerged at audit time: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/pull/1. The Partner negative-tests PR #5 is also draft/open: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/pull/5.
5. Do not assume feature-branch Rules or tests are deployed to Firebase production. GitHub branch content is source evidence only; production Rules version/history still needs verification in Firebase Console by an authorized project owner.
6. Because the stricter Rules are coordinated with trusted-location callable functions and Admin app changes, do not deploy Rules alone or merge the branches independently without reviewing the documented rollout sequence.

## Safety and next action
No source code was changed in the Firebase repository during this audit. Next, compare the Admin Service Location write payloads against the exact feature-branch Rules and callable request/response schemas, then run/inspect the relevant Emulator tests. Keep all release/deployment actions gated by explicit approval and coordinated rollout.

# DOJO WALK — Step 210: Firebase Rules Deployment Source Audit

## Status
- Result: **Repository deployment path identified; live deployed version still unverified**
- Repository: `dojoplatform2026/DOJO-WALK-Firebase`
- Ref inspected: `main`
- No rules were changed and no deployment was triggered by this audit.

## Findings

### 1. Rules source and Firebase project mapping
- `firebase.json` blob SHA: `0207c3fc808f51c418117f7e1facf13cf1a32b71`
- It maps Firestore rules to `firestore.rules`.
- `.firebaserc` blob SHA: `2316a8fec75b3a753d859fb006b962c1ed629091`
- The default project is `dojo-platform-b68a3`.
- Root `firestore.rules` blob SHA on `main`: `86ce54ab89a306be5d94904b409385960185be71`.

### 2. Deployment workflow
- File: `.github/workflows/deploy-firestore-rules.yml`
- Blob SHA: `60ae10677c94f5456422e170b3aba3898fa24d2f`
- [View workflow](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/blob/main/.github/workflows/deploy-firestore-rules.yml)
- It runs on pushes to `main` that change `firestore.rules`, `firebase.json`, `.firebaserc`, or the deployment workflow itself; it also supports manual dispatch.
- It authenticates using the GitHub Actions secret `FIREBASE_SERVICE_ACCOUNT`.
- Its deployment command is `firebase deploy --only firestore:rules --project dojo-platform-b68a3 --non-interactive`.
- **Important:** a qualifying push to `main` can trigger an automatic production Rules deployment. Do not merge or push a Rules change to `main` without intended review and authorization.

### 3. Emulator test workflow
- File: `.github/workflows/test-firestore-rules.yml`
- Blob SHA: `d5f0df9661d4e399a974ea22a4a1375f374d7cba`
- [View workflow](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/blob/main/.github/workflows/test-firestore-rules.yml)
- It runs on relevant pull requests, relevant pushes to `main`, and manual dispatch.
- It uses the demo project `demo-dojo-rules-tests` for Firestore Emulator tests and runs `npm test`.
- Test workflow execution is not a live deployment verification.

### 4. Partner repository relationship
The Partner repository's visible workflow deploys Functions only, while this Firebase repository contains the dedicated Firestore Rules deployment workflow. This identifies the repository's **configured deployment path**, but does not prove that a specific workflow run succeeded or that the currently deployed Firebase rules exactly match the current `main` file.

## Conclusion / Next safe action
Treat `DOJO-WALK-Firebase/firestore.rules` on `main` as the configured deployment source, subject to confirming current deployment history and live state. Before any Rules merge/deploy, verify the exact commit and the live Firebase Rules release through authorized deployment evidence or Firebase Console/CLI. No production state was read or changed during this repository-only audit.

## Evidence
- [firebase.json](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/blob/main/firebase.json)
- [.firebaserc](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/blob/main/.firebaserc)
- [Firestore Rules source](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/blob/main/firestore.rules)
- [Deploy Firestore Rules workflow](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/blob/main/.github/workflows/deploy-firestore-rules.yml)
- [Test Firestore Rules workflow](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/blob/main/.github/workflows/test-firestore-rules.yml)

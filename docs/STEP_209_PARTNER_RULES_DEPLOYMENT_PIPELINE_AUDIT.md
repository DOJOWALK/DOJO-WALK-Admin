# DOJO WALK — Step 209: Partner Rules Deployment Pipeline Audit

## Status
- Result: **Audit completed; deployment source remains unconfirmed**
- Repository inspected: `dojoplatform2026/dojo-partner`
- Ref inspected: `main`
- Scope: repository configuration and visible GitHub Actions workflows only
- Safety: no Firebase rules, production data, deployment settings, or workflows changed

## Findings

### 1. Firebase configuration
- `firebase.json` blob SHA: `9c0a48062869c158b2f52db3a4946611ad14101a`
- It configures the Functions source directory (`functions`) and Node.js 22 runtime.
- It does **not** declare a `firestore.rules` deployment mapping.
- A root `.firebaserc` was not found at the inspected `main` path. This does not rule out project selection through CI configuration or another repository.

### 2. Visible workflows
- `.github/workflows/deploy-functions.yml` SHA: `6f365897529a6c50f7dcb79121d7c2eb7004af1a`
  - Triggers on manual dispatch or changes under `functions/**`, `firebase.json`, and this workflow on `main`.
  - Authenticates with the GitHub secret `FIREBASE_SERVICE_ACCOUNT_DOJO_PLATFORM_B68A3`.
  - Runs `firebase deploy --only functions --project dojo-platform-b68a3`.
  - It does **not** deploy Firestore rules.
- `.github/workflows/flutter.yml` SHA: `d2f9850b770afaa26eaeffdf7de3cd5baa5a5bc8`
  - Builds/analyzes/tests the Partner Flutter app and uploads an APK artifact.
  - It contains no Firebase rules deployment step.
- The repository's `.github/workflows` directory listed these two workflow files at the time of inspection.

### 3. Function package
- `functions/package.json` SHA: `51b3febbe8cfa1754587eebabb1496b68a35a57a`
- Its scripts include only `lint` (`node --check index.js`); no rules deployment script was found there.

## Security conclusion
The Partner repository's visible CI does not deploy its bundled `firestore.rules`. The Functions workflow deploys **Functions only**. Therefore, the stale/incompatible rules file in this repository must not be treated as proof of which rules are currently deployed to Firebase. The Firebase repository's reviewed rules and passing emulator tests are useful source/test evidence, but neither proves the live deployed ruleset by itself.

## Recommended next step
Audit the Firebase repository's workflow/configuration history and the available deployment evidence to identify the intended single source of truth for Firestore rules. Confirm the live ruleset through an authorized Firebase Console/CLI read before any deployment decision. Do not deploy rules as part of this audit.

## Evidence links
- [Partner firebase.json](https://github.com/dojoplatform2026/dojo-partner/blob/main/firebase.json)
- [Partner Functions deployment workflow](https://github.com/dojoplatform2026/dojo-partner/blob/main/.github/workflows/deploy-functions.yml)
- [Partner Flutter workflow](https://github.com/dojoplatform2026/dojo-partner/blob/main/.github/workflows/flutter.yml)
- [Partner Functions package.json](https://github.com/dojoplatform2026/dojo-partner/blob/main/functions/package.json)

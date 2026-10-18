# Step 211 — Firestore Rules Deployment Run Evidence Audit

**Date checked:** 2026-10-18  
**Repository checked:** `dojoplatform2026/DOJO-WALK-Firebase`  
**Target Firebase project configured in source:** `dojo-platform-b68a3`  
**Safety boundary:** Read-only audit. No workflow was dispatched, no rerun was requested, no merge was performed, and no Firebase deployment or live project mutation was attempted.

## Evidence checked

1. Read `.github/workflows/deploy-firestore-rules.yml` on `main`.
   - Blob SHA: `60ae10677c94f5456422e170b3aba3898fa24d2f`
   - Source: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/blob/main/.github/workflows/deploy-firestore-rules.yml
   - The workflow is configured to run on pushes to `main` affecting `firestore.rules`, `firebase.json`, `.firebaserc`, or the workflow itself, and on manual dispatch.
   - It expects the GitHub secret `FIREBASE_SERVICE_ACCOUNT` and runs `firebase deploy --only firestore:rules --project dojo-platform-b68a3 --non-interactive`.

2. Inspected the most recent 100 GitHub Actions run records (five pages, 20 records per page) in the repository.
   - Recent runs included successful pull-request emulator tests, for example:
     - Rules tests #151: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39133139292 — `success`, event `pull_request`, review branch `step-138-partner-submission-negative-tests`.
     - Geometry/callable tests #140: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39133139279 — `success`, event `pull_request`, same review branch.
   - Neither run is a deployment run; both are test workflows triggered by pull requests.
   - No run with path `.github/workflows/deploy-firestore-rules.yml` appeared in the 100 run records inspected.

3. Read the current `main` rules file.
   - Blob SHA: `86ce54ab89a306be5d94904b409385960185be71`
   - Source: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/blob/main/firestore.rules
   - This establishes the repository's current source file only, not the live Firestore Rules version.

## Finding

**Live deployment remains unverified.** The recent Actions history inspected does not provide evidence of a successful run of the Firestore Rules deployment workflow. This bounded search does not prove that no older deployment run exists, and a successful emulator test does not establish what is deployed in Firebase.

The current repository source and configured workflow are identifiable, but the actual live rules version still needs an authorized read-only check in Firebase Console or other trusted deployment evidence. Do not dispatch the workflow merely to create evidence: its command targets `dojo-platform-b68a3` and can change production Rules.

## Next safe step

Check Firebase Console's Firestore Rules history / published version for project `dojo-platform-b68a3` using an authorized account, and compare the published rules with the reviewed source commit. Do not publish or edit Rules during that check.

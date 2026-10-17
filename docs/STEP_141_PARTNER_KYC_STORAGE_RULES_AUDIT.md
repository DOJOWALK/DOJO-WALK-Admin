# Step 141 — Partner KYC Storage Rules Audit

Date: 2026-10-18

## Scope
Reviewed Partner selfie/document upload code and Firebase deployment configuration on the review branches. No code or production settings were changed in this step.

## Findings
1. Partner uploads KYC files to Firebase Storage paths:
   - `walker_selfies/{uid}/selfie_{timestamp}.jpg`
   - `walker_kyc/{uid}/{documentType}_{timestamp}.jpg`
2. The selfie and KYC screens upload the Storage object before writing its path and status to `walkers/{uid}`.
3. The Firestore review-branch Rules block ordinary walker document edits after `applicationSubmitted == true`; the 57-test emulator run validates the nested KYC metadata update denial.
4. The Firebase repo root on the reviewed branch contains `firestore.rules` and `firebase.json`, but no `storage.rules`; `firebase.json` configures Firestore Rules and Functions only, with no Storage Rules path.
5. Therefore this repository snapshot does not provide a reviewable/deployable Storage Rules policy to verify whether uploads, overwrites, and reads of these private KYC objects are restricted by UID, path, content type, size, and application status. This is a configuration/evidence gap, not proof that deployed Storage Rules are open or absent.

## Risk / next action
- Treat KYC Storage authorization as a release blocker until the actual Firebase Storage Rules source and deployed configuration are located and reviewed.
- A Firestore write denial does not itself prove the preceding Storage upload was denied; it can leave an uploaded object whose metadata was not saved.
- Add server-side Storage policy that restricts private KYC reads and owner uploads to the correct UID/path and approved MIME/size limits, while aligning the lifecycle with submission/review policy. Test with the Storage Emulator before deployment.
- Client-side submitted-state checks are useful UX but cannot replace Storage Rules.

## Release status
No merge, deployment, or production change. Actual deployed Storage Rules are unknown and must not be inferred from this repository's missing file.

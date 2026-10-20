# Step 219 — CI Recheck and Name-Index Hierarchy Validation

Date: 2026-10-18

## Step 218 CI results
For PR #6 head commit `7949497341d9f9c6d3667a871da39daf56667c6f`, GitHub Actions completed successfully:
- Firestore Rules Emulator Tests — run #152, success.
- Trusted Location Geometry and Callable Tests — run #141, success.
- Workflow YAML validation job — success.

## Additional hardening committed
The review found that the prior parent list check was not meaningful validation of the hierarchy depth. The Rules now require the expected parent count for each index collection:
- `service_countries`: 0 parent IDs
- `service_states`: 1 parent ID
- `service_cities`: 2 parent IDs
- `service_areas`: 3 parent IDs
- `service_localities`: 4 parent IDs

New negative tests cover a wrong parent count and a country index with parent IDs.

## Current revision
Draft PR: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/pull/6
Branch: `fix/location-index-import-rules`
Current PR head commit: `88df8ea2854b35e76e35f943aac03548516cc0cd`
Rules blob SHA: `8f1a015ec244349d7e6874c3fa49d236f34cdfbd`
Test blob SHA: `a992072400c22ce76b9093db53cdce69df4d9e77`

## Latest CI status
The new revision has triggered fresh workflows:
- Test Firestore Security Rules — run #153, in progress at audit time.
- Trusted Location Geometry and Callable Tests — run #142, in progress at audit time.

Do not use the earlier passing runs as proof for the newer revision. Recheck the latest head after these runs complete.

## Still open
- Import `status` and `verificationStatus` remain bounded strings, not enums, until the Admin importer defines authoritative accepted values.
- Firestore Rules do not verify that the index document ID is the SHA-256 hash of the Admin-generated tuple; consider a trusted callable/server write path for stronger integrity.
- PR remains Draft and unmerged. No production deployment occurred.

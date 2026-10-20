# Step 135 — District Callable Emulator Coverage

Date: 2026-10-19

Firebase repository: `DOJO-WALK-Firebase`
Branch: `fix/location-index-import-rules`
Test commit: `c26c1afae0723e79a3a75a60950dcd96ea9f6166`

## Added
Added `functions/test/district_status.integration.test.cjs`, which uses the same Firestore Emulator integration-test pattern as the existing trusted callable suites.

Coverage includes:
- unauthenticated and non-admin District save requests are rejected;
- a State that belongs to a different Country cannot be used for a District;
- a valid District document and canonical name index are written;
- duplicate District names under the same Country/State are rejected;
- District activation requires an active Country and State;
- successful activation guard-writes both ancestors;
- District deactivation is blocked by active City descendants and active Area descendants;
- District deactivation succeeds after active descendants are disabled.

## Verification
The preceding code-fix and regression-guard commits passed the existing Firebase CI:
- Firestore Security Rules run 244: PASS.
- Trusted Location Geometry and Callable Tests run 244: PASS.

Those runs are for commit `ffbdac545d943215a72f226cad57a5b7ac6227ea` and do not yet include this new emulator test. CI for this test commit must finish before claiming the District integration tests passed.

## Safety and scope
No deployment, merge, or production data import was performed. Admin changes are documentation only; Customer and Partner repositories remain untouched.

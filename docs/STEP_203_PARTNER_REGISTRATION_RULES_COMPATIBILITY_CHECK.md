# Step 203 — Partner Registration and Firestore Rules Compatibility Check

**Status:** Source-level compatibility check completed; no live reproduction  
**Repository reviewed:** `dojoplatform2026/dojo-partner`, `main`  
**Rules source SHA:** `7b02a8bfb4fe80ab04d72f59966e2e09c848ffd0`  
**Scope:** Compare exact write payloads against the reviewed rules. No code, rules, data, deployment, or merge changes.

## 1. Finding A — Initial profile create appears incompatible

File: `lib/features/onboarding/screens/personal_details_screen.dart`, SHA `ae8a929e9ec724e9536acd2c8ffcc9b7c06c0f82`.

For a new profile, the client includes fields such as:
`applicationSubmitted`, `city`, `state`, `area`, `zoneName`, `zoneNames`, `zones`, and `travelMode`.

The reviewed `walkers/{walkerUid}` create rule's `keys().hasOnly([...])` allowlist does not include those fields. It also requires `status == 'under_review'`, while the onboarding create payload sends `status: 'in_progress'`.

**Likely impact if these exact sources are active together:** first-time profile creation is rejected by Firestore Rules. This is a static comparison; no authenticated app run or Rules Emulator test was executed in this step.

## 2. Finding B — Final application submission appears incompatible

File: `lib/features/onboarding/screens/review_submit_screen.dart`, SHA `17aaedef0c04ee7956bb6260a05cc7f1d7f3380d`.

The final submission client calls `walkerRef.update` with:
- `status: 'under_review'`
- `applicationSubmitted: true`
- `submittedAt`
- `updatedAt`
- `onboardingStep: 'submitted'`

The reviewed ordinary owner-update rule allows only its listed profile/KYC/location keys and does not include `status`, `applicationSubmitted`, `submittedAt`, or `onboardingStep`. The separate admin update rule requires `isAdmin()`, so it does not authorize a normal partner owner submission.

**Likely impact if these exact sources are active together:** a normal partner's final submission is rejected with permission denied. This is a source-level finding, not a confirmed production reproduction.

## 3. Rules must not be loosened blindly

The intended trust boundary is that a partner may submit their application but may not self-approve, activate, or set verification status. A future fix must preserve that boundary.

Before implementation:
1. Add or run Firestore Rules Emulator tests against the exact client payloads.
2. Agree on the canonical onboarding document schema and lifecycle.
3. Permit only the necessary owner-submission fields and validate their exact transitions (e.g. only `in_progress -> under_review`, only `applicationSubmitted: false -> true`, server timestamp fields, and no change to approval flags).
4. Keep `isActive`, `isApproved`, and `verificationStatus` controlled by admin/trusted server logic.
5. Make initial create and final submit schemas consistent with the partner client, admin review screens, and backend.
6. Run partner unit/widget tests, Rules Emulator tests, and app integration tests before considering deployment.

Do not deploy a rules change until tests prove that a partner can submit and still cannot self-approve or modify protected fields.

## 4. Test status

- Static source comparison: **completed**.
- Authenticated app reproduction: **not run**.
- Firestore Rules Emulator: **not run** in this step.
- CI/test workflow: **not run** in this step.
- Production rules revision: **not verified**.

## 5. Change boundary

No runtime code, Firestore Rules, schema, production data, deployment, or merge was changed. This is a high-priority compatibility finding to fix on a review branch after the intended schema is confirmed.

Related:
- [Step 202 — Partner eligibility and coverage audit](STEP_202_PARTNER_ELIGIBILITY_COVERAGE_AUDIT.md)
- [Step 201 — Admin and walker eligibility field audit](STEP_201_ADMIN_AND_WALKER_ELIGIBILITY_FIELD_AUDIT.md)
- Partner source files listed above.

# DOJO WALK — Firestore Security Test Coverage (Step 47 follow-up)

Date: 2026-10-17  
Tracking repository: `dojoplatform2026/dojo-admin`  
Branch: `restore/india-location-reference-data`  
Target rules repository: `dojoplatform2026/dojo-firebase`

## Outcome

**Coverage plan recorded; tests not yet implemented or run in this follow-up.** The GitHub connector could not retrieve the target repository's `firestore.rules`, test file, or workflow, and repository code search returned no results. Without reading the exact current rules and test harness, safely editing or extending the tests is not possible.

## Required security cases

1. **Area activation**
   - Deny activation when no verified Area boundary exists.
   - Deny activation when boundary reference is missing, mismatched, or not verified.
   - Deny activation if parent City is inactive/unverified or the Area boundary does not reference the expected parent.
   - Verify rejected writes leave the Area inactive.
2. **Boundary verification and transitions**
   - Deny verification unless the parent boundary is verified and the referenced parent IDs match.
   - Deny unauthorized edits/deletes of verified boundaries.
   - Test status transitions and metadata tampering, not only the happy path.
3. **Name indexes**
   - Deny direct writes/deletes from ordinary client roles if indexes are maintained only by a trusted workflow.
   - Confirm permitted trusted/admin path preserves normalized-name uniqueness and cannot claim another location's index.
4. **Import permissions and audit trail**
   - Deny import creation/update/delete for unauthorized roles.
   - Confirm authorized import workflow writes required actor, timestamp, source and outcome fields.
   - Ensure a user cannot impersonate another actor or rewrite a completed import audit record.
5. **Role/rules authorization matrix**
   - Unauthenticated user: deny privileged reads/writes.
   - Inactive admin: deny privileged writes.
   - Active `super_admin`: allow only documented administrative operations.
   - Active `location_admin`, `operations_admin`, and `support_admin`: verify each permitted/denied operation against an explicitly approved scope.
   - Test that a client-side `isActive` flag alone cannot grant privileged Firestore access.
6. **Regression and execution**
   - Run tests against the Firestore Rules Unit Testing SDK and Firebase Emulator, not only fake Firestore.
   - Capture the exact GitHub Actions run URL, commit SHA, and result in the status report.

## Safety / scope

- No Firestore rules or tests were modified in the central repository during this follow-up.
- No production Firebase deployment, data import, or location activation was performed.
- Step 46 remains **user-confirmed PASS** from the earlier conversation; its exact Actions run link is still missing.
- The above cases are a test plan, not evidence that the cases currently pass.

## Next unblock

Restore/confirm connector access to `dojoplatform2026/dojo-firebase`, then read the current `firestore.rules`, `package.json`, test file, and workflow. Implement the smallest compatible test additions, run the emulator-backed workflow, and record the actual run link.

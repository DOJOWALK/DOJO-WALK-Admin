# Zone UI-to-Emulator E2E Test Plan

Status: planning/contract audit only. This file does not claim that browser-to-emulator E2E is implemented or passing.

## Safety boundary

- Run only against Auth, Firestore, and Functions emulators.
- Use a unique emulator project ID (for example `demo-dojo-zone-e2e`) and explicit emulator ports.
- Fail fast if the target project is not the emulator-only project or if required emulator host variables are absent.
- Never use `dojo-platform-b68a3` as the test target.
- Do not deploy functions, deploy rules, merge a PR, or write to production.

## Repositories and baseline revisions audited on 2026-10-28

- Admin: `DOJOWALK/DOJO-WALK-Admin`, audited commit `1b02b07c855d1240029bdebcd41cfb5f08003cfe` (PR #47).
- Firebase: `DOJOWALK/DOJO-WALK-Firebase`, audited commit `6b1ac42c99564333bf9507a0b5739257c28421eb` (PR #39).

## Callable contract currently used by Admin

| Admin operation | Firebase callable | Payload keys |
| --- | --- | --- |
| Save draft | `saveServiceLocationWithNameIndex` | `locationType=zone`, `locationId`, `payload` |
| Submit for Founder review | `submitServiceZoneForFounderReview` | `zoneId` |
| Founder decision | `decideServiceZoneFounderApproval` | `zoneId`, `decision`, `notes` |
| Activate approved Zone | `activateServiceZone` | `zoneId` |
| Request deactivation | `requestServiceZoneDeactivation` | `zoneId`, `notes` |
| Execute approved deactivation | `setServiceLocationStatus` | `locationType=zone`, `locationId`, `isActive=false` |
| Request reactivation | `requestServiceZoneReactivation` | `zoneId`, `reason` |
| Emergency suspend | `suspendServiceZoneForEmergency` | `zoneId`, `reason`, `severity` |

The callable names and payload keys above were checked against the Admin service and Firebase exports at the baseline revisions. This is a static contract audit, not an executed end-to-end test.

## Required E2E sequence

1. Start Auth, Firestore, and Functions emulators with a dedicated test project.
2. Seed synthetic State → District → City ancestry, verified City/Zone boundaries, and active/inactive test users for Central Admin, Founder, Super Admin, and ordinary staff.
3. Launch the Admin UI configured for the emulators and sign in as Central Admin.
4. Create a Zone draft using the UI. Assert the Zone is inactive, workflow status is `draft`, revision starts at the expected value, and name-index records exist.
5. Submit the Zone for Founder review from the UI. Assert submitted state and reject Founder-decision attempts by Central Admin, Super Admin, and inactive users.
6. Sign in as Founder, approve the submitted revision, and assert approval metadata binds to that revision and the verified boundary hash.
7. Return to Central Admin and activate the approved Zone. Assert service-active state and an audit record.
8. Request deactivation as Central Admin; verify service remains governed by the approval workflow until Founder approval and Central Admin execution are complete.
9. Emergency-suspend as Central Admin; assert service is immediately inactive, reason/severity are recorded, an audit record is written, and a Founder inbox notification is queued. Push/email delivery is not configured and must not be claimed.
10. Request reactivation and verify it remains inactive until a fresh Founder decision and Central Admin activation.
11. Assert duplicate-name, ancestry mismatch, unverified/out-of-city boundary, missing auth, inactive account, and wrong-role cases fail closed.
12. Clean up all fixture documents, indexes, audit rows, and inbox records in emulator storage.

## Implementation phases

- [ ] Add a browser-capable E2E runner and explicit emulator startup to CI.
- [ ] Add a shared contract assertion so Admin callable names/payload keys are checked against Firebase exports.
- [ ] Add UI-driven happy-path lifecycle test.
- [ ] Add role/authorization denial tests.
- [ ] Add boundary/name-index negative tests.
- [ ] Add audit/inbox assertions and deterministic fixture cleanup.
- [ ] Upload logs and publish both exact tested SHAs in CI output.
- [ ] Verify CI runs without any production credentials or deployment step.

## Current known verification status

- Admin unit/widget/build CI passed on the Admin baseline commit.
- Firebase workflow YAML, Firestore Rules emulator tests, and callable/build/geometry integration CI passed on the Firebase baseline commit.
- Firebase callable integration tests use the Firestore emulator and call exported handlers; Admin widget tests exercise UI gates separately.
- **The complete Admin browser/UI → Firebase Auth/Firestore/Functions Emulator flow has not yet been independently executed.**

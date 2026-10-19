# DOJO WALK Developer Team Control Center
Last verified: 2026-10-19 (GitHub API + latest workflow runs)
Primary rule: **finish and review Admin first; do not merge it yet. Only after Admin is complete and explicitly approved for merge, proceed to Partner and Customer integration.**

> This is the continuation source of truth for a new chat or a mobile session. Read this file first. Do not trust an old step report without checking its commit SHA against the current branch head.

## 1. Current release gate at a glance

| Area | Current state | Evidence / rule |
|---|---|---|
| Admin app | Active priority; PR #7 is Draft/open, head `step-119-boundary-geometry`, head SHA `8efc042db2bb4ecee825cbfc5b16a0c423d8df41` | [Admin PR #7](https://github.com/dojoplatform2026/DOJO-WALK-Admin/pull/7) |
| Admin Web Build Check (No Deploy) | PASS on current PR head | [Run 39245999526](https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39245999526) |
| Admin Service Location Geometry Tests | PASS on current PR head | [Run 39245999614](https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39245999614) |
| Shared Firebase | Active supporting branch; PR #6 Draft/open, head `fix/location-index-import-rules`, current PR SHA `e2f72b72e97b9bf51d81dddfa366c6986afef811` | [Firebase PR #6](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/pull/6) |
| Firebase callable/geometry tests | PASS on current PR head | [Run 39236530995](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39236530995) |
| Firebase Firestore Rules tests | PASS on current PR head | [Run 39236531337](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39236531337) |
| Customer app | Not to be modified until Admin review/merge gate is complete | Separate repo; integration later |
| Partner app | Not to be modified until Admin review/merge gate is complete | Separate repo; integration later |
| Production | NOT released | No merge, production import, activation, or Firebase/Hosting deployment is authorized by this status file |

**CI scope:** passing CI proves only the code exercised by those workflows at those SHAs. It does not prove live Firestore compatibility, official-data correctness, production settings, or complete end-to-end release readiness.

## 2. Repository / PR map

1. **Admin:** `dojoplatform2026/DOJO-WALK-Admin` — branch `step-119-boundary-geometry`, PR #7 to `main`.
2. **Shared Firebase:** `dojoplatform2026/DOJO-WALK-Firebase` — branch `fix/location-index-import-rules`, PR #6 to `feature/trusted-location-activation`.
3. **Customer:** `dojoplatform2026/dojo-walk-customer` — frozen until Admin gate completes.
4. **Partner:** `dojoplatform2026/dojo-partner` — frozen until Admin gate completes.
5. **Website:** `dojoplatform2026/DOJO-WALK-Website-` — separate public website; not a blocker for Service Location schema work unless a later task specifically requires it.

Do not assume similarly named branches have the same base or are ready to merge together. Review each PR's base, changed files, checks, and dependencies before merge.

## 3. What has been built (verified from branch contents / CI)

### Admin
- Service Location management UI and country/state/district/city/area hierarchy work are present on the review branch.
- Boundary geometry model/service and geometry regression tests are present.
- CSV parsing/preview and validation cover required State, District, City and Area mapping, malformed quoting, duplicate headers/combinations, and row-width issues.
- India reference Dart datasets (states, districts, sub-districts) and integrity tests are present on the review branch.
- Latest PR-head no-deploy web build and geometry workflows passed (run links above).

### Shared Firebase
- Service-location trusted callable / Firestore Rules tests are passing on the current PR head.
- District-aware name-index work and preflight/integration reports exist on the branch. Treat any older Step 170–189 report as a historical snapshot unless its commit SHA matches the current branch.
- Current CI passes on the current PR head; this is not evidence of a production data migration or deployment.

## 4. Remaining work — do not mark complete without evidence

### P0 — Admin/Firebase contract and merge gate
- [ ] Audit the exact current Admin and Firebase branch heads and read the latest relevant source, not only historical reports.
- [ ] Compare the exact City `districtId` optional/legacy behavior, Area/Locality parent tuple ordering, name-index IDs, active-status fields, callable payloads, and Firestore Rules.
- [ ] Resolve any mismatch in a reviewed code change with tests on both repositories.
- [ ] Ensure CSV import remains preview-only unless an approved transactional import with rollback and emulator/integration tests is actually implemented.
- [ ] Run the complete Admin checks on the final candidate SHA: formatting, `flutter analyze`, `flutter test`, release web build, geometry and parser tests.
- [ ] Run the Firebase callable/integration and Firestore Rules workflows on the corresponding final Firebase SHA.
- [ ] Reconcile PR branch divergence against base safely; do not force-push or discard changes.
- [ ] Review PR #7 changed files and latest PR #6 dependency/compatibility status.
- [ ] Verify repository branch protection and required review/check configuration; a green CI badge alone is not sufficient.
- [ ] Keep both PRs Draft until review gates and the user explicitly authorizes merge.

### P1 — data/import and production safety
- [ ] Retrieve/reconcile the current official LGD source snapshot; the previously audited sub-district snapshot is dated 2024-10-07 and is not automatically current.
- [ ] Confirm reliable authoritative boundary data for target areas (especially UP/NCR); synthetic polygon tests do not prove real-world boundary accuracy.
- [ ] Design a transactional CSV import with dry-run preview, duplicate/conflict report, idempotency, rollback/recovery, and emulator coverage.
- [ ] Decide the production-safe order for Rules/Functions and Admin release; verify production Environment required reviewers and Hosting deployment safeguards.
- [ ] If and only if separately approved, perform a read-only preflight against the explicitly confirmed Firebase project and review its complete report before any migration proposal.
- [ ] Production scan/import/activation/deployment requires explicit authorization; do not infer approval from “next” or “continue.”

### P2 — after Admin is approved and merged
- [ ] Re-open Customer and Partner work only after Admin merge is confirmed.
- [ ] Audit both app repos against the finalized Admin/Firebase contract before coding.
- [ ] Customer: verify login/profile/address/booking schemas and service-area selection against the final hierarchy.
- [ ] Partner: verify onboarding/work-zone selection, legacy `zones` compatibility, walker IDs and existing records; never map old zones by name alone.
- [ ] Run each app's own build/tests and cross-repository contract tests; keep migrations/deployments gated separately.

## 5. Data and compatibility invariants

- Target logical hierarchy: Country → State → District → Service City → Service Area → optional Locality.
- Legacy City records without `districtId` must remain compatible until an explicit, tested migration says otherwise.
- Area/Locality name-index parent tuple order must be consistent between Admin and trusted Firebase code. Never guess tuple order.
- Do not delete legacy indexes or rewrite production records just because a new District-aware index exists.
- Preserve official LGD codes, leading zeros where relevant, and source metadata. Do not hand-recreate or replace full reference datasets with sample data.
- Locality is optional for customer address entry; the user-facing service coverage selection is intended to stop at Area unless product requirements are explicitly changed.
- Existing Partner `zones`/walker data needs a separately tested compatibility plan; no name-only migration.

## 6. Safe continuation protocol (every step)

1. Read this Control Center.
2. Fetch current PR head SHA and latest CI runs for the repo being touched.
3. Read the current source/tests and latest relevant report.
4. State the exact next step and scope; change only that scope.
5. Add/adjust tests for behavior changes.
6. Re-fetch the changed file and inspect the exact resulting source.
7. Wait for CI; inspect logs and fix any failures.
8. Add a dated/numbered report with commit SHA, run IDs, PASS/FAIL/PENDING, changed files, and safety boundaries.
9. Update this Control Center whenever the release gate or next action changes.
10. Never say “complete” unless evidence supports it; never claim deployment, migration, merge, or live counts without a verifiable result.

### Report status vocabulary
- **PASS:** exact current commit tested successfully.
- **FAIL:** a check or gate failed; record evidence and next fix.
- **PENDING:** not yet run, not verified, or requires an external decision.
- **BLOCKED:** cannot safely continue until a named dependency is resolved.
- **NOT DONE:** no implementation or operation has occurred.

## 7. Next exact action

**Start with an Admin/Firebase cross-repository contract audit on the current heads** (`8efc042...` Admin and `e2f72b7...` Firebase). Compare source code and tests for District/City ancestry, Area/Locality index tuples, active status, and callable/rules behavior. Record mismatches and fixes required; do not touch Customer or Partner. Do not merge or deploy.

## 8. Quick handoff message for a new chat

Paste this instruction in the next chat:

> Continue DOJO WALK from `docs/DEVELOPER_TEAM_CONTROL_CENTER.md` in `dojoplatform2026/DOJO-WALK-Admin`, branch `step-119-boundary-geometry`. First re-check current PR #7 and Firebase PR #6 heads/CI because this report can become stale. Admin is priority; Customer and Partner must remain untouched until Admin is reviewed and explicitly merged. Next task: cross-repository Admin/Firebase contract audit. Work on GitHub/mobile-friendly steps, keep the report updated, inspect real code and tests, and never merge/deploy/migrate without explicit approval.

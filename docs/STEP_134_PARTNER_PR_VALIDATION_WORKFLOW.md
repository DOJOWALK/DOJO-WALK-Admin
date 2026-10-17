# Step 134 — Partner PR Validation Workflow

Date: 2026-10-18  
Status: **Draft PR opened; workflow execution still needs verification.**

## Change created

Repository: `dojoplatform2026/dojo-partner`  
Branch: `ci/partner-pr-validation`  
Commit: `43754938ee2d914ca6d1c3ff8ad9a8f018f5ceda`  
Draft PR: https://github.com/dojoplatform2026/dojo-partner/pull/2

New file: `.github/workflows/partner-pr-validation.yml`

## Workflow coverage

- Pull requests targeting `main`, filtered to Dart, package/lock files, analysis config, tests, assets, Android files and the workflow itself.
- Manual `workflow_dispatch`.
- Read-only repository permission.
- Concurrency group cancels obsolete validation runs for the same PR/ref.
- Flutter stable setup and dependency resolution.
- Required Partner image assets checked.
- Android launcher icons generated.
- `flutter analyze`.
- `flutter test`.
- `flutter build apk --debug`.

The existing release workflow remains separate and still owns release APK packaging/artifact upload. This PR does not change app runtime code or deploy an APK.

## Verification status

- [x] Workflow committed to a dedicated branch.
- [x] Draft PR opened for review.
- [ ] GitHub Actions run starts and workflow YAML is accepted.
- [ ] Analyze succeeds.
- [ ] Tests succeed.
- [ ] Debug APK build succeeds.
- [ ] Review and merge only after actual CI results and code review.

No CI PASS is claimed yet because no run result has been inspected. Do not merge this draft until the first run and review are complete.

## First run status update

GitHub Actions run: [39068442507](https://github.com/dojoplatform2026/dojo-partner/actions/runs/39068442507)

At the latest check:
- Setup, checkout, Flutter setup, dependency install, required asset checks, and launcher-icon generation: **success**.
- `flutter analyze`: **in progress**.
- `flutter test` and debug APK build: pending.
- Overall run: in progress.

These are live intermediate results, not a final CI pass.

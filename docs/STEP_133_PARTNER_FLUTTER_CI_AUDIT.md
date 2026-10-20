# Step 133 — Partner Flutter CI Coverage Audit

Date: 2026-10-18  
Status: **Workflow configuration inspected; no PR-triggered run found for the inspected source.**

## Files inspected

Repository: `dojoplatform2026/dojo-partner`, branch `main`.

- `.github/workflows/flutter.yml`, blob `d2f9850b770afaa26eaeffdf7de3cd5baa5a5bc8`
- `pubspec.yaml`, blob `8276384813d505ac204b2b85f2b572e87636e413`
- Submission UI `lib/features/onboarding/screens/review_submit_screen.dart`, source blob reviewed in Step 132.

## Workflow contract

The workflow `DOJO WALK Partner Release APK` runs on:
- push to `main`
- manual `workflow_dispatch`

It does **not** declare a `pull_request` trigger. Therefore, a draft feature PR does not automatically run this workflow. The workflow sequence itself includes:
1. `flutter pub get`
2. required image asset checks
3. `dart run flutter_launcher_icons`
4. `flutter analyze`
5. `flutter test`
6. `flutter build apk --release`
7. upload release APK artifact (7-day retention)

A search for workflow runs associated with the inspected submission source blob did not return a run. Since that identifier is a file blob rather than a commit SHA, this is not proof that no related build ever ran; it only means no PR-run evidence was available from that query. No manual workflow dispatch was triggered.

## Findings

- The Partner repo has a useful full analyze/test/release-APK workflow, but it is wired to `main` pushes and manual dispatch only.
- No CI pass is claimed for the exact Partner source revision inspected in Step 132.
- Running the release workflow manually against `main` would validate `main`, not an unmerged feature branch. A manual run is not a substitute for PR checks on a specific head SHA.
- To make review safer, consider adding a separate `pull_request` workflow (or adding PR trigger to the existing workflow only after confirming artifact/release semantics). A PR check should run analyze/tests and a debug or non-release build; release artifact creation should remain separate from PR validation.

## Checklist

- [x] Inspect workflow triggers and validation steps.
- [x] Inspect declared Flutter package/test dependencies.
- [x] Check available workflow-run evidence; no matching PR run was established.
- [ ] Add/approve a PR validation workflow.
- [ ] Run analyze/tests/build on the exact reviewed Partner commit and retain CI results.
- [ ] Cross-review Partner PR and Firebase draft PR #4 before release.

No workflow was dispatched, no Partner source or workflow was changed, and no merge/deployment/production data operation occurred.

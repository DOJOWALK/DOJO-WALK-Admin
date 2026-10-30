# DOJO WALK Admin — Service Location UI Final Acceptance Checklist
**Date:** 2026-10-31  
**Repository:** `DOJOWALK/DOJO-WALK-Admin`  
**Branch:** `ui/notion-brand-foundation-2026-10-28`  
**Scope:** UI acceptance planning and source-level review only. This checklist does not authorize Firebase/Firestore integration, Emulator work, merge, or deployment.

## Evidence labels
- **Implemented / source-reviewed:** the current source was inspected and the expected UI behavior or guardrail is present.
- **CI executed — passed:** a test exists in the repository, but no Flutter test result has been observed.
- **Not verified:** requires actual test execution, device/browser testing, or product-owner confirmation.
- **Blocked by backend gate:** intentionally unavailable until Admin UI acceptance and validation are complete and a separate backend gate is approved.

## 1. Create Zone — form and hierarchy
- [x] **Implemented / source-reviewed:** hierarchy is exactly State/UT → District → City → Zone; no Locality selector.
- [x] **Implemented / source-reviewed:** changing an upstream selection clears dependent selections; selecting “Create new Zone…” reveals the new Zone name field.
- [x] **Implemented / source-reviewed:** a new Zone requires a polygon preview; radius-only evidence is not accepted as a substitute.
- [x] **Implemented / source-reviewed:** local geometry feedback distinguishes basic shape validity from GIS verification; the UI explicitly says local validity is not GIS verification.
- [x] **Implemented / source-reviewed:** preview drawing is in-memory only; no upload or persistence callback is wired.
- [x] **Implemented / source-reviewed:** Save Draft and Submit for Review remain disabled; readiness dialog explains the missing authoritative catalog/GIS evidence and that nothing is saved.
- [x] **CI executed — passed:** tests cover hierarchy, cascading reset, new-Zone selection, disabled actions, missing polygon evidence, local geometry feedback, and readiness blockers.
- [ ] **Not verified:** execute Create Zone widget tests and manually exercise map taps, undo, clear, and bottom-sheet behavior on supported devices.

## 2. Zone Directory — discovery and lifecycle
- [x] **Implemented / source-reviewed:** directory supports the current search/status-filter prototype and shows example-only data warnings.
- [x] **Implemented / source-reviewed:** lifecycle is Zone-level; State/UT, District, and City are not independently activated/deactivated.
- [x] **Implemented / source-reviewed:** temporary **Suspended** state is described as an emergency safety/material-risk stop, not a shortcut for normal deactivation. Central Admin records the reason/audit event and promptly notifies Founder; new bookings are blocked while suspended.
- [x] **Implemented / source-reviewed:** Directory actions pass the selected Zone ID into Boundary Review and Founder Approval Queue routes.
- [x] **CI executed — passed:** Directory tests cover search/filter, empty/reset behavior, narrow viewport, details metadata, boundary-review route context, approval-queue route context, and suspension guidance.
- [ ] **Not verified:** run Directory widget tests and verify keyboard/focus behavior and long Zone names at narrow widths.

## 3. Zone Details — traceability
- [x] **Implemented / source-reviewed:** details preview shows Zone identity, parent hierarchy, status, boundary status, readiness blockers, revision/metadata, last-updated and updated-by fields, with an example-data warning.
- [x] **Implemented / source-reviewed:** unavailable edit/lifecycle actions remain disabled.
- [x] **Implemented / source-reviewed:** Details passes its Zone ID to Boundary Review and Founder Approval Queue.
- [x] **CI executed — passed:** details test covers displayed metadata, disabled controls, and a 320px viewport; Directory test asserts the selected row's values reach Details.
- [ ] **Not verified:** run both Details and Directory widget tests; verify text scaling and unusually long metadata values.

## 4. Boundary Review — technical evidence
- [x] **Implemented / source-reviewed:** boundary evidence/revision state is shown separately from operational activation.
- [x] **Implemented / source-reviewed:** a changed boundary revision/hash requires a fresh review; prior approval must not be reused.
- [x] **Implemented / source-reviewed:** “Verified (example)” is used consistently; the screen explains that verified boundary evidence does not activate a Zone or constitute Founder launch approval.
- [x] **Implemented / source-reviewed:** selected Zone ID is retained when routing to Founder Approval Queue.
- [x] **CI executed — passed:** tests assert the verified-example label, absence of the obsolete “Integrity matched” label, and the separate approval/activation explanation.
- [ ] **Not verified:** run Boundary Review widget tests and validate map/evidence rendering on real browsers/devices.

## 5. Founder Approval Queue — business decision
- [x] **Implemented / source-reviewed:** Founder/CEO remains the final business approver for launch/activation and material lifecycle decisions; Central Admin prepares the request.
- [x] **Implemented / source-reviewed:** Super Admin does not inherit Founder approval authority.
- [x] **Implemented / source-reviewed:** boundary verification, Founder decision, and operational lifecycle status remain distinct states.
- [x] **Implemented / source-reviewed:** selected Zone ID appears in the queue route when passed from Directory, Details, or Boundary Review.
- [x] **Implemented / source-reviewed:** example-only data and disabled action controls prevent the prototype from implying a live approval.
- [ ] **Not verified:** run Founder Approval Queue widget tests and review all blocked/rejected/pending states against the current Notion policy.
- [ ] **Not verified:** obtain explicit Founder/product-owner acceptance of the approval authority and suspension policy before enabling actions.

## 6. Responsive behavior and accessibility
- [x] **Implemented / source-reviewed:** screens use scrollable layouts, wrapping controls, and constrained/responsive layout structures; Boundary Editor map height is responsive to available screen height.
- [x] **CI executed — passed:** narrow viewport coverage exists across Add Zone, Directory, Details, Boundary Review, and Approval Queue; Details includes a 320px case.
- [ ] **Not verified:** run widget tests at 320px, 360px, tablet, and desktop widths; check portrait and landscape.
- [ ] **Not verified:** test large text scaling, screen-reader labels/semantics, keyboard navigation, focus order, contrast, and tap-target sizes.
- [ ] **Not verified:** test the native Google Maps platform view and bottom sheet on actual Android/iOS devices and supported web browsers.

## 7. Navigation and user-visible states
- [x] **Implemented / source-reviewed:** Zone ID context is preserved across Directory → Details / Boundary Review / Approval Queue and Boundary Review → Approval Queue.
- [x] **CI executed — passed:** Directory route assertions cover Zone ID propagation.
- [ ] **Not verified:** test back navigation, direct/deep route entry, missing/unknown Zone IDs, and repeated navigation.
- [ ] **Not verified:** validate loading, empty, error, offline, and retry states; do not substitute example data for a live-state claim.
- [ ] **Not verified:** verify no overflow, clipped dialogs, inaccessible controls, or accidental action affordances on all target form factors.

## 8. Required local validation — outstanding
**CI validation is complete for the current tested code commit** (Analyze, all 320 tests, and Web release build; see Section 12). The six focused Service Location test files listed below were individually observed passing in the CI log. The following commands remain a local reproducibility checklist; local execution has not been performed in this session.

Run from the Admin repository root on the target branch:
1. `flutter --version` and record the exact Flutter/Dart versions.
2. `flutter pub get`.
3. `flutter analyze`.
4. Run the focused tests:
   - `flutter test test/features/service_location/add_zone_screen_test.dart`
   - `flutter test test/features/service_location/zone_directory_screen_test.dart`
   - `flutter test test/features/service_location/zone_details_screen_test.dart`
   - `flutter test test/features/service_location/boundary_review_screen_test.dart`
   - `flutter test test/features/service_location/zone_approval_queue_screen_test.dart`
   - `flutter test test/features/service_location/services/service_boundary_preview_validator_test.dart`
5. Run the complete Admin widget/unit suite: `flutter test`.
6. Build the intended Admin target (at minimum `flutter build web`) and retain logs/artifacts.
7. Record each command's exit code, duration, and any failure details. Do not mark a test PASS unless its actual result is available.

**Current execution status (updated 2026-10-31):** GitHub Actions has now executed Analyze, the complete Flutter test suite, and Flutter Web release build successfully for code commit `2caff9d00d24020969a7744880101475d2afa9d2` (Flutter stable 3.47.9). This is CI evidence, not a claim that local device/browser, accessibility, or product-owner checks have been completed.

## 9. Backend / Firebase gate — explicitly blocked
Until Sections 1–8 are validated and accepted:
- Do not connect these prototype screens to Firestore or Firebase Storage.
- Do not enable Save Draft, Submit for Review, Founder approval, activation/deactivation, or suspension actions.
- Do not introduce boundary upload, canonical GIS verification, geometry hash persistence, audit writes, or lifecycle mutations.
- Do not add or dispatch Emulator integration workflows for this UI scope.
- Do not change canonical Firebase Rules, indexes, or production configuration.
- Do not merge or deploy this work.

After UI validation, obtain explicit owner approval for a separately scoped backend design and security review before implementation.

## 10. CI failure investigation and corrective commits — 2026-10-31

A real GitHub Actions run was found for code commit `71055eeb3268c9195b8cc00170665f741dfc4ad6`:
- Workflow: **Admin Web Build Check (No Deploy)**
- Run: `41109254956`
- Result: **FAILURE** — Analyze completed and the complete Flutter test command reported **315 passed, 2 failed**; the Web build did not run after the test failure.
- Failure 1: the out-of-range-coordinate test expected the full feedback string from a `LatLng(91, 1)` fixture, but the actual `LatLng` object reached the validator as a value that passed the preview check. The range predicate was extracted as a public raw-coordinate helper so latitude, longitude and non-finite bounds can be tested independently of Google Maps coordinate-object construction.
- Failure 2: the Zone Directory test attempted to tap “Preview approval queue” while the control was below the visible viewport on the Zone Details scroll view. The test now scrolls the control into view before tapping.
- Corrective commits:
  - `51472ed4703810975ea04f0a3b7b77d683205ab2` — extracted explicit raw-coordinate bounds validation.
  - `33f12460b0412a166abfe3bd8b72253440dab14e` — added direct latitude/longitude/non-finite/boundary-value tests.
  - `736a47416f942f1af2aad6a21f45905a8db07fd1` — scrolls the approval-queue control into view in the navigation test.
- These corrections are committed, but their own CI run has not yet been observed. Do not infer that they pass from the previous failed run.



**Fresh validation result:** Run #62 (`41111309355`) did not produce a usable completed result before the next source correction. After the approval-queue assertion was corrected in commit `2caff9d00d24020969a7744880101475d2afa9d2`, the following workflows completed successfully:
- **DOJO WALK Admin Flutter Validation**, run #63 / `41112382633`: `flutter analyze` — **No issues found** (21.0s); `flutter test --no-pub` — **320 tests passed**; `flutter build web --release --no-pub` — **Built build/web**. Job conclusion: success.
- **Admin Web Build Check (No Deploy)**, run #1307 / `41112382557`: conclusion **success**.
- The test assertion now accepts repeated `Awaiting decision` labels; source file was fetched back from GitHub and the updated assertion verified.

These CI runs validate code commit `2caff9d00d24020969a7744880101475d2afa9d2`. A subsequent documentation-only update does not change that tested code.

## 11. Acceptance decision
**Status: NOT YET ACCEPTED.**  
Reason: automated CI is now green (Analyze, 320 tests, and Web release build), but the remaining manual/device/browser/accessibility checks in Sections 1–7 and explicit Founder/product-owner acceptance are still outstanding. This is not a claim that the Service Location UI is complete or production-ready.

**Next engineering action:** confirm the new branch push triggers the validation workflow, inspect its logs, fix any remaining failures, and only then request product-owner acceptance.


## 12. Successful CI evidence — 2026-10-31
- Tested code commit: `2caff9d00d24020969a7744880101475d2afa9d2`.
- Flutter Validation run #63: `41112382633` — Analyze success, **320 tests passed**, Web release build success.
- Admin Web Build Check run #1307: `41112382557` — success (no deploy).
- Flutter CI version: stable **3.47.9**.
- The CI log explicitly recorded passing tests in all six focused files: `add_zone_screen_test.dart`, `zone_directory_screen_test.dart`, `zone_details_screen_test.dart`, `boundary_review_screen_test.dart`, `zone_approval_queue_screen_test.dart`, and `services/service_boundary_preview_validator_test.dart`.
- No Firebase integration, merge, or deployment was performed.

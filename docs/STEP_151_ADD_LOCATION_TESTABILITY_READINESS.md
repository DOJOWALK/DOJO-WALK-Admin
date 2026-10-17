# Step 151 — Add Location Testability Readiness

Date: 2026-10-18

## Inspection
Reviewed the current `AddLocationDialog`, `ServiceLocationService`, `pubspec.yaml`, model definitions, and parser tests on `step-119-boundary-geometry`.

## Findings
- `ServiceLocationService` accepts optional `FirebaseFirestore` and `FirebaseFunctions` instances, which is helpful for dependency injection.
- The Admin test dependencies currently include `flutter_test` and `flutter_lints`; there is no existing mocking/fake-Firebase package declared in `pubspec.yaml`.
- `AddLocationDialog` currently creates and calls the concrete service directly. A widget test that exercises the full dialog would need a safe test seam for Firestore streams, writes, and callable functions. Adding an unverified mock setup or connecting tests to real Firebase would be unsafe.
- The dialog's parent-reset behavior is currently inline in dropdown callbacks: Country clears State/City/Area; State clears City/Area; City clears Area. The behavior is simple, but currently not isolated as a pure testable unit.
- The CSV parser already has broad unit coverage for reordered headers, duplicate/empty headers, malformed quotes, row shape, missing values, and duplicate combinations. No additional parser behavior was changed in this step.

## Decision
Do not write a widget test that risks using live Firebase, and do not add a new test dependency without confirming a compatible approach.

## Next implementation slice
Extract the Add Location parent-selection/reset logic into a small pure Dart state helper and add unit tests for each parent change. Wire the dialog to that helper while preserving its current UI, save behavior, collection names, and persisted schema. Then run the existing Admin CI workflows.

## Status
This step is a source/dependency audit only. No app code, Firebase data, rules, callables, or UI behavior changed. No merge, deployment, import, or activation was performed.

# Step 150 — Add Location and CSV Preview Audit

Date: 2026-10-18

## Files inspected
- `lib/features/service_location/widgets/add_location_dialog.dart`
- `lib/features/service_location/services/location_csv_preview_parser.dart`
- `test/features/service_location/services/location_csv_preview_parser_test.dart`
- Current directory inventory for Service Location screens, services, widgets, and tests.

## Findings

### 1. Add Location UI follows the current legacy hierarchy
The dialog offers Country, State, **City / District**, Area / Sub-district, and Locality / Village. Its save path creates a `ServiceCity` directly under State and a `ServiceArea` directly under that City. There is no separate District entity or District selection in this dialog.

This is consistent with the existing model/backend contract found in Steps 143–145, but it does **not** yet implement the requested four distinct administrative source columns as separate Firestore service entities. Do not rename the current City field to District or silently create a District until the hierarchy contract is approved and backend support is coordinated.

### 2. Parent selections are reset when the parent type changes
Country selection clears State, City, and Area; State selection clears City and Area; City selection clears Area. The save path re-reads the selected City before creating Area/Locality, and locations are initially saved inactive. This is a useful defensive pattern.

### 3. CSV preview remains read-only
The parser documents State, District, City, and Area as required headers; normalizes case/spaces/underscores/hyphens; rejects empty/duplicate headers and missing required headers; and maps row values by normalized header indexes. The parser has no Firebase dependency and is explicitly a preview parser, not an import/activation authorization path.

### 4. Current test coverage is service-level
The Service Location test directory contains parser tests, LGD staging parser tests, and geometry tests. No dedicated Add Location dialog widget test was found in that directory inventory. This is an opportunity for a small UI regression test, but it should avoid depending on production Firestore.

## Recommended next safe slice
Add focused widget tests for Add Location's hierarchy labels and parent-selection reset behavior using a fakeable service seam or a minimal mock, without changing the persisted schema. First inspect the service constructor/dependencies and existing test dependencies to choose the smallest reliable approach.

## Safety decision
No schema, UI behavior, Firestore data, backend callable, rules, or production location was changed in this audit. No merge, deployment, import, or activation was performed. The tested CI checkpoint from Step 149 remains PASS for its two named workflows; this audit itself is source inspection only.

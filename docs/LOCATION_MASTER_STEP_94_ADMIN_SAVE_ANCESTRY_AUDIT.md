# Step 94 — Admin Save Workflow Ancestry Audit

Date: 2026-10-17

## Findings

Reviewed `ServiceLocationService.saveState/saveCity/saveArea/saveLocality` and hierarchy guard tests.

- State save already requires an existing Country.
- City save already requires Country and State and checks the State-to-Country link.
- Area save previously required its City and checked the City's embedded Country/State IDs, but did not independently require the referenced Country and State documents to exist.
- Locality save previously required its Area and compared IDs against the Area, but did not independently require the Country, State, and City documents to exist. A legacy/malformed Area record could therefore allow a save attempt to progress too far before Firestore Rules rejected it.
- Parent reparenting is already rejected and status remains preserved on edit; service-status changes continue through trusted backend callables.

## Changes

- Added defense-in-depth reads in Area save: require Country and State docs and verify State.countryId, City.countryId and City.stateId all agree.
- Added defense-in-depth reads in Locality save: require Country, State and City docs and verify each parent link agrees with the selected Area's full hierarchy.
- Added unit regression tests for an Area pointing to a missing State and a Locality pointing through an Area to a missing City. Both assert the invalid child document is not created.
- Step 93's offline JSON snapshot audit utility remains available for existing-data audit. It does not connect to Firebase. A real snapshot/export has not been supplied, so no existing live data findings are claimed.

## CI / safety status

- Admin Flutter Web Validation is running for the new commits. Check the latest run before marking this step passed:
  - Service update commit: `9eb7ea180e424aa5bed3f0f153c02984715ca5ce`
  - Test update commit: `f3eb438c967a97f4e65ca01011963995a581eebc`
- No production Firestore read, write, import, activation, or deployment was performed.
- Fresh official LGD row-level reconciliation and authoritative contiguous polygon verification remain release gates.

## Next

Verify Admin Flutter Web Validation. Then prepare the snapshot schema and request an authorized read-only export for the existing-data audit; do not access production data without explicit authorization.

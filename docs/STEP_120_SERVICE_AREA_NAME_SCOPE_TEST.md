# Step 120 — Service Area Name Scope Regression Test

## Change
Added a CSV preview parser regression test proving that the same Area label (for example, “Sector 1”) is allowed under two different Service Cities in the same State and District. Duplicate detection must use the full State/District/City/Area combination, not the Area label alone.

## Validation
- The focused geometry/parser workflow is triggered by this test file.
- Full Admin analyze/test/release build workflow is triggered by the change; result pending at report creation.

## Safety
- Test-only change; no Firestore records or production behavior changed.
- CSV remains preview-only; no location import/write is enabled.
- No merge, deployment, activation, or production import performed.
- Partner and Customer work remains deferred until Admin is completed and merged.

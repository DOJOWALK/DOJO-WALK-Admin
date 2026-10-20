# India Location Master Bootstrap Runbook

This runbook is for the Admin Service Locations feature on branch `feature/service-locations-premium-3d-ui`. It does not connect to or inspect production Firestore by itself.

## A. Create the India Country record

1. Open Admin → Service Locations.
2. Use **Add Country**.
3. Enter:
   - Country name: `India`
   - Country code: `IN`
4. Save. The Country is intentionally created inactive.
5. In the Country list, use the trusted activation action only after confirming the name/code and the correct Firebase project. Country activation does not mean any City/Area service boundary is approved.
6. Confirm the Country appears in the list and the status is active before importing a CSV.

Do not create a second India record if one already exists. Search the Country list first. If duplicates or unexpected records are found, stop and reconcile them.

## B. Prepare a CSV

Use `data/templates/service_location_import_template.csv`. The exact required headers are:

`State,District,City,Area`

- One row represents one complete State → District → City → Area path.
- Repeat parent names on each row; the planner resolves duplicate paths into shared parent records.
- Keep names exactly as they should appear in the admin UI; the importer normalizes whitespace/case for path matching.
- Do not put PIN codes or village/locality values into the Area column unless the team has explicitly approved that mapping.
- The India LGD sub-district reference files are not the same thing as City or Area service polygons. Confirm source-code mapping and geography semantics before using them to populate these columns.
- Every run is limited to 300 planned nodes, including parent nodes. Split large files into parent-complete chunks and use a unique Run ID for each new import.

## C. Pilot import

1. Start with a small, reviewed file (a few complete paths) and verify source names and parent relationships first.
2. In Service Locations, open the CSV preview and fix every validation error.
3. Select the active India Country.
4. Save the Run ID and SHA-256 fingerprint shown in the confirmation dialog.
5. Read the warning, tick the explicit confirmation checkbox, and run the import.
6. Verify the result counts: planned, created, reused.
7. Inspect the State/District/City/Area records. New records must remain inactive.
8. If a timeout or partial error occurs, do not retry with a fresh Run ID. Preserve the original Run ID and fingerprint and reconcile the original run before continuing.

## D. Before service activation

- Country/State/District records provide hierarchy; they do not prove service coverage.
- City/Area service activation must wait for a real contiguous polygon boundary to be reviewed and verified through the trusted boundary workflow.
- Never substitute a radius, bounding circle, guessed polygon, or fabricated coordinates for a verified boundary.

## E. What this repository can and cannot confirm

The code repository confirms the importer implementation and workflow. It cannot prove live Firestore document counts or current production records. Confirm the Firebase project and collections in Firebase Console before running the first production import.

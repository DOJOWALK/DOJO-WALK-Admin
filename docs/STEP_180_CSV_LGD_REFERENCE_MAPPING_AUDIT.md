# Step 180 — CSV Preview vs LGD Reference Data Mapping Audit

Date: 2026-10-18
Branch: `step-119-boundary-geometry`

## Scope
Read-only audit of the four-column CSV preview contract, the India State/District/Sub-District reference files, and the new reference-filter tests. No application schema or production data changes.

## Confirmed current behavior
- CSV preview requires four source columns: State, District, City, Area.
- The parser normalizes those columns to four name values and checks row syntax, missing values, field counts and duplicate State/District/City/Area combinations.
- CSV preview is not connected to a production Firestore write path.
- Reference State records have an integer LGD State code and a String Census 2011 code.
- Reference District records preserve LGD State/District codes and Census codes as strings; this matters for source fidelity and leading zeroes.
- Reference filters use State LGD code to filter districts, and both State + District LGD codes to filter sub-districts.
- Existing Service Location model is still Country → State → City → Area → Locality. District is not a separate service entity.

## Mapping gap to resolve before importer implementation
The current four-column CSV contract carries names only; it does not explicitly capture:
- Source dataset name and version/date.
- State LGD code and State Census code as separate identifiers.
- District LGD code and District Census code as separate identifiers.
- Source row number or deterministic source-row fingerprint.
- Whether the City column means administrative city or DOJO service grouping.
- Whether Area means a source administrative unit or DOJO service coverage boundary.

These cannot be inferred safely from display names. Similar names may occur under different parents, source codes can change, and reference data does not supply verified DOJO service polygons.

## Safe next implementation slice
After the source/product gate is answered:
1. Keep the existing four-column CSV preview compatible.
2. Introduce a separate versioned staging/preview contract for source codes and provenance rather than silently changing the meaning of existing columns.
3. Validate codes as strings; preserve leading zeroes.
4. Detect duplicate codes in their correct parent scope, missing parent codes, and name/code conflicts.
5. Display row-level diagnostics and source provenance.
6. Keep all import behavior preview-only until separately approved.
7. Do not create service records, verified boundaries, or active coverage from administrative reference data.

## Approval gate remains open
The five questions in Step 145 remain unresolved:
1. Is source City an administrative City or a DOJO service grouping?
2. Can a Service City belong to one District only?
3. Must each Area belong to one Service City?
4. Are imported records reference-only until explicitly created/verified by an admin?
5. Which source/version and stable codes are authoritative for each column?

## CI snapshot
For test commit `bbb151c120cc79eb1c29a4cfc407f11c92505720`:
- Geometry Unit Tests: success, run [39077899734](https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39077899734).
- Admin Web Build Check: in progress when checked, run [39077899713](https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39077899713). No final result is claimed here.

## Safety
Admin PR #7 remains Draft and unmerged. No Firebase schema changes, production import, deployment, activation/deactivation, or Partner/Customer migration occurred.

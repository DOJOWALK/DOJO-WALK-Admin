# DOJO WALK Admin — Step 121: Closed GIS Polygon Ring Support

## Change
- Geometry validation now accepts both open rings and standard closed GIS/GeoJSON-style rings where the final coordinate repeats the first.
- Containment checks normalize parent and child rings before validating edges, avoiding a false zero-length closing edge.
- Added regression tests for closed-ring validity and closed parent/child containment.

## Safety and scope
- This is local geometry validation only; no Firestore records, location boundaries, imports, or activation states were changed.
- No deployment or merge was performed.
- CI was triggered by the code/test commits and must pass before this change is treated as validated.

## Why this matters
Official GIS boundary sources commonly represent polygon rings with a repeated closing coordinate. The Admin geometry validator should not reject a valid ring solely because it uses that standard representation.

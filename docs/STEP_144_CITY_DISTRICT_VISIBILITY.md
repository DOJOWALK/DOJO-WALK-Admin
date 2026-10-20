# Step 144 — City-to-District relationship visibility

## Change
- City cards now show the linked District name when districtId is present.
- Legacy Cities without districtId are explicitly labeled "Not linked (legacy City)" rather than implying they belong to a District.
- City search now includes District name/ID alongside City, State, and Country fields.
- This is a read-only UI change; it does not migrate legacy records or change activation rules.

## Validation
- Service Location Geometry Tests: pending workflow.
- Admin Web Build Check (No Deploy): pending workflow.

## Follow-up audit
- Area model currently records Country, State, and City but does not have a District field.
- Backend trusted-write allow-list and hierarchy checks also need a coordinated review before introducing District-aware Area ancestry.
- No production data was changed. No import, deployment, or PR merge was performed.

# DOJO WALK Admin — India Location Click Flow

Status: implementation specification for the next UI change. This document does not claim the UI is already implemented.

## Goal
Replace the current flat location-tab experience with a guided, parent-child browsing flow for India. Keep the existing Firestore collections and trusted callable activation checks unchanged.

## Navigation
India (fixed country master record)
→ State
→ District
→ City
→ Area
→ Locality
→ Manage Service
→ Review Activation
→ Confirm Activation

A user may open a level only after selecting its parent. Breadcrumbs must show the current path and provide safe navigation to ancestors.

## Main Service Locations screen
- Show India as a fixed country (code IN); do not ask for country name/code.
- Primary action: Open States.
- Global search accepts state, district, city, area, locality, and PIN/code. Search results must display the full parent path and must not bypass permissions or activation validation.
- Keep Add Location available.
- Keep boundary preview and import history available as secondary tools, not as the main navigation.

## Every hierarchy list
- Search within the current level.
- Filter: All / Active / Inactive.
- Show record status and service status separately where supported by the model.
- Inactive records remain visible and openable; do not filter them out by default.
- Each row has an explicit Open action and an Add Child action where appropriate.
- Empty, loading, and error states must be clear.

## Service status and safety
- Location record status and customer-facing service status are different concepts; never conflate them.
- Activating one locality must not activate sibling localities or any parent/child automatically.
- Customer booking eligibility is the result of the target location's service status plus every required ancestor's eligibility.
- A City or Area must have a verified polygon boundary before activation; radius-only coverage is not verification.
- A Locality may rely on its valid parent/coverage mapping and does not need its own polygon by default.
- Final activation must use the existing trusted server callable; UI-only checks are not a security boundary.
- Review must show full location path, current statuses, boundary verification, parent eligibility, and the exact action being confirmed.
- If a parent is ineligible or boundary is not verified, disable activation and explain why.
- Do not auto-activate children when a parent is activated.

## Suggested implementation sequence
1. Introduce guided hierarchy navigation without changing Firestore schema or trusted callables.
2. Add All / Active / Inactive filtering at each level while preserving inactive records.
3. Add a Manage Service review panel showing status, path, boundary, and parent eligibility.
4. Verify activation/deactivation goes through existing trusted callables.
5. Run formatter, analyzer, unit/geometry tests, full validation, and web build before proposing merge.
6. Test with Firestore/emulator data for active and inactive parent/child combinations, including a single locality activation.

## Acceptance criteria
- No manual country name/code entry.
- A user can navigate India → State → District → City → Area → Locality.
- Inactive records can be searched and opened.
- Activating one locality does not alter any sibling record.
- Ineligible ancestors or unverified City/Area boundaries prevent activation.
- Existing import, boundary, and legacy-zone workflows remain available and unchanged.
- No claim of completion until CI and relevant tests have been checked.

# DOJO WALK Company Flow and Repository Structure

Last updated: 2026-10-20  
Status: Architecture guide / target structure. This document does not certify that every listed feature is implemented or production-ready.

## 1. Company-wide operating flow

Use one company workflow across the repositories; do not create a separate identity or location system per app.

```text
DOJO WALK Company
  ├── Company & System Management
  │   ├── Company profile and companyId
  │   ├── Admin accounts, roles and permissions
  │   ├── System configuration and audit trail
  │   └── Release / deployment controls
  ├── Dashboard & Operations (single command center)
  │   ├── Company KPIs and booking status
  │   ├── Live Operations overview + Open Live Operations map
  │   ├── Recent bookings and operational alerts
  │   └── Walker availability and assignment
  ├── India Location Master
  │   └── Country → State/UT → District → City → Area/Sub-district → Locality/Village
  ├── Customer
  │   ├── Authentication and profile
  │   ├── Dogs and saved addresses
  │   ├── Service availability and booking
  │   ├── My bookings / live walk
  │   └── Help and support
  ├── Walker / Partner
  │   ├── Application and document review
  │   ├── Eligibility and service coverage
  │   ├── Assigned walks and live walk
  │   └── Completion and earnings
  ├── Business
  │   ├── Services, pricing and coupons
  │   └── Payout / commission policies
  ├── Support & Communication
  │   ├── Customer / walker cases
  │   └── Approved notifications and communication
  └── Reports & Audits
      ├── Operations and booking reports
      ├── Location / import audit
      └── Security and release evidence
```

These are company-level functional groups. They do not mean every group already has a complete screen or backend.

## 2. Repository ownership

| Repository | Owns | Must not become the source of truth for |
|---|---|---|
| `DOJO-WALK-Admin` | Company operations UI, location master management, boundary review, administrative workflows | Customer-only or Partner-only UI |
| `DOJO-WALK-Firebase` | Shared Firestore Rules, callable Functions, trusted server-side validation and shared backend contracts | App-specific presentation/UI |
| `dojo-walk-customer` | Customer authentication/profile, dogs, customer addresses, booking and walk views | Admin-managed service-location activation |
| `dojo-partner` | Partner onboarding, documents, eligibility, assigned walks and live walk | Company-wide location master writes |
| `DOJO-WALK-Website-` | Public company website and enquiry entry points | Authenticated app/admin workflows |

Each repository has its own Git branch and release pipeline. Coordinate them using shared contracts and this cross-repository flow; do not assume one branch spans multiple repositories.

## 3. Shared contract rules

- Use a stable company-wide `companyId` and canonical location IDs where the schema supports them; do not invent app-local IDs for the same entity.
- Keep parent references explicit: country, state/UT, district, city, area and locality must not be inferred from display labels alone.
- Keep government/source codes (for example LGD codes) in separate source-code fields; do not use a display name as an identifier.
- Keep customer pickup addresses separate from the service-area master.
- The Admin UI may create a location record as inactive. City/Area activation must remain a separate, trusted operation requiring a verified valid polygon and valid parent chain.
- Boundary review, location activation, import, and customer booking are separate lifecycle steps.
- CSV preview/validation is not a production import. Do not write imported reference data into production until schema review, dry-run, audit and rollback plan are approved.
- Client UI is not a security boundary. Authorization and trusted mutations belong in Firebase Rules and/or callable Functions, with emulator tests.

## 4. Recommended file placement

### Admin — `DOJO-WALK-Admin`
- `lib/app/`: app composition.
- `lib/screens/dashboard/admin_shell.dart`: company navigation shell; Dashboard is the primary command center and Live Operations is launched from the Dashboard action instead of occupying a separate sidebar item.
- `lib/screens/dashboard/dashboard_screen.dart`: company KPIs, booking status, live overview, recent bookings, alerts, activity and the Live Operations entry action.
- `lib/core/`: shared constants, errors, routing, theme and utilities.
- `lib/data/reference/india_locations/`: generated, versioned read-only India reference data.
- `lib/features/service_location/models/`: location and boundary data models.
- `lib/features/service_location/services/`: repository/Firestore calls, validation and lifecycle orchestration.
- `lib/features/service_location/screens/`: page-level Service Locations workflow.
- `lib/features/service_location/widgets/`: Add Location dialog, boundary editor, reusable form controls.
- `test/features/service_location/`: focused tests for form state, parent selection, validation and boundaries.
- `docs/architecture/`: company flow, cross-repository contracts and architecture decisions.
- `docs/runbooks/`: deploy/test/recovery instructions.
- `docs/reports/`: dated verification reports. Keep historical step reports intact; do not bulk-move/delete them without reviewing links and workflow references.

### Shared Firebase — `DOJO-WALK-Firebase`
- `functions/`: callable Functions and server-side validators.
- `firestore.rules` / `storage.rules`: authorization policies.
- `tests/` (or the repository's established test path): emulator and contract tests.
- `docs/architecture/`: canonical payload/schema contracts and migration plans.
- `.github/workflows/`: separate test, deploy and verification workflows.

### Customer and Partner
Keep feature code in each app's own `lib/features/<feature>/` grouping. Shared contracts should be documented/versioned, not copied as whole app folders. Preserve each app's current package names, routes and working file paths until a path migration is tested.

## 5. Service Location workflow

1. Load/select existing Country.
2. Select State/UT.
3. Select District and City according to the agreed schema contract.
4. Select or create Area/Sub-district, then optional Locality/Village.
5. Save new records inactive.
6. Draw or load the geographic polygon and validate geometry.
7. Submit the boundary for review.
8. Use the trusted Firebase operation to approve the boundary and activate coverage.
9. Verify active status and parent/name-index consistency.
10. Confirm Customer availability and Partner eligibility read the same canonical active location IDs.

If a dropdown shows “No countries found”, treat it as a data-loading/configuration/permission issue to diagnose; do not mask it with fake fallback data.

## 6. Change and release workflow

1. Read `docs/DEVELOPER_TEAM_CONTROL_CENTER.md` and the latest matching audit report.
2. Confirm repository, branch, base branch and current SHA before editing.
3. Inspect existing files and tests before moving or renaming.
4. Make the smallest coherent change; avoid duplicate services, models and navigation paths.
5. Run formatter, analyzer, unit/widget tests and release build for the affected app.
6. Run Firebase emulator/contract tests when schema, rules or callable payloads change.
7. Record exact changed files, commit SHA, CI run IDs and remaining blockers in a dated report.
8. Do not merge, deploy, import production data, or activate service coverage without explicit owner approval.

## 7. Dashboard and navigation update (2026-10-20)

- Live Operations was removed as a standalone left-sidebar item and is now opened from the Dashboard command-center action. Its dedicated map screen remains intact and is not deleted.
- Dashboard visual treatment now uses the DOJO WALK orange/cream palette, a raised gradient hero header, company overview copy and a prominent Live Operations action.
- Booking, Walker Management, Coupons and Service Locations navigation indexes were updated to match the removed menu item. These changes must be validated by CI before merge.
- This does not claim the live map/data stream is fully production-verified; it only updates the navigation entry point and dashboard presentation.

## 8. Current UI work boundary

The Service Locations page and Add Location dialog have a 3D-inspired orange/cream visual update on the review branch. This is a UI styling change only. It does not prove the country data source works, the company flow is fully implemented, or CI has passed. Keep the “No countries found” blocker visible until diagnosed and fixed.

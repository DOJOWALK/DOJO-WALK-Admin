# DOJO WALK Admin — Step 143: Service Address Schema Cross-Audit

Date: 2026-10-18
Branch: `step-119-boundary-geometry`
Status: Audit only. No production changes.

## Files inspected
- `lib/features/service_location/models/service_location_models.dart`
- `lib/features/service_location/widgets/add_location_dialog.dart`
- `lib/features/service_location/models/service_location_boundary.dart`
- `lib/features/service_location/services/service_location_service.dart`
- `docs/SERVICE_LOCATION_DISTRICT_CITY_SCHEMA_PROPOSAL.md`
- `docs/LOCATION_LGD_STAGING_DESIGN.md`

## Confirmed mismatches

### 1. District and Service City are currently combined
The model and Add Location UI use a single `ServiceCity` type and label it `City / District`. Its current fields include `countryId`, `stateId`, and `name`, but no distinct `districtId` or `service_districts` model. This does not match the import source's separate State, District, City and Area columns.

**Impact:** an import row cannot safely represent all four meanings without an approved schema/mapping decision.

### 2. Area is attached directly to the combined City/District
The Add Location flow creates `ServiceArea` with the selected city's `countryId`, `stateId`, and `cityId`. There is no separate district parent in this flow.

**Impact:** do not import a district as a city or an LGD sub-district as a DOJO service area by name alone.

### 3. Locality remains an optional administrative feature, but the Add Location flow requires a parent Area
The locality form asks for a City and Area and writes a `ServiceLocality`. Customer-entered house/society/landmark/pickup information is a separate booking-address concern and should not be forced into the service coverage hierarchy.

**Impact:** preserve optional locality records for admin/reference use, but customer booking should be able to supply its own address without requiring a locality master record.

### 4. Boundary validation and activation are separate, correctly guarded concepts
The boundary model validates location ID/type, source metadata and at least three distinct valid points. The service uses trusted callable Functions for activation. However, basic point-count/range checks alone do not establish that a polygon is authoritative, non-self-intersecting, contiguous, or geographically correct.

**Impact:** keep boundary verification and activation separate; require review and geometry checks before activating service coverage.

### 5. LGD staging design correctly forbids treating administrative reference data as service coverage
The existing staging design says state/district/sub-district data must remain read-only staging, and must not create service cities/areas or infer polygons. The schema proposal is explicitly unapproved.

**Impact:** do not implement CSV-to-Firestore writes until the City/District meaning and import contract are approved.

## Step 143 decision
The current code is internally aligned with the existing hierarchy (Country → State → City/District → Area/Sub-district → optional Locality), but it is not yet aligned with the proposed four-column State/District/City/Area import contract.

No silent schema change is safe. The next implementation gate is to settle the canonical schema before changing models, Firestore Rules, trusted Functions, import parser, or tests.

## Recommended canonical contract for review
- `State`: administrative reference from a reconciled LGD snapshot.
- `District`: separate administrative entity with source code and State parent.
- `Service City`: explicit DOJO service coverage grouping under the chosen District/State; never inferred automatically from District name.
- `Service Area`: DOJO coverage polygon under a Service City; must have reviewed boundary before activation.
- `Customer Service Address`: customer-entered address fields used for pickup/booking; not a polygon and not dependent on a locality master.
- `Locality/Village`: optional reference data only unless a separately approved feature requires it.

## Next step
Step 144 should inspect the Firebase review branch's Firestore Rules and trusted Functions for the exact current allowlists and callable payloads. Then prepare a coordinated Admin + Firebase implementation checklist and tests. Do not modify only the client model; Rules and server-side validation must change together.

## Safety
No production writes, imports, activations, deployments, merges, or Partner/Customer migrations occurred.

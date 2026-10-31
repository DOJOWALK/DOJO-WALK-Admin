# Admin Live GPS Freshness & Route Session — Draft Specification
Date: 2026-11-01
Team: 02 — Admin App
Status: **DRAFT / NOT APPROVED / NOT IMPLEMENTED / NOT TESTED**
Related: POL-007 Live Walk & Safe Handover; POL-016 Incident & Emergency Management; ADM-P0-02 Incident & Safe-Handover draft; Team 01 GPS/location contract.
Tracking PR: #51 (Draft, unmerged)

## 1. Purpose and non-negotiable principles
Define how Admin distinguishes a Walker's online presence from a verified fresh location and how it displays only the route belonging to one specific walk/session.

- `isOnline == true` means presence/availability only; it does **not** prove a walk is active, GPS is fresh, or the Walker is at the displayed position.
- A last-known coordinate must never be presented as a live verified position without a freshness indicator and its observation time.
- Route points from different walks/sessions must never be combined into one polyline.
- Missing, stale, inaccurate, delayed, or out-of-order GPS data is uncertainty, not proof of location or misconduct.
- Never fabricate route points, timestamps, accuracy, walk completion, or a live status.
- Emergency response must not wait for GPS recovery or internal approval.

## 2. Source audit baseline (read-only findings)
The Team 02 source audit of Admin Live Operations found:
1. Online Walker stream is filtered by `walkers.isOnline == true`.
2. Marker parsing accepts `currentLocation` as GeoPoint or latitude/longitude map; marker path has no location-age or accuracy validation.
3. UI `LIVE` derives from `isOnline == true`, not fresh GPS or an active walk.
4. Route history is fetched from `walk_locations` filtered by `walkerId`, ordered by `timestamp` ascending, limited to 300.
5. Route query does not filter by `walkId` or `bookingId`, and has no explicit session boundary, time window, freshness/accuracy rule, or pagination control.
6. With ascending order and a 300-record limit, a long history can return the oldest 300 points rather than the latest 300.

These are findings from inspected Admin paths, not a statement that all backend data sources have been inspected or that Firebase currently guarantees a particular schema.

## 3. Proposed Admin location states
The UI should render distinct states, with exact thresholds and status semantics supplied by Team 01 / approved policy:

| State | Meaning | Admin presentation |
|---|---|---|
| Fresh | Latest valid point is within approved freshness threshold and passes approved accuracy/validation rules | Show “GPS fresh” with observed-at time and accuracy when supplied |
| Delayed | Point exists but exceeds fresh threshold while remaining within approved delayed window | Show “GPS delayed”; visibly age the point |
| Stale | Point exceeds approved stale threshold | Show “Last known location — stale”; do not use live marker styling |
| Unavailable | No usable location is available | Show “GPS unavailable”; no fabricated marker |
| Invalid | Coordinates/timestamp/accuracy fail validation | Suppress invalid point; show data-quality warning |
| Unknown | Required metadata is absent or cannot be interpreted | Show “GPS status unknown”; do not infer freshness |

Do not hard-code numeric freshness thresholds in Team 02. Team 01 and policy owner must approve thresholds for fresh, delayed, stale, and incident escalation, considering GPS update interval, device/background restrictions, network delay, and operating conditions.

## 4. Presence, walk state, and GPS state are independent
Admin must display three separate dimensions:
- **Presence:** online / offline / unknown (presence source and observed time).
- **Walk:** active / not active / state unknown (authoritative active walk/session reference).
- **GPS:** fresh / delayed / stale / unavailable / invalid / unknown.

Examples:
- Online + no active walk + stale GPS is not a live walk.
- Online + active walk + unavailable GPS is a tracking gap, not proof the Walker stopped.
- Offline + active walk requires a safety/operations warning based on policy; it must not silently disappear from active operations.
- Fresh GPS without an active walk is a fresh location observation, not a live walk.

Remove or replace any single “LIVE” badge that collapses these dimensions. If product keeps a summary badge, its exact meaning must be explicit and backed by authoritative walk state plus GPS freshness.

## 5. Canonical route-session identity
A route displayed for an active or historical walk must be scoped to a canonical unique session:
- `walkId` (required authoritative identifier)
- `bookingId` (required relationship/reference where applicable)
- `walkerId` (required actor)
- `sessionId` or route-session identifier (required if a walk can have multiple tracking sessions/restarts)
- session start/end timestamps and status
- ordered point sequence / server timestamp
- source timestamp and received timestamp where available
- coordinates and accuracy metadata
- integrity/sequence metadata where available

Team 01 must declare the canonical schema and whether `walkId` alone uniquely identifies one uninterrupted route session. Team 02 must not invent `sessionId`, collection paths, field names, or callable names and must not assume legacy points can be safely joined.

## 6. Route query and rendering requirements
- Query by exact authorized `walkId` and canonical session identifier; validate bookingId and walkerId relationship from trusted records.
- Apply server-side authorization and geographic/resource scope; client-supplied IDs are selectors, not proof of permission.
- Sort by a stable, documented ordering (server timestamp plus sequence/tie-breaker where needed).
- Use cursor pagination; do not rely on a fixed first-page ascending limit for long routes.
- Historical route and live route updates must use the same session boundary and deduplicate by canonical point identity.
- Do not join points from another walk, booking, walker, or session, even if timestamps overlap.
- Handle late/out-of-order points without silently reordering into a misleading path; preserve source order and flag anomalies according to contract.
- Handle gaps explicitly; do not draw a continuous line across a material tracking gap unless product/policy explicitly defines the visual treatment.
- Route should indicate session start/end and missing segments where supported.
- Empty route is “No route points received”, not “Walker did not move”.
- Partial route is labelled partial; a completed walk with missing route data is not automatically a completed GPS audit.
- Export/download of route evidence is a separate permissioned action, not implied by map read access.

## 7. Freshness and accuracy calculation
Freshness must be calculated from a trusted, documented timestamp field and a server-approved clock basis. The UI must not use local device receipt time as if it were GPS observation time.

Required metadata contract:
- observation timestamp (when device measured location)
- server received timestamp (when backend accepted it)
- accuracy value and unit, if available
- source/device/session identity sufficient to prevent cross-session contamination
- validation outcome and reason when rejected
- server-side normalized status or approved thresholds/version, if backend owns classification

If device timestamp and server receipt timestamp diverge, expose the discrepancy or use the backend-approved authoritative value. Do not silently substitute one for another. Accuracy missing must be shown as unknown, not zero or perfect.

## 8. Live Operations map and list UX
Walker/active-walk list should show:
- Walker identity (minimum necessary)
- presence status and last presence update
- active walk status and walk ID/booking reference as authorized
- GPS status and last observed time
- accuracy (with unit) if supplied
- tracking gap duration only when computed from approved timestamps
- warning/incident link where a tracking gap meets approved escalation criteria

Map behavior:
- Fresh: current marker with observed-at time.
- Delayed/stale: visually distinct last-known marker and explicit age; never “LIVE”.
- Unavailable/invalid/unknown: no misleading current-position marker; show state in list/detail.
- Selecting a Walker must require selecting the exact active/historical walk session before drawing a route.
- A route legend explains fresh/late/gap/invalid points only if the backend supplies enough metadata.
- Do not expose precise location to roles outside approved geographic and operational scope.

## 9. Incident and safety linkage
When an active walk's GPS becomes delayed/stale/unavailable:
1. Preserve last verified point and observation time.
2. Display uncertainty; do not claim current position.
3. Apply only the approved escalation thresholds and notification contract.
4. Track notification sent, delivery result, acknowledgement and backup escalation separately.
5. If safety cannot be established, follow POL-016 and ADM-P0-02; do not wait for GPS recovery before urgent emergency action.
6. Do not auto-stop or auto-complete a walk solely because GPS is missing unless an approved trusted safety contract explicitly defines that action and its safeguards.

## 10. Team 01 required decisions and evidence
Team 01 must provide exact branch + commit SHA and answer:
- Canonical location point schema, collection/path, required fields, timestamp semantics and coordinate validation.
- Canonical active walk/session source and relationship between bookingId, walkId, walkerId and sessionId.
- Whether a walk may have multiple route sessions due to app restart, reconnect, device change or handover.
- Fresh/delayed/stale thresholds and accuracy policy, including missing accuracy behavior.
- Server-side route read authorization and City/Zone scope checks.
- Query indexes, ordering, cursor pagination, retention and maximum route size.
- Deduplication and out-of-order point handling.
- Whether live updates are supported and how snapshot history is reconciled with live stream.
- Tracking-gap alert thresholds, recipients, acknowledgement and backup escalation semantics.
- Data retention, deletion/legal hold and privacy controls for precise location.
- Emulator/test evidence: cross-walk isolation, cross-walker isolation, cross-session isolation, unauthorized read denial, sibling-zone/city denial, stale GPS classification, invalid coordinates, missing accuracy, delayed/out-of-order/duplicate points, pagination, and empty/partial route.

No Team 02 UI implementation or API integration should begin until the schema and authorization contracts are approved.

## 11. Planned acceptance checklist — NOT EXECUTED
- [ ] Online status alone never produces a “GPS fresh” or “active walk” claim.
- [ ] Active walk state is read from an authoritative source.
- [ ] Presence, walk state and GPS freshness are displayed independently.
- [ ] Freshness uses the approved observation timestamp and thresholds.
- [ ] Missing accuracy is unknown, not zero.
- [ ] Stale marker is explicitly labelled last known and shows age.
- [ ] Unavailable/invalid/unknown GPS does not create a false live marker.
- [ ] Exact walkId/sessionId isolates route points.
- [ ] Another booking's points cannot appear in the selected route.
- [ ] Another walker's points cannot appear in the selected route.
- [ ] A restarted/reconnected route session is handled per approved contract.
- [ ] Pagination can retrieve newest and older points without truncating silently.
- [ ] Stable ordering and duplicate handling are tested.
- [ ] Out-of-order points and material gaps are visible or flagged.
- [ ] Empty/partial route is not interpreted as no movement or successful tracking.
- [ ] Route access enforces server-side role and geographic scope.
- [ ] Location data is hidden from unauthorized roles.
- [ ] Tracking-gap escalation follows approved threshold and delivery contract.
- [ ] GPS failure alone does not silently stop or complete a walk.
- [ ] Mobile layout and accessibility support operations under time pressure.

Every item above is **PLANNED — NOT EXECUTED**.

## 12. Explicit non-decisions and guardrails
- No numeric freshness or accuracy threshold is approved here.
- No Firestore schema, index, collection, callable, or API name is approved here.
- No assumption that `isOnline` means an active walk or fresh GPS.
- No assumption that `walkId` and `sessionId` are interchangeable.
- No permission to broaden precise-location access or export.
- No Firebase/Firestore Rules/Functions/schema/production data changes.
- No Admin API wiring or runtime UI changes.
- No Emulator tests, CI run, merge or deployment performed for this documentation-only task.
- PR #51 remains Draft and unmerged.

## 13. Status
This is a Team 02 requirements draft based on the inspected Admin source audit. Team 01 contract, policy-owner approval, implementation, automated tests, Emulator evidence, operational drill, and exact-head CI are pending. Do not mark complete or launch-ready.

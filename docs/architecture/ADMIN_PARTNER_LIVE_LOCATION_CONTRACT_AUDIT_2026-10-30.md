# Admin ↔ Partner Live Location Contract Audit

- Checked: 2026-10-30
- Status: Source-level integration gap confirmed; **not an approved schema or production change**.
- Notion source: [Cross-App Live Tracking & Booking Data Contract — Readiness](https://app.notion.com/p/409756abedb9811bad58c5aea088be62?pvs=204)
- Scope: Admin Live Operations reader versus Partner Live Walk GPS writer.

## Exact source evidence

### Admin reader

Repository: `DOJOWALK/DOJO-WALK-Admin`  
Branch: `ui/notion-brand-foundation-2026-10-28`  
File: `lib/screens/live/live_operations_screen.dart`  
Blob: `841b4028dbfde736b69749dd11543cebb9329ba0`

Observed behavior:
- Subscribes to `walkers` where `isOnline == true`.
- Reads each marker from `walkers/{walkerId}.currentLocation`, accepting a GeoPoint or a map with numeric `latitude` and `longitude`.
- Loads route history from `walk_locations`, filtered by `walkerId`, ordered by `timestamp`, limited to 300 points.

### Partner writer

Repository: `DOJOWALK/DOJO-WALK-Partner`  
Branch: `chore/notion-aligned-structure`  
File: `lib/features/live_walk/screens/live_walk_screen.dart`  
Blob: `f035fa3410500ea9c798955c92e93c075a4e6132`

Observed behavior:
- Receives GPS updates from Geolocator and stores accepted positions in an in-memory route list.
- The inspected position handler updates local timer, distance and route state; it does not write `walkers/{walkerId}.currentLocation` or `walk_locations`.
- At walk end, writes a `walks/{walkId}` document containing a compacted `route` array.
- In the same client batch, updates `bookings/{bookingId}` to `completed` and records handover fields.

## Finding

**Confirmed source-level writer/reader mismatch:** the inspected Partner implementation does not populate either location source read by the inspected Admin Live Operations screen. Admin's route loader does not read Partner's final `walks.route` array. Therefore, these exact source branches do not yet establish an end-to-end Admin live marker/route feed.

This is a code-contract finding, not proof about current production runtime data.

## Risks

1. Adding direct client writes to `walk_locations` without a strict server-side authorization contract could expose or corrupt precise location data.
2. Writing `currentLocation` alone would make a marker appear but would not establish a route feed or location freshness.
3. Writing only a final route after walk completion is not live tracking.
4. No stale threshold, sample cadence, accuracy policy or approved retention contract is established by these two files.
5. Existing Admin UI presence must not be represented as successful backend integration.

## Required decisions before code changes

- [ ] Founder approval of POL-007 and its live-sharing window / stale-GPS policy.
- [ ] Select canonical live marker source and canonical route/event source.
- [ ] Decide whether a trusted backend ingests location or a narrowly scoped client write is permitted.
- [ ] Define active walk linkage: bookingId, walkId and assigned walker identity.
- [ ] Define server timestamp, device timestamp (if needed), accuracy, rate limits and idempotency.
- [ ] Define Admin area scope and cross-walker/cross-customer denial.
- [ ] Define route retention and stop-tracking behavior after walk completion.
- [ ] Add Firestore Rules/Functions Emulator tests for authorization, stale samples, walk-end behavior and privacy.
- [ ] Update Partner writer and Admin reader only after the shared contract is approved.

## Release gate

**NO-GO for live Admin integration.** No source code, Firestore rules, production data or Firebase deployment was changed by this audit. This document records evidence and prerequisites only.

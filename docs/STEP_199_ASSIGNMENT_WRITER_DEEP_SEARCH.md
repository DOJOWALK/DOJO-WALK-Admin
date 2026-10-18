# Step 199 — Assignment Writer Deep Search

Status: READ-ONLY REPOSITORY SEARCH. No application code, rules, database data, deployment, or pull request state changed.

## Scope

Searched GitHub code indexes for booking collection usage, `walkerId`, `assignedAt`, assignment terms, and Firebase callable handlers in:
- `dojoplatform2026/DOJO-WALK-Admin`
- `dojoplatform2026/DOJO-WALK-Firebase`
- `dojoplatform2026/dojo-partner`
- `dojoplatform2026/dojo-walk-customer`

Important limitation: GitHub code search indexes the default branch. Branch-specific reads were separately used for the Firebase review branch and Admin review branch in the previous audit. Search results are evidence from inspected/indexed paths, not a guarantee about every historical branch or unindexed file.

## Additional evidence

### Admin booking writes
Code-index searches for `collection('bookings')`, `walkerId =`, `assignedAt:`, and `walkerId` found:
- `lib/screens/bookings/bookings_screen.dart`: booking stream, status filters, and display of `walkerName ?? walkerId`.
- `lib/screens/dashboard/dashboard_screen.dart`: booking counts / dashboard stream.
- `lib/screens/live/live_operations_screen.dart`: reads booking records by `walkerId` to render live operations.
- `lib/features/walkers/services/walker_admin_service.dart`: reads bookings and writes walker approval state plus audit log.
No assignment-field write was identified in these matched Admin files.

### Firebase Functions
Recursive tree of the Firebase review branch shows `functions/src/index.ts`, location geometry module, and location boundary/activation/status tests. The inspected `index.ts` exports service-location boundary review, activation, and service-location status callables; the code-index search returned no booking assignment function or assignment terms. This does not exclude an external trusted server, unindexed file, or another deployment repository.

### Partner behavior
- `lib/screens/home/partner_home_screen.dart` queries `bookings` with `walkerId == current UID` and accepts active statuses such as `assigned` and `accepted`. This consumes assignments.
- `lib/screens/home/walk_details_screen.dart` changes booking status to `accepted` before navigation to pickup; it does not set `walkerId`.
- `lib/screens/home/navigation_screen.dart` updates lifecycle status only.
- `lib/features/live_walk/screens/live_walk_screen.dart` records a walk document with the current user's UID as `walkerId`; this is a `walks` record, not the booking assignment.
- Partner Firestore rules restrict a walker's booking updates to lifecycle fields and require the existing booking `walkerId` to match the signed-in UID. This prevents the partner app from serving as a general assignment tool.

### Customer behavior
Customer booking confirmation initializes `walkerId` as null and `status` as pending. The customer app reads and displays assignment state but no assignment writer was found in the inspected booking flow.

## Step 199 conclusion

Across the inspected paths, no authoritative writer that chooses a walker and assigns a booking was found. The current evidence suggests the assignment operation may be absent from the inspected application code, may exist in a separate/unindexed system, or may be performed manually outside these screens. Do not claim conclusively that it is absent from the entire organization until all deployment repos and relevant branches are confirmed.

## Implementation gate / next action

Before writing assignment code:
1. Confirm whether an external backend, Cloud Function, script, or manual Firestore workflow currently assigns bookings.
2. If no supported writer exists, design a single trusted assignment callable/transaction instead of allowing clients to set `walkerId`.
3. Define eligibility against approved+active walkers, active service City/Area IDs, booking status, schedule overlap, and any capacity/availability rules.
4. Make assignment idempotent and concurrency-safe; record `assignedAt`, actor/source, and an audit event.
5. Add emulator tests for unauthorized callers, inactive/unapproved walker, inactive/mismatched area, already-assigned booking, concurrent assignment, and legacy booking compatibility.
6. Keep service-location migration separate until the assignment contract and product questions are approved.

## Evidence links

- Admin bookings: https://github.com/dojoplatform2026/DOJO-WALK-Admin/blob/main/lib/screens/bookings/bookings_screen.dart
- Admin dashboard: https://github.com/dojoplatform2026/DOJO-WALK-Admin/blob/main/lib/screens/dashboard/dashboard_screen.dart
- Admin live operations: https://github.com/dojoplatform2026/DOJO-WALK-Admin/blob/main/lib/screens/live/live_operations_screen.dart
- Admin walker service: https://github.com/dojoplatform2026/DOJO-WALK-Admin/blob/main/lib/features/walkers/services/walker_admin_service.dart
- Firebase Functions: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/blob/step-138-partner-submission-negative-tests/functions/src/index.ts
- Firebase rules: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/blob/step-138-partner-submission-negative-tests/firestore.rules
- Partner home: https://github.com/dojoplatform2026/dojo-partner/blob/main/lib/screens/home/partner_home_screen.dart
- Partner walk details: https://github.com/dojoplatform2026/dojo-partner/blob/main/lib/screens/home/walk_details_screen.dart
- Partner navigation: https://github.com/dojoplatform2026/dojo-partner/blob/main/lib/screens/home/navigation_screen.dart
- Customer booking confirmation: https://github.com/dojoplatform2026/dojo-walk-customer/blob/main/lib/features/booking/screens/booking_confirmation_screen.dart

# Step 198 — Walker Assignment Path Audit

Status: READ-ONLY AUDIT COMPLETE; no runtime code, Firestore data, rules, or deployment changed.

## Repositories and revisions inspected

- Admin: `dojoplatform2026/DOJO-WALK-Admin`, branch `step-119-boundary-geometry`.
- Firebase: `dojoplatform2026/DOJO-WALK-Firebase`, branch `step-138-partner-submission-negative-tests`.
- Partner: `dojoplatform2026/dojo-partner`, branch `main`.
- Customer: `dojoplatform2026/dojo-walk-customer`, default branch.

## Findings

### Customer booking creation
`lib/features/booking/screens/booking_confirmation_screen.dart` creates a booking with `status: 'pending'` and `walkerId: null`. This is the expected unassigned initial state. Customer booking display reads `walkerId` but does not assign it.

### Admin
`lib/screens/bookings/bookings_screen.dart` reads and displays booking status and `walkerName ?? walkerId`; the inspected screen contains no assignment write.
`lib/screens/live/live_operations_screen.dart` reads bookings by `walkerId` for live operations and route display; no assignment write found.
`lib/features/walkers/services/walker_admin_service.dart` provides booking read streams and walker approval/rejection/suspension actions. Its `runAdminAction` transaction updates the walker profile and an audit log, not booking assignment.

### Firebase rules / Functions
In `firestore.rules` on the Firebase review branch, booking creation validates the initial booking including `walkerId == null`. Admin booking updates permit an allowlisted set that includes assignment-related fields such as `walkerId`, `assignedAt`, and status. This is permission to write, not an assignment algorithm.
The inspected `functions/src/index.ts` contains service-location boundary review, activation, and status callables. No booking/walker assignment callable was found in that file.

### Partner
`lib/screens/home/partner_home_screen.dart` queries bookings where `walkerId == current user UID`; this is a consumer of existing assignments, not the assigner.
`lib/screens/home/walk_details_screen.dart` updates booking status to `accepted` when proceeding to pickup; it does not set `walkerId`.
`lib/screens/home/navigation_screen.dart` updates booking status for walk progression; no assignment write found.
`lib/features/live_walk/screens/live_walk_screen.dart` writes walk lifecycle / walk-record data and includes the current user's UID in a walk record; that is not the booking assignment writer.
Partner rules allow assigned walkers to update constrained lifecycle fields only when the booking's existing `walkerId` matches their UID.

## Step 198 conclusion

The inspected paths do not identify a live application-side assignment algorithm or a dedicated Firebase callable that assigns a walker. Admin Firestore rules appear to allow an admin to write assignment fields, but the inspected Admin booking UI does not expose the assignment operation. This is a bounded search, not proof that no writer exists anywhere in every branch or uninspected file.

## Required before implementation

1. Search remaining Admin widgets/services and all Firebase Functions for writes to `bookings/{id}` that set `walkerId` or `assignedAt`, including alternate branches and scripts.
2. Decide whether assignment is intentionally manual in an uninspected admin tool or missing.
3. Define the authoritative assignment path and transaction: booking eligibility/status, walker approval and active state, service-area eligibility, duplicate/concurrent assignment protection, timestamps, and audit record.
4. Only then design the coordinated booking/walker location schema migration. Do not map legacy zone IDs to service areas automatically.
5. Keep all production writes, import/activation, deployment, and PR merge blocked pending explicit approval.

## Evidence links

- Admin booking screen: https://github.com/dojoplatform2026/DOJO-WALK-Admin/blob/step-119-boundary-geometry/lib/screens/bookings/bookings_screen.dart
- Admin live operations: https://github.com/dojoplatform2026/DOJO-WALK-Admin/blob/step-119-boundary-geometry/lib/screens/live/live_operations_screen.dart
- Admin walker service: https://github.com/dojoplatform2026/DOJO-WALK-Admin/blob/step-119-boundary-geometry/lib/features/walkers/services/walker_admin_service.dart
- Firebase rules: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/blob/step-138-partner-submission-negative-tests/firestore.rules
- Firebase Functions index: https://github.com/dojoplatform2026/DOJO-WALK-Firebase/blob/step-138-partner-submission-negative-tests/functions/src/index.ts
- Partner home: https://github.com/dojoplatform2026/dojo-partner/blob/main/lib/screens/home/partner_home_screen.dart
- Partner walk details: https://github.com/dojoplatform2026/dojo-partner/blob/main/lib/screens/home/walk_details_screen.dart
- Partner navigation: https://github.com/dojoplatform2026/dojo-partner/blob/main/lib/screens/home/navigation_screen.dart
- Customer booking confirmation: https://github.com/dojoplatform2026/dojo-walk-customer/blob/main/lib/features/booking/screens/booking_confirmation_screen.dart

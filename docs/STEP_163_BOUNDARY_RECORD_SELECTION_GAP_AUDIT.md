# Step 163 — Boundary Record Selection Gap Audit

Date: 2026-10-18  
Repository: `dojoplatform2026/DOJO-WALK-Admin`  
Branch: `step-119-boundary-geometry`

## Step 162 CI result

The Admin Web Build Check for the Step 162 test commit completed successfully:

- Workflow run: https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39073320852
- Commit: `254222031e330788d2cd564f444f7e9eadaf0abf`
- Conclusion: `success`

This validates the branch's configured CI for the replacement-boundary selection helper and its tests.

## Audit scope

Reviewed:
- `lib/features/service_location/models/service_location_boundary.dart`
- `lib/features/service_location/screens/service_location_screen.dart`

## Findings

1. The management helper chooses one record by status priority: Pending, then Rejected, then Verified, then the first available record.
2. If a location has multiple Pending or multiple Rejected boundary records, the helper returns the first matching record in the supplied iterable. There is no explicit ordering or record selector to let an administrator choose among those records.
3. When a Pending replacement is selected, the previous Verified boundary is retained and a notice explains that it remains safe. However, the UI does not provide a complete list of all boundary records or a direct switcher between the pending/rejected records and the older verified record.
4. This is an Admin usability/reachability gap, not evidence that Firebase has lost or overwritten the old boundary. The backend lifecycle audit says the old record is retained and the verified-boundary pointer changes only when a replacement is successfully verified for an inactive location.
5. The screen fetches the boundary records for the location once when opening the manager. A future record selector should be based on refreshed records and should show each record's status, timestamps, and verification notes where available.

## Safe next change

Add an explicit boundary-record chooser for the selected City/Area, preserving these rules:
- Never silently overwrite or delete a verified record.
- Verified records stay read-only.
- Pending records remain available for review; rejected records remain available for edit/resubmission.
- Replacements must still be verified through the trusted Firebase callable.
- Do not automatically deactivate an active location.
- Do not change Firestore schema, Rules, callable contracts, service activation, imports, or legacy Zones as part of this UI-only improvement.

## Not done

- No production Firestore data was changed.
- No service location was activated/deactivated.
- No PR was merged and no deployment was performed.
- No District schema migration was performed.

# Step 161 — Replacement Boundary Review Reachability

Date: 2026-10-18

## Issue found

After Step 160 added the replacement action, reopening a location still preferred its existing verified boundary over any pending replacement. That meant the newly saved replacement could be hidden behind the read-only verified record and not be straightforward to review.

## Change made

File: `lib/features/service_location/screens/service_location_screen.dart`

Commit: `be2b39df4bb7ca66955b52a518fed0e026bae6a3`

- Boundary manager now prefers Pending records, then Rejected records, then Verified records.
- A pending/rejected replacement can therefore be opened for editing/review while the old verified record remains stored.
- When a verified record also exists, the editor displays a notice that the old verified boundary remains safe and the replacement is a separate record.
- The notice explains that Firebase requires the owning location to be inactive before replacement verification; the UI will not deactivate it automatically.
- The replacement still uses the existing trusted review flow. No direct client verification writes were added.

## CI

Admin Web Build Check:
- Run: https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39073044653
- Commit: `be2b39df4bb7ca66955b52a518fed0e026bae6a3`
- Status when this report was created: `in_progress`

Do not mark the commit validated until this run finishes successfully. Dedicated replacement lifecycle tests are still a follow-up.

## Safety / scope

No Firestore Rules or Firebase functions changed. No production data, activation, import, deployment, District schema change, or PR merge was performed. Admin PR #7 remains Draft/open.

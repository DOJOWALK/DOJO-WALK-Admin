# Step 160 — Replacement Boundary Entry Point

Date: 2026-10-18

## Change made

File: `lib/features/service_location/screens/service_location_screen.dart`

Commit: `4c2d4525a3ac8604fd02d087cb0c924c5211329a`

Added a `Create replacement boundary` action when the currently opened boundary is verified. The action closes the read-only verified-boundary dialog and opens a fresh boundary editor with:
- the same owning location ID and type;
- no existing boundary document ID, so the save path creates a new record;
- an empty point list, ready for a new polygon.

The existing verified record is not edited or deleted. The replacement uses the existing `saveDraft` path and is saved as `pending`. Review still goes through the trusted Firebase callable. Verification and service activation remain separate.

## Important limitation

Firebase rejects verification of a replacement while its owning location is active. Admin currently surfaces that backend error; this UI change does not deactivate a service automatically. An authorized administrator must handle service status deliberately before replacement verification.

## Validation status

The Admin Web Build Check for this commit is running:
- Run: https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39072834582
- Commit: `4c2d4525a3ac8604fd02d087cb0c924c5211329a`
- Status at report creation: `in_progress`

Do not consider this change validated until CI completes successfully. A dedicated widget/regression test for the replacement action is still desirable; no such test is claimed in this step.

## Scope and safety

No Firebase code/Rules, production data, imports, service activation, deployment, District schema, or PR merge was changed. Admin PR #7 remains Draft/open.

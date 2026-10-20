# Step 183 — Optional Source Metadata Visible in CSV Preview

Date: 2026-10-18
Branch: `step-119-boundary-geometry`

## Change
Updated the read-only CSV preview dialog in `service_location_screen.dart`:
- Shows a clearly labeled “Optional source metadata · preview only” section when non-required columns are present.
- Lists the extra source column headers as chips.
- Includes non-empty optional source values in each preview row's subtitle.
- Explicitly warns that source codes and versions are displayed as provided and are not verified against an authoritative source.
- Retains existing row validation counts, errors, parent-mapping check and import-disabled warning.

The existing four normalized location-name fields remain unchanged. Source metadata is not used to match or write Firebase records.

## Verification
Code commit: `f87ef3648821ea314c80c14dd3111bffe064ede9`.
CI checks must finish on this exact commit before the UI change is considered validated.

## Safety
No schema, Firebase write, deployment, import, activation/deactivation, or Partner/Customer migration. Admin PR #7 remains Draft and unmerged.

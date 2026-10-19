# Step 241 — Align Admin District Status With Trusted Firebase Callable

Date: 2026-10-19

## Issue found
The trusted Firebase `setServiceLocationStatus` callable stores District service status in `isServiceActive`, while the Admin District model and active-child checks were reading/writing `isActive`. This could make an active District appear inactive in Admin and could let the Admin client miss it when guarding State deactivation.

## Changes
- District model serializes the canonical `isServiceActive` field.
- District model reads `isServiceActive`, with a legacy `isActive` fallback for older documents.
- District active-only stream filters on `isServiceActive`.
- State deactivation precheck checks canonical active Districts and also checks the legacy field for backward compatibility.
- Added model regression tests for canonical and legacy District status fields.

## Validation
Admin CI must be checked after the final commit before this step is marked passed.

## Safety
- Admin source/test/docs only; no production Firestore writes or deployment.
- Admin PR #7 remains Draft/open/unmerged.
- Partner and Customer work remains deferred until Admin and Firebase schema contracts are aligned.

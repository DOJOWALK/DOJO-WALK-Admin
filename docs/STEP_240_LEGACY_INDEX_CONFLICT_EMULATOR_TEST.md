# Step 240 — Legacy Index Ownership Conflict Integration Test

Date: 2026-10-19

## Change
Added a Firebase Firestore Emulator callable integration regression test on companion branch `fix/location-index-import-rules`:

- Seeds a legacy Area name index owned by a different Area document.
- Attempts to create a District-linked Area that would collide with that index.
- Expects the trusted callable to reject the operation with `failed-precondition`.
- Verifies the conflicting legacy index remains owned by the original document, the District-aware index is not created, and no Area record is written.

Firebase test commit: `b1ff8b6e94dd4625549b77814a98b6e975644650`.

## CI
Pending at report creation. Verify the latest Trusted Location Geometry and Callable Tests and Firestore Security Rules workflows before marking this step passed.

## Scope and safety
- Companion Firebase test-only change; no Admin production write path enabled by this step.
- No production Firestore scan, import, activation, deployment, merge, or Partner/Customer migration performed.
- Admin PR #7 remains Draft/open/unmerged.

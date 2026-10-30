# Dashboard Audit Log Schema Compatibility — 2026-10-30

## Scope

Source audit and minimal Admin-side query correction for the Dashboard's planned Firestore Emulator integration. No production configuration, Rules, indexes, or data were changed.

## Pinned source evidence

- Admin repository: `DOJOWALK/DOJO-WALK-Admin`
- Admin branch: `ui/notion-brand-foundation-2026-10-28`
- Corrected Dashboard data source blob: `80caaf6f73db0d73c1b5104eff5d29a91d11140c`
- Firebase repository: `DOJOWALK/DOJO-WALK-Firebase`
- Firebase `firestore.rules` blob: `104467bab5dcc66c01a1f0f70df321ac0b193249`
- Firebase `firestore.indexes.json` blob: `add7c655c19cb240e35624e23c3e9a1041ef15bf`
- Firebase `firebase.json` blob: `ec27a2d7b8880c12cc76ebf7c1ea5ac5e05f6ea9`
- Firebase Rules test file: `test/firestore.rules.test.mjs`, blob `e7bfeb73b09438dd6252f8232d41ea78de57cf0f`

These are blob identifiers observed during this audit, not substitutes for pinning repository commit SHAs in a CI checkout.

## Confirmed mismatch and correction

The previous Admin `FirestoreDashboardDataSource.recentActivity()` queried `audit_logs` ordered by `timestamp`.

The authoritative Firebase Rules require audit records to include `createdAt`, allow `createdAt` in the field whitelist, and require `createdAt == request.time`. The Rules do not whitelist a `timestamp` field. The existing Walker Admin writer also writes `createdAt: FieldValue.serverTimestamp()`, and the Walker audit-history reader orders by `createdAt`.

The Admin Dashboard data source has now been corrected to:

```dart
.collection('audit_logs')
.orderBy('createdAt', descending: true)
.limit(6)
```

The existing `action` and `actorRole` mapping and the `Admin` fallback are unchanged. The canonical Rules were not weakened or edited.

## Remaining test work

1. Add a focused Dashboard data-source test proving records with `createdAt` are ordered/read correctly and legacy `timestamp` is not required.
2. Seed Emulator audit fixtures with `createdAt`, `action`, `actorUid`, `targetType`, and `targetId`; use only allowed `action` values for client-created test audit entries.
3. Test Rules authorization independently from Dashboard query mapping. Do not interpret a successful Admin read as permission to create arbitrary audit events.

The focused test file has not been added; the attempted GitHub file-create operation was blocked and no test result is claimed.

## Emulator configuration

The Firebase repository's `firebase.json` declares Auth (9099), Functions (5001), and Firestore (8080) Emulator ports, and points to the canonical `firestore.rules` and `firestore.indexes.json` files. Its package script runs Node's test runner against `test/*.test.mjs`.

The Admin repository should not duplicate or independently edit canonical Rules/indexes. A CI workflow can check out a pinned Firebase commit and start the Emulator using the Firebase repository's configuration/artifacts, while the Admin Flutter integration test targets only a dedicated demo project ID.

## Index finding

The inspected indexes file contains one composite index for `audit_logs` on `targetType`, `targetId`, and `createdAt`. The Dashboard's unfiltered single-field `orderBy('createdAt')` query does not require that composite index; Firestore's automatic single-field index is sufficient unless index exemptions or additional filters are introduced.

## Status and non-claims

- Source compatibility audit: complete.
- Timestamp mismatch: confirmed and corrected in the Admin Dashboard query.
- Corrected source fetched back from GitHub and verified to use `createdAt`; no legacy `orderBy('timestamp')` remains in this data source.
- Focused data-source test: pending.
- Emulator integration: not implemented.
- Flutter tests / Rules tests / Emulator tests / CI: not run for this change; no PASS is claimed.
- No merge, deployment, production write, Rules edit, or indexes edit.

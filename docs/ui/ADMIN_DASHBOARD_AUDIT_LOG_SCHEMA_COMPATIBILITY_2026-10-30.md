# Dashboard Audit Log Schema Compatibility — 2026-10-30

## Scope

Read-only source audit for the Admin Dashboard's planned Firestore Emulator integration. No production configuration, Rules, indexes, or data were changed.

## Pinned source evidence

- Admin repository: `DOJOWALK/DOJO-WALK-Admin`
- Admin branch: `ui/notion-brand-foundation-2026-10-28`
- Admin Dashboard data source blob: `f8463020ffada650a4a081dbec2d621280bd4aa7`
- Firebase repository: `DOJOWALK/DOJO-WALK-Firebase`
- Firebase `firestore.rules` blob: `104467bab5dcc66c01a1f0f70df321ac0b193249`
- Firebase `firestore.indexes.json` blob: `add7c655c19cb240e35624e23c3e9a1041ef15bf`
- Firebase `firebase.json` blob: `ec27a2d7b8880c12cc76ebf7c1ea5ac5e05f6ea9`
- Firebase Rules test file: `test/firestore.rules.test.mjs`, blob `e7bfeb73b09438dd6252f8232d41ea78de57cf0f`

These are source/blob identifiers observed during this audit; pin exact commit SHAs before wiring a cross-repository CI checkout.

## Confirmed mismatch

The Admin `FirestoreDashboardDataSource.recentActivity()` currently queries:

```dart
.collection('audit_logs')
.orderBy('timestamp', descending: true)
.limit(6)
```

It maps `action` and `actorRole`.

The authoritative Firebase Rules require Audit Log creates to include `createdAt`, allow `createdAt` in the field whitelist, and require `createdAt == request.time`. The Rules do not whitelist a `timestamp` field. The existing Walker Admin writer also writes `createdAt: FieldValue.serverTimestamp()`, and the Walker audit-history reader orders by `createdAt`.

Therefore, the Dashboard's `timestamp` ordering is inconsistent with both the authoritative Rules schema and the existing Admin Walker audit writer/reader contract.

## Safe resolution

1. Align the Dashboard recent-activity query to `createdAt` (not by widening or weakening Firestore Rules).
2. Keep the UI model mapping for `action` and `actorRole`; missing `actorRole` continues to use its existing display fallback.
3. Add a focused Dashboard data-source test proving records with `createdAt` are ordered/read correctly and that the legacy `timestamp` field is not required.
4. Seed Emulator audit fixtures with `createdAt`, `action`, `actorUid`, `targetType`, and `targetId`; use only allowed `action` values for client-created test audit entries.
5. Test Rules authorization independently from Dashboard query mapping. Do not interpret a successful Admin read as permission to create arbitrary audit events.

## Emulator configuration

The Firebase repository's `firebase.json` already declares Auth (9099), Functions (5001), and Firestore (8080) Emulator ports, and points to the canonical `firestore.rules` and `firestore.indexes.json` files. Its package script runs Node's test runner against `test/*.test.mjs`.

The Admin repository should not duplicate or independently edit the canonical Rules/indexes. A CI workflow can check out a pinned Firebase commit and start the Firestore Emulator with the Firebase repository's configuration/artifacts, while the Admin Flutter integration test targets only the dedicated demo project ID.

## Index finding

The inspected indexes file contains one composite index for `audit_logs` on `targetType`, `targetId`, and `createdAt`. The Dashboard's unfiltered single-field `orderBy('createdAt')` query does not require that composite index; Firestore's automatic single-field index is sufficient unless index exemptions or additional filters are introduced.

## Status and non-claims

- Source compatibility audit: complete.
- Timestamp mismatch: confirmed.
- Recommended correction: Dashboard query should use `createdAt`.
- Emulator integration: not implemented in this audit.
- Flutter tests / Rules tests / Emulator tests / CI: not run by this audit; no PASS is claimed.
- No merge, deployment, production write, Rules edit, or indexes edit.

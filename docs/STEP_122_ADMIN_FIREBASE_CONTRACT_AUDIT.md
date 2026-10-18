# Step 122 — Admin ↔ Firebase Service Location Contract Audit

Date: 2026-10-19
Status: Static cross-repository audit; no schema or production changes.

## Repositories and reviewed revisions

- Admin PR #7: `step-119-boundary-geometry`; latest Step 121 documentation commit `362ac977fdd7c54e7e2581c453c08e423e1c2d67`.
- Firebase PR #6: `fix/location-index-import-rules`; head `83239c94efe4f64c53dcd8ae1881cfda7e1c1861`.
- Reviewed Admin `service_location_service.dart`, Firebase `functions/src/index.ts`, `functions/src/location_name_index.ts`, and Firebase PR #6 Rules/callable diff.

## Contract checks

1. **Client direct writes are intentionally denied in Firebase PR #6.** Country/State/City/Area/Locality writes and name-index mutations are denied through direct Firestore client SDK writes. Admin's save service calls `saveServiceLocationWithNameIndex`; this direction is aligned, provided the matching trusted Functions are deployed with the matching Rules revision.
2. **Trusted save callable supports only five types:** country, state, city, area and locality. Its payload allowlists and canonical index parent counts match the existing hierarchy. There is no `district` type, `service_districts` collection, or `districtId` field in the reviewed callable schema.
3. **District → City hierarchy is therefore not implemented.** Admin-only addition of `districtId` or `lgdCode` would be rejected by the current callable allowlist. Import must stay preview-only; do not map District silently into City.
4. **Boundary verification/activation is a separate trusted workflow.** The reviewed Firebase Functions check City/Area boundaries, and Area verification checks containment within its active City boundary. Imported records must not become active merely because a CSV row passes parsing.
5. **Rules and callable rollout must be coordinated.** The Firebase PR makes direct client writes fail by design. If Rules were deployed without the matching callable Functions and compatible Admin client, Service Location create/update would fail. Repository PR state does not prove the deployed production version.

## Required next implementation gate

- Approve the logical hierarchy and migration plan for existing City/District records.
- Add District type, collection, parent validation, name-index parent-count rules and migration compatibility only as one coordinated Admin + Firebase change.
- Add emulator tests for District ownership by State, City ownership by District, duplicate names under the correct parent, wrong-parent rejection, legacy City records, and import retries/idempotency.
- Verify Admin authorization UI matches the callable role contract.
- Run Admin CI and Firebase Rules/Functions emulator CI on the coordinated branches before review.
- Keep CSV import preview-only until these checks pass and official source mapping is reconciled.

## Safety

No Firebase deployment, Firestore writes, location activation, PR merge, or production import was performed. Both PRs remain draft/open at the time of this audit.

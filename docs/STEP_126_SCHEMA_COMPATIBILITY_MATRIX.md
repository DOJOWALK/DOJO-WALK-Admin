# Step 126 — Service Location Schema Compatibility Matrix

Date: 2026-10-18  
Status: **Audit/design only — not approved for implementation or production**

## 1. Current state versus proposed state

| Concept | Current Admin/Firebase shape | Proposed logical meaning | Compatibility decision |
|---|---|---|---|
| Country | `service_countries` | Country reference | Keep existing IDs and fields |
| State | `service_states` with `countryId`, `name` | Official State/UT reference; optional LGD code | Add LGD code only after Rules/Functions allowlists and tests are coordinated |
| District | No separate collection; folded into City/District label today | Official LGD district reference under State | Proposed `service_districts`; preserve LGD source code exactly, including leading zeros |
| Service City | `service_cities` with `countryId`, `stateId`, `name` | Operational city/municipal service unit under a District | Add optional `districtId`; keep `stateId`/ `countryId` for legacy readers; old records without `districtId` remain legacy/unclassified |
| Service Area | `service_areas` with `countryId`, `stateId`, `cityId`, `name` | Operational coverage area under a Service City | Keep separate from LGD Sub-District; polygon verification remains mandatory before activation |
| Locality | `service_localities` | Optional address/reference detail | Must not be mandatory for customer booking if customer supplies address |
| Boundary | `service_location_boundaries`, owner/type/status/source/review metadata | Trusted, reviewed polygon tied to one City or Area | Keep trusted callable workflow; do not infer verification from name/code |
| Import history | `service_location_imports` | Source, validation and audit trail | Preview records must not be mistaken for committed imports |
| Legacy Partner zone | `zones` and walker zone IDs in existing Partner code | Old operational mapping | Do not delete or rewrite; mapping must use stable reviewed IDs, not name-only matching |

## 2. Import column mapping — allowed and disallowed

Input columns: `State, District, City, Area`.

- `State`: resolve against a reviewed official State/UT reference and stable source code.
- `District`: resolve against a separate official District reference under the resolved State.
- `City`: resolve/create an explicitly approved operational Service City under the resolved District. Do not assume it is the District.
- `Area`: resolve/create an operational Service Area under the Service City. Do not assume it is the LGD Sub-District.
- Boundary geometry and service activation are separate gated operations; a clean CSV row is not evidence that a boundary is authoritative or verified.

**Prohibited shortcuts:** mapping District to City solely because the current collection combines the terms; mapping Area to Sub-District by matching names; creating duplicate entities when a parent is ambiguous; assigning LGD codes to operational records without verified source semantics.

## 3. Stable identifiers and source provenance

1. Preserve current Firestore document IDs for existing records.
2. Store official LGD codes as strings or another representation that preserves source values exactly; never coerce codes through a number that can strip leading zeros.
3. For new reference records, document the deterministic ID strategy before implementation. It must be stable across imports and scoped to the source jurisdiction/version.
4. Store source dataset name, official URL/reference, source snapshot/update date, source file hash, import run ID and row number for traceability.
5. Do not use normalized names as the sole cross-system identity key. Names can change, repeat across districts, or have transliteration differences.
6. Parent relationships must be validated by IDs and jurisdiction chain, not names alone.

## 4. Legacy compatibility rules

- Legacy `service_cities` without `districtId` remain readable. Do not invent a District parent during read.
- Existing `service_areas` retain their current `cityId` and verified boundary reference.
- Existing `zones`, customer addresses, bookings and walker zone IDs remain untouched until a separately reviewed migration/adapter exists.
- Any new callable must accept the documented legacy case only where explicitly intended; it must reject malformed or contradictory parent IDs.
- If a legacy record cannot be unambiguously mapped, report it for manual review; do not auto-repair or activate it.

## 5. Required coordinated implementation and tests

### Admin
- Models: State LGD metadata, District model, City optional `districtId`, import row/mapping report.
- Services: read/write District collection; stable ID and source metadata handling.
- UI: State → District → City → Area dependent selectors and parent validation.
- Import: dry-run report first; no Firestore writes until approved.

### Firebase
- Rules: strict field allowlists and parent checks updated together with model changes.
- Trusted Functions: validate District/City/Area ancestry; retain boundary review/activation guards.
- Emulator tests: allowed/denied writes, active admin roles, invalid/missing parents, legacy City without `districtId`, City/District mismatch, Area wrong City, boundary ownership, verification and deactivation guards.

### Partner and Customer
- Inventory all readers/writers of `zones`, `zoneIds`, `stateId`, `cityId`, `areaId` and location labels.
- Preserve legacy read behavior while an adapter is introduced and tested.
- Test existing booking and active-walk behavior with old and new location records before any migration.
- Do not change production IDs or deployed Rules as part of a documentation-only schema decision.

### Import reliability
- Validate exact headers, UTF-8/BOM, duplicate combinations, missing cells and row widths.
- Add dry-run/idempotency tests and duplicate-parent ambiguity tests.
- If committing records spans multiple Firestore documents, use a bounded batch/transaction strategy with a recoverable import-run state; do not claim global transactionality beyond Firestore's limits.
- Record per-row outcomes, errors and actor; support safe retry without duplicate records.
- Keep import and activation as distinct authorized actions.

## 6. Decisions still required

- [ ] Approve logical hierarchy and definitions for District, Service City and Service Area.
- [ ] Approve collection names and source-code ID strategy.
- [ ] Approve how old City/District records without `districtId` are displayed and whether they require manual classification.
- [ ] Approve the cross-app legacy-zone adapter/migration plan.
- [ ] Confirm authoritative current LGD snapshot and source provenance.
- [ ] Approve who may run an import and who may verify/activate boundaries.

## 7. Explicit safety state

This document does not approve implementation, production import, data migration, boundary activation, Rules/Functions deployment, Hosting deployment or PR merge. CSV remains preview-only until the above decisions and coordinated tests are complete.

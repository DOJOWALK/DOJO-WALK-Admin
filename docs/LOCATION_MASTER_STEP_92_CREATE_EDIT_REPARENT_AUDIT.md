# DOJO WALK Location Master — Step 92
## Create/Edit/Reparent Hierarchy Audit
Date: 2026-10-17

### Audit finding
Location documents were protected against direct status flips, but metadata edit paths could still submit model-supplied activation values, and inactive location records could have their parent IDs changed. Client-only child queries were not sufficient to guarantee safe reparenting under concurrency.

### Changes implemented
- Firestore Rules now make parent references immutable after creation:
  - State: `countryId`
  - City: `countryId`, `stateId`
  - Area: `countryId`, `stateId`, `cityId`
  - Locality: `countryId`, `stateId`, `cityId`, `areaId`
- Added Rules Emulator regression tests that attempt to reparent each of State, City, Area and Locality and expect rejection.
- Admin save methods for Country, State, City, Area and Locality now preserve the status stored in Firestore; new records start inactive. Status transitions remain on the trusted backend callable paths.
- Admin service now rejects parent-ID changes early with a clear error directing the operator to create a new location rather than silently creating inconsistent descendants.
- Removed the obsolete client-only child-query reparent guard.
- City/Area/Locality save-time active checks now use persisted activation state, rather than trusting the incoming model's status field.

### Validation
- [!] Initial Rules run [39026587203](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39026587203) exposed a misplaced Locality rule condition in the new regression test. The rule placement was corrected in Firebase commit `7fcede8b73ddfa7b0c1eee298df589f2ec53ef20`.
- [x] Corrected Firebase Rules CI [39026678657](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39026678657) — **PASS** on commit `7fcede8b73ddfa7b0c1eee298df589f2ec53ef20`.
- [x] Firebase callable/geometry CI [39026678719](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39026678719) — **PASS** on the same commit.
- [ ] Admin Flutter CI [39026612586](https://github.com/dojoplatform2026/DOJO-WALK-Admin/actions/runs/39026612586) is still running; Step 92 final validation remains pending.
- [!] CI results must be rechecked before Step 92 is marked PASS.
- [!] This is source/rules/test hardening, not proof that every existing database record is consistent. A one-time live data integrity scan is still needed before launch.
- [!] No production deployment, production Firestore write, import, or live service activation was performed.

### Remaining release gates
- Fresh official LGD sub-district export with retrieval provenance and checksum; record-by-record reconciliation.
- Authoritative, verified, contiguous City/Area polygon data and containment validation.
- Live-data integrity audit for legacy records with missing/mismatched parent IDs.
- Review/merge/deployment approval.

### Next
Step 93 — validate parent-document existence and ancestry on create/edit paths, and add a safe read-only integrity scan for existing location records.

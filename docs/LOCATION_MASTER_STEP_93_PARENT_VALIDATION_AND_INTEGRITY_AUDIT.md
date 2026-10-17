# Step 93 — Parent Creation Validation & Read-Only Integrity Audit

Date: 2026-10-17

## Scope

Harden creation-time parent linkage in Firebase Firestore Rules and add an offline integrity-audit utility. This step is additive to the Step 92 immutable-parent protections.

## Implemented

- State creation now requires its referenced Country document to exist.
- City creation requires its Country and State to exist, and the State's `countryId` to match the City's `countryId`.
- Area creation requires Country, State, and City to exist and the City's Country/State links to match.
- Locality creation requires Country, State, City, and Area to exist, with the parent IDs consistent across the full chain.
- These checks intentionally permit draft records under inactive ancestors; service activation remains separately guarded by trusted backend callables.
- Added Rules Emulator regression cases for missing and mismatched parent links and a valid State creation control.
- Added `scripts/audit_service_location_integrity.mjs` and its pure audit core. It reads a caller-provided JSON snapshot, reports missing/mismatched ancestors and active records beneath inactive ancestors, and never connects to Firebase or changes source records.
- Added unit tests for the offline audit and included them in the repository's Node test command.

## Validation status

- Firebase Rules Emulator run [39027112643](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39027112643) — **PASS** on commit `8823cbc574e6be24ce9cfc2be9c41bb5e61b2484`.
- Trusted Location Geometry and Callable Tests run [39027112624](https://github.com/dojoplatform2026/DOJO-WALK-Firebase/actions/runs/39027112624) — **PASS** on the same commit.
- An earlier intermediate Rules run failed because the country-create test reused a document seeded as a parent fixture. The fixture was isolated under a separate ID, and both latest workflows passed.
- No live Firestore database was scanned. To audit real data, an authorized read-only export must be supplied as the documented JSON snapshot shape.
- No production data was modified, imported, activated, or deployed.
- Official current LGD row-level reconciliation and authoritative contiguous polygon verification remain release gates.

## How to run the offline audit

```sh
node scripts/audit_service_location_integrity.mjs path/to/location-snapshot.json path/to/integrity-report.json
```

The output path must not already exist. The utility is offline and read-only with respect to the input snapshot; it writes only the requested report file. Exit code is 1 when integrity issues are found, 0 when none are found, and 2 for missing usage arguments.

## Next

Step 93 code and Firebase CI validation are complete. Existing-data integrity scanning remains a separate pending gate and requires an authorized read-only export. Do not run a production scan without an authorized export and explicit approval.

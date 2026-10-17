# DOJO WALK Location Master — Step 88
## Activation / Deactivation Race Audit
Date: 2026-10-17

### Finding
The Admin Flutter service checks for active children before deactivating a Country, State, City, or Area. However, this check is a query followed by a separate update. It is not one atomic transaction.

The Firestore Rules currently allow Admin status updates that set Country/State inactive and allow City/Area service deactivation without enforcing an active-descendant check. Therefore, client-only guards can be bypassed and can race with a concurrent activation callable. The new activation callable checks active ancestors transactionally, but that does not make an unrelated non-transactional parent deactivation safe.

### Required remediation
1. Add a trusted backend deactivation/status callable, or another server-enforced atomic protocol, to check active descendants before changing service status.
2. Restrict direct client updates of service-status fields in Firestore Rules after the callable is available; keep non-status edits governed separately.
3. Add Firestore Emulator tests proving that Country/State/City/Area cannot be deactivated while active descendants exist.
4. Add race/regression coverage for activation and deactivation touching the same ancestor hierarchy.
5. Run Firebase Rules and callable CI and Admin Flutter tests.

### Status
Audit finding recorded. No deactivation implementation change made in this step. No production activation or deployment performed.

Next: Step 89 — implement server-enforced deactivation and regression tests.

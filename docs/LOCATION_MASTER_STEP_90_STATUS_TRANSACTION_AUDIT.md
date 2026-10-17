# DOJO WALK Location Master — Step 90
## Status Callable Transaction and Rules-Boundary Audit
Date: 2026-10-17

### Audit scope
Reviewed Firebase `setServiceLocationStatus`, the City/Area activation transaction, Firestore Rules for Country/State/City/Area/Locality, status callable emulator tests, and Admin's status-callable integration.

### Confirmed protections
- Status callable requires a signed-in active `super_admin`, rechecks actor and target inside the transaction, rejects deactivation when active direct children are found, and records an audit event.
- City/Area activation is a separate callable that validates the verified boundary and active hierarchy; its transaction touches ancestor guard documents to serialize competing changes.
- Country, State, City, and Area direct client status flips are blocked by Rules.
- Existing emulator regression test exercises competing Country deactivation and State activation and asserts the hierarchy invariant.

### Gap found — Locality status bypass
- Firestore Rules for `service_localities` currently allow an active admin to set `isServiceActive` directly on create/update; unlike Country/State/City/Area, the rule does not enforce inactive-on-create or unchanged status on update.
- `setServiceLocationStatus` currently accepts only Country/State/City/Area, so Locality status changes are not routed through the trusted callable.
- Area deactivation checks for active Localities, but that check cannot fully protect the invariant against a concurrent/direct Locality activation while the parent Area is being deactivated because Locality writes do not participate in the ancestor-guard transaction protocol.
- This is a source/rules audit finding; no production exploit or live Firestore incident was tested.

### Result
Step 90 audit is complete, but the status-transition safety review is **NOT fully closed** because of the Locality path. Do not mark the whole hierarchy release-ready yet.

### Next — Step 91
- Extend the trusted status transition contract to Locality, or otherwise ensure Locality service-status changes cannot bypass the parent Area guard.
- Restrict direct client Locality status flips in Firestore Rules and enforce inactive-on-create if status must be enabled only through the callable.
- Add Emulator tests for direct Locality status-change rejection, Locality activation requiring active ancestors, and concurrent Area deactivation vs Locality activation.
- Run Firebase Rules and callable CI, then Admin Flutter validation if its service contract changes.

### Remaining release gates
Current official LGD row-level reconciliation, authoritative contiguous polygon verification, PR review/merge and deployment approval remain pending. No merge, deployment, production import, or real location activation was performed.

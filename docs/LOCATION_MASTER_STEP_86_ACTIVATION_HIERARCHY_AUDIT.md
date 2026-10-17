# DOJO WALK Location Master — Step 86
## City/Area Activation Contract Audit
Date: 2026-10-17

### Summary
Admin activation routes through the Firebase callable `activateServiceLocation` in `asia-south1`. The callable already requires an authenticated active `super_admin`, a matching verified boundary with provenance fields and valid polygon geometry, and—when activating an Area—an active parent City whose verified polygon fully contains the Area. Activation plus an audit document are written transactionally after key state is re-read.

### Confirmed integration gap
The callable does not validate that a City has an existing, correctly linked, active Country and State before activating it. For an Area, it checks that the parent City is active and validates boundary containment, but does not independently validate the Area's Country/State IDs and active ancestors. Because the Admin activation action calls the callable directly, validation performed in other save paths cannot enforce this server-side requirement.

The existing callable integration test fixtures also create a City without Country/State ancestry, so they currently permit and test the weaker contract.

### Required fix (next step)
1. For City activation, require a valid Country and State reference; verify the State belongs to that Country and both are active.
2. For Area activation, require its Country/State references to match its parent City; verify Country, State, and City are active and correctly linked.
3. Include all ancestor documents in the same activation transaction and re-check existence, active flags, parent IDs, and boundary IDs before writing activation.
4. Add emulator integration tests for missing/inactive/mismatched ancestors, plus positive tests with a complete active hierarchy.
5. Run Firebase callable/geometry and Admin Flutter validation CI.

### Release status
This is a source-code audit finding, not a claim of a reproduced production incident. Do not activate or import production service locations until this gap, official current LGD reconciliation, and authoritative polygon validation are addressed. No production deployment is claimed.

Next: Step 87 — implement backend ancestor validation and regression tests.

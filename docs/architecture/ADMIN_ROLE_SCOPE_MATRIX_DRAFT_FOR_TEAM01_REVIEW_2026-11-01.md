# Admin Role × Action × Geographic Scope Matrix — Draft for Team 01 / POL-021 Review
Date: 2026-11-01
Team: 02 — Admin App
Status: **DRAFT / NOT APPROVED / NOT AN AUTHORIZATION CONTRACT**
Related: POL-021 (Admin Roles, Draft), POL-040 (Admin Service Location UI), POL-041 (Zone API workflow), Team 01 D01 and D03.
Branch: `ui/notion-brand-foundation-2026-10-28`; PR #51 Draft.

## 1. Why this document exists
Team 02 needs a stable role and geographic-scope model before presenting privileged Admin actions or connecting APIs. The existing Admin role screen is a static preview; AuthGate/AuthService currently verify active membership only. The inspected Zone callable source requires exact `central_admin` for certain operations and `founder` for Founder decisions. The relationship between these backend identifiers and product-facing roles is not confirmed.

This document is a review proposal to help Team 01 and policy owners answer D01/D03. It does not grant permissions, establish backend behavior, approve POL-021, or authorize implementation.

## 2. Proposed principles (require policy-owner confirmation)
1. **Founder/CEO:** company-wide oversight and approval of major business/risk decisions; not routine booking dispatch or ordinary support handling.
2. **Super Admin:** technical platform governance, account/security administration and platform configuration. This role does not automatically inherit Founder business approval or Central operational duties.
3. **Central Admin / Central Operations:** cross-city operational coordination, city-manager oversight, escalations and consolidated operations. This is a business-operational role, not automatically synonymous with Super Admin.
4. **City Manager:** one explicitly assigned City and only approved Zones within it; cannot act in another City without a separately granted scope.
5. **Zone Supervisor:** one or more explicitly assigned Zones only; no cross-zone access by default.
6. **Support:** case records and permitted communications within assigned support scope; no unrestricted customer/KYC export or privileged role grants.
7. **Finance:** payment/refund/payout/reconciliation actions explicitly granted within finance scope; no self-approval where segregation of duties is required.
8. **Walker/Partner:** belongs to Partner operations, not the Admin role hierarchy; sees own profile and assigned work only.

## 3. Proposed scope model
| Scope | Meaning | Proposed source of truth | Guardrail |
|---|---|---|---|
| Company | All cities/zones and company-wide governance | Approved privileged role assignment | Founder oversight; Super Admin technical scope; Central operational scope remain distinct |
| City | One named City and approved descendant Zones | Explicit city assignment record | No access to sibling cities |
| Zone | One named active/assigned Zone | Explicit zone assignment record | No access to sibling zones |
| Case | Explicit case assignment or permitted support queue | Case owner/queue membership | Case access does not imply unrestricted customer or payment access |
| Finance | Explicit finance permission and possibly city/zone scope | Finance role grant + scope | No self-approval; actions separated as policy requires |
| Self / assigned work | Own Walker account and assigned booking/walk | Authenticated partner identity + assignment | No access to other Walkers or unassigned customer data |

**Open source-of-truth question:** Team 01 must specify exact Firestore documents/claims and the server-side resolution algorithm for role and scope. Do not infer scope from a client-provided cityId/zoneId.

## 4. Proposed action matrix (discussion draft)
Legend: **P** = proposed responsibility for policy discussion; **—** = not proposed by default; **C** = must be explicitly confirmed by Team 01 and policy owner before any action is enabled. Every data read/write remains subject to record-level scope and trusted server enforcement.

| Action | Founder / CEO | Super Admin | Central Admin | City Manager | Zone Supervisor | Support | Finance |
|---|---|---|---|---|---|---|---|
| Company policy / major risk approval | P | — | C | — | — | — | — |
| Admin account / technical security administration | C | P | — | — | — | — | — |
| Cross-city operational oversight | P (oversight) | — | P | — | — | C | C |
| City operational management | — | — | P (oversight) | P (assigned City) | — | C | C |
| Assigned Zone daily operations | — | — | P (oversight) | P (assigned City) | P (assigned Zone) | C | C |
| Customer/Walker record read | C | C (technical support need) | P (operational need) | P (assigned City) | P (assigned Zone, minimum fields) | P (assigned case, minimum fields) | C (finance need only) |
| Booking assignment / operational escalation | — | — | P | P (assigned City) | P (assigned Zone, per approved workflow) | C | — |
| Zone draft creation | — | — | P | C | C | — | — |
| Boundary evidence upload / submission | — | — | P | C | C | — | — |
| Boundary technical review | — | C (technical validation only, if policy allows) | P / C | — | — | — | — |
| Submit Zone for Founder review | — | — | P | C | C | — | — |
| Founder approval / rejection | P | — | — | — | — | — | — |
| Zone activation / deactivation execution | — | — | P (only after required approval) | C | — | — | — |
| Emergency Zone suspension | C (oversight) | C (technical emergency authority?) | P / C | C (assigned City?) | C (assigned Zone?) | C (report/escalate) | — |
| Request Zone reactivation | — | — | P | C | C | — | — |
| Execute reactivation after Founder approval | — | — | P (if Team 01 confirms same activation callable) | — | — | — | — |
| Support case triage / communication | — | — | P (escalation) | P (assigned City) | P (assigned Zone) | P | C |
| Refund initiation / review | — | — | C | — | — | C (case only) | P |
| Refund approval up to approved threshold | C (only above delegated threshold) | — | P (subject to approved threshold) | — | — | — | C (segregation policy) |
| Refund approval above threshold / suspicious case | P | — | Escalate | — | — | Escalate | P (review/evidence) |
| Walker payout / reconciliation | — | — | C (oversight) | — | — | — | P |
| Grant/revoke privileged Admin roles | C (policy oversight) | P (technical execution, if policy approves) | — | — | — | — | — |
| Audit log read/export | P (oversight) | P (security audit) | P (operational scope) | P (assigned City) | P (assigned Zone) | C (case scope) | C (finance scope) |

This table deliberately includes **C** where business policy or backend behavior is not yet confirmed. It must not be translated into code as an authorization table until reviewed and approved.

## 5. Team 01 required answers (D01 / D03)
### D01 — Canonical role identifiers and operation map
Team 01 must provide:
- Exact accepted `admin_users/{uid}.role` values and any permission/claim mapping.
- Whether `super_admin`, `central_admin`, and `founder` are separate identifiers or mapped aliases; no implicit equivalence.
- Exact accepted role(s) per callable: draft save, boundary upload/create, boundary review, submit Founder review, Founder decision, activation/deactivation, emergency suspension, reactivation request and execution.
- Whether role membership can carry multiple permissions and how conflicts/revocation are handled.
- Positive and negative Emulator test evidence for each callable.

### D03 — Authoritative geographic scope
Team 01 must provide:
- Authoritative assignment record(s) for City Manager and Zone Supervisor.
- Whether a City assignment automatically includes all Zones in that City, or only explicitly assigned Zones.
- Whether Central Admin has company-wide operational scope and how it differs from Super Admin.
- Server-side checks for read, query, create, update, review, activation, suspension and export.
- Stable error response for out-of-scope requests.
- Emulator evidence for same-scope allow, sibling-zone deny, sibling-city deny, missing assignment deny, revoked assignment deny, and attempted client-supplied scope escalation.

## 6. Team 02 implementation implications (blocked until approval)
After Team 01 and policy owners approve the model:
1. Keep authentication entry gate responsible for active membership; do not arbitrarily restrict all Admin entry to one role.
2. Add a shared capability model for UI presentation, using canonical role/permission values returned by the approved source.
3. Route and screen actions must check capability and record scope for usability; these are not security controls.
4. Trusted backend must independently validate role, active status, scope, current resource state and audit requirements.
5. Add widget tests for visible/hidden/disabled actions and route/deep-link denial states.
6. Add Emulator tests for actual authorization; widget tests cannot prove backend security.
7. Normalize server errors into safe UI states without leaking private customer/KYC or internal security details.

## 7. Explicit non-decisions
- No approval of POL-021 is implied.
- No mapping of `super_admin` to `central_admin` or `founder` is implied.
- No City Manager or Zone Supervisor callable permission is implied.
- No broad customer/KYC access or unrestricted export is implied.
- No permission to change Firebase, Firestore rules, Functions, production data or wire Admin APIs is granted.
- No code-level role gate should be implemented from this draft alone.

## 8. Status
- Draft matrix prepared by Team 02 for review.
- Team 01 D01 and D03 answers: **PENDING** in the PR #51 discussion at time of preparation.
- POL-021 approval: **NOT VERIFIED / DRAFT**.
- Server-side role/scope enforcement: **NOT ESTABLISHED** by Team 02 source audits.
- Emulator evidence: **NOT PROVIDED / NOT RUN by Team 02**.
- Admin API integration: **NOT STARTED — intentionally blocked**.

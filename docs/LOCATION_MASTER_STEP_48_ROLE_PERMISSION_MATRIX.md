# DOJO WALK — Step 48 Role & Permission Matrix (Proposal)

Date: 2026-10-17  
Status: **DRAFT — policy proposal, not yet enforced**  
Scope: Admin UI and Firestore permissions for Service Location setup.

## Design principles

1. Firestore Rules are the security boundary; hiding UI controls is not authorization.
2. Access should be limited by both role and assigned geography where applicable.
3. Draft creation/editing, boundary verification, and service activation are separate privileges.
4. Name indexes should be maintained only through trusted, validated workflows; ordinary clients should not write index documents directly.
5. Import jobs and audit records must not be editable/deletable by ordinary client roles.
6. Do not change deployed rules or production data until this matrix is reviewed and matching Emulator tests pass.

## Proposed permissions

Legend: **Yes** = proposed; **Scoped** = only assigned locations; **No** = denied; **Review** = requires product approval.

| Action | Super Admin | Location Admin | Operations Admin | Support Admin |
|---|---|---|---|---|
| Read location hierarchy | Yes, all | Scoped | Yes, active locations needed for operations | Read-only, support-needed fields |
| Create/edit draft locations | Yes | Scoped | No | No |
| Submit boundary for review | Yes | Scoped | No | No |
| Verify/reject a boundary | Yes | No (separation of duties) | No | No |
| Activate/deactivate City/Area | Yes | No by default; Review | No | No |
| View activation status | Yes | Scoped | Yes | Read-only |
| Start/execute reference-data import | Yes | No | No | No |
| Read import result/status | Yes | Scoped, if assigned | No by default | No |
| Edit/delete import audit history | No direct client writes; trusted workflow only | No | No | No |
| Directly create/update/delete name-index docs | No direct client writes; trusted workflow only | No | No | No |
| Change global settings or roles | Yes | No | No | No |

## Required scope fields and safeguards

- For scoped roles, use a trusted assignment field or server-validated mapping. Do not trust a client-supplied city/area ID by itself.
- Super Admin operations should still validate parent-child hierarchy, verified boundary references, and state transitions.
- A Location Admin can submit boundary metadata but cannot approve their own boundary in the proposed separation-of-duties model.
- Service activation should require a verified, matching boundary and active parent chain. Polygon containment/official provenance still need trusted enforcement and data review.
- Denials must be tested for unauthenticated users, inactive users, each role, and out-of-scope locations.

## Emulator test checklist before enforcement

- Unauthenticated and inactive users denied for all protected collections.
- Super Admin allowed only for explicitly approved actions.
- Location Admin can edit drafts only within assigned scope; cannot verify, activate, import, change roles, or write name indexes directly.
- Operations Admin cannot mutate reference locations or boundaries.
- Support Admin is read-only and cannot access import internals beyond any explicitly approved status view.
- City and Area activation requires matching verified boundary and valid active parents.
- Wrong-location/wrong-type boundary references are denied.
- Boundary verification/rejection state transitions follow approved rules.
- Import audit history is immutable to client roles.
- Tests run in the Firestore Emulator and the CI result is inspected before a PASS is recorded.

## Decision needed

This is a recommendation, not a user-approved final policy. In particular, decide whether Location Admins should ever activate locations, whether Operations Admins need scoped draft edits, and what import status Support Admins may see. Implement UI and Rules only after those decisions are settled.

## Safety

No code permissions or deployed rules were changed in this step. No production writes, imports, activations, or deployments were performed. Keep PR #6 open.

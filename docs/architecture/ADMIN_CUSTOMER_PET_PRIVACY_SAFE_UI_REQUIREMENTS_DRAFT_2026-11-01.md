# Admin Customer & Pet Privacy-Safe UI Requirements — Draft
Date: 2026-11-01
Team: 02 — Admin App
Backlog item: ADM-P1-04
Status: **DRAFT / POLICY-DEPENDENT / NOT APPROVED / NOT IMPLEMENTED / NOT TESTED**
Notion sources reviewed (all currently Draft / unapproved):
- POL-014 — Privacy & Data Access Policy (fetched 2026-10-25)
- POL-031 — Customer Account, Profile, Consent & Account Lifecycle Policy (fetched 2026-10-25)
- POL-006 — Customer Booking & Eligibility Policy (fetched 2026-10-30)
- POL-027 — Dog Safety, Welfare, Walk Handling & Emergency Response Policy (fetched 2026-10-25)
Tracking PR: #51 (Draft, unmerged)

## 1. Purpose and source status
The Admin Customers and Pets screens were previously audited as UI-only examples with hard-coded records. This draft defines minimum privacy-safe product requirements before any live customer/pet data source or actions are connected.

The Notion policies above explicitly state Draft / not approved / not implemented / not tested. This document therefore does not claim legal compliance, approved consent, verified age, operational dog-safety controls, or working deletion/access controls.

## 2. Core principles
1. Least privilege: Admin staff see only the fields needed for their authorized purpose and assigned scope.
2. Authentication is not authorization; enforce access in trusted backend and Firestore Rules, not only by hiding UI.
3. Customer can access own profile, dogs, bookings and permitted support/payment information; unrelated customers cannot.
4. Walker/Partner sees only relevant dog/service details needed for an accepted/assigned booking and only at the approved lifecycle stage.
5. Support access is case-assigned and minimum necessary; sensitive documents, full financial data and precise live location require additional authorization.
6. Finance access does not imply access to unrelated dog-care notes or live location.
7. Do not expose passwords, OTPs, PINs, payment authentication secrets, raw payment credentials, or identity documents in ordinary Admin screens.
8. Do not infer account verification, consent, age eligibility, health status, or dog temperament from UI fields or free-text notes.
9. Preserve historical booking/financial records when a profile changes; profile edits must not rewrite historical facts.
10. Do not implement a customer or pet delete button until retention, legal-hold, active-booking and deletion contracts are approved.

## 3. Proposed Customers list
List/table columns should be minimized:
- Customer display name (if authorized)
- Masked contact identifier or verified-contact indicator; full phone/email only when required for a permitted task
- Account state from authoritative backend (unverified/active/restricted/suspended/closure requested/closed only if those exact states are adopted)
- Account creation/last activity time only if operationally justified
- Active booking count or status summary only if source and semantics are defined
- City/Zone scope indicator only when relevant and authorized
- Last profile update / data freshness indicator

Avoid showing date of birth, full address, payment details, dog medical notes, identity evidence or full contact details in the default table.

Search must be limited to authorized customer records and approved identifiers. Avoid broad fuzzy search that reveals whether unrelated customer accounts exist. Search result counts must not leak out-of-scope records.

## 4. Customer detail view
Proposed sections:
- **Overview:** customer reference, display name, account state, verified contact indicators, created/updated timestamps.
- **Contact:** masked phone/email by default; reveal only for an approved support/operational purpose and authorized role, with access audit.
- **Eligibility:** backend verification result and checked-at timestamp; do not show or store a client-calculated age as proof.
- **Consent & notices:** notice/terms version, timestamp, purpose-specific consent/acknowledgement and revocation state only where backend has authoritative records.
- **Dogs:** linked dog references and safe summary; click-through must independently enforce authorization.
- **Bookings:** references and status timeline; sensitive pickup/location fields only for a booking-related operational need.
- **Support:** assigned/authorized case references only; case detail access follows case scope.
- **Privacy requests:** access/correction/closure/deletion request state, without exposing unnecessary evidence.
- **Audit:** permitted access/change events; no secret or unnecessary old sensitive values.

A customer detail screen is not a general-purpose staff dossier. Do not aggregate every customer-related dataset into one unrestricted view.

## 5. Proposed Pets list
Default list fields:
- Dog display name
- Customer reference/display name only if permitted
- Dog profile status / completeness indicator (not a safety certification)
- Relevant size/age band only if approved and necessary
- Safety-review flag only if backed by an explicit authorized workflow; never infer it from breed
- Last profile update timestamp

Do not display private health/behavior notes, exact home/pickup address, customer phone, incident evidence, or veterinary details in the list.

## 6. Pet detail view and field governance
Potential profile data described by POL-006/POL-027 includes dog name, optional image, approximate age/date of birth, size/weight band, breed/type where relevant, behavior/trigger/handling considerations, relevant health/mobility needs, emergency contact and veterinarian details where justified.

Before implementing each field, policy/product owners must specify:
- Exact field name/type and allowed values.
- Purpose and whether required or optional.
- Who supplies it and how accuracy is maintained.
- Who can read it (Customer, assigned Walker, Support, City/Zone operations, Central, Founder, Finance).
- At what booking/walk lifecycle stage it becomes visible.
- Whether it is sensitive or specially restricted.
- Validation, correction and audit behavior.
- Retention and deletion rule.
- Whether the field is shown to the assigned Walker, and whether a safety acknowledgement is required.

**No field in the potential list becomes mandatory merely because it appears in this document.** Do not use breed alone to infer risk, temperament or walker suitability. Do not diagnose, prescribe or administer treatment through Admin UI.

## 7. Walker-facing data minimization
For a specific accepted/assigned booking, the Partner app may receive only the minimum dog and handover details required for safe performance, according to approved policy and backend contract:
- Dog identity and authorized pickup/handover confirmation.
- Relevant handling instructions, triggers and disclosed safety considerations.
- Required equipment and safe handover notes.
- Emergency information only where justified by the service and approved design.

Full customer profile, unrelated dogs, unrelated bookings, payment history, date of birth, identity evidence and broad customer search are not required by default. Access must end or be reduced when assignment/service ends, except a documented and authorized dispute/incident need.

Team 02 Admin UI must not create or broaden Partner permissions.

## 8. Customer profile changes and lifecycle
- Display authoritative backend state and last-updated time; do not invent state from local UI.
- Profile corrections must use approved mutation workflow and revalidate contact/eligibility fields as required.
- Security-sensitive changes require an audit event without unnecessarily retaining prior sensitive values.
- Profile changes must not rewrite historical bookings, walk reports, payment or incident records.
- Account restriction/suspension must have a reason, authorized owner, effective time and review/appeal path as approved.
- Closing an account must not silently cancel/erase active walks, financial obligations, incident records or legal retention records.
- Deletion requests must be authenticated, tracked, idempotent/retryable and evaluated against approved POL-020 retention/legal-hold rules.

## 9. Admin actions — disabled until contracts exist
Potential actions for future review:
- Open customer/pet detail
- Correct permitted profile field
- Request customer contact verification/re-verification
- Record support case reference
- Restrict or restore account under approved lifecycle
- Initiate privacy request workflow
- Mark a dog profile as needing customer clarification (not as a diagnosis or safety verdict)

No action should be implemented from this draft alone. For each mutation, Team 01 must specify callable/API name, input/output, authorization, scope, validation, idempotency, audit event, error semantics and Emulator evidence. UI-only disablement is not a security control.

## 10. Sensitive data reveal and audit UX
- Default to masked contact fields.
- Reveal full contact only after an explicit permitted user action and authorization result; record who revealed it, when, why and which record/field, if backend supports it.
- Do not put full contact, health notes, exact coordinates or evidence URLs in notifications, analytics, client logs or route query parameters.
- Do not expose KYC/identity documents in customer or pet views.
- Copy/export/download is a separate capability and must be disabled until its permission, purpose, scope, watermarking/expiry and audit requirements are approved.
- Prevent screenshot/clipboard restrictions only where supported and policy-approved; do not claim that UI masking prevents screenshots.

## 11. Empty, error and restricted states
- Loading: show skeleton/progress without leaking cached sensitive data.
- No results: distinguish “no matching authorized records” from a broad “customer does not exist” claim where existence disclosure is sensitive.
- Restricted: explain that access is not permitted; do not reveal the hidden field value.
- Stale data: show last-updated timestamp; do not label stale profile as current/verified.
- Backend unavailable: show unavailable/retry state; do not fall back to hard-coded example records as if they were live.
- Partial response: clearly identify unavailable sections; do not silently substitute blank/zero/false for missing fields.
- Access denied: log/handle safely without exposing internal authorization details.
- Deletion pending/failed: show exact request state; never report deleted until trusted service confirms.

## 12. Planned acceptance tests — NOT EXECUTED
1. Customer A cannot open Customer B or their dogs/bookings by UI route, deep link, guessed ID or direct API.
2. A City Manager cannot access a sibling City; a Zone Supervisor cannot access an unassigned Zone.
3. Support can read only assigned case/customer fields; sensitive documents remain separately restricted.
4. Finance access does not expose dog health notes or live location by default.
5. Walker access is limited to an accepted/assigned booking and minimum approved dog details.
6. Walker access is reduced/revoked after assignment/service end, subject to documented incident/dispute exception.
7. Default list masks contact and omits DOB, full address, payment details and sensitive dog notes.
8. Contact reveal requires an authorized purpose and produces an audit event.
9. Missing/unverified contact is never displayed as verified.
10. Client-side age field or device clock cannot bypass the approved 18+ eligibility check.
11. Optional gender/photo fields are not forced without approved purpose and policy.
12. Breed alone does not create a safety/risk verdict.
13. Dog safety notes are not visible to unrelated customers or walkers.
14. Profile edits do not mutate historical booking, payment or incident records.
15. Account closure preserves active-walk safe handling and approved retained records.
16. Deletion request is identity-checked, idempotent/retryable, and accurately reports partial/failed outcomes.
17. Guessing storage paths cannot expose identity or private evidence documents.
18. Search, filters, counts and exports do not leak out-of-scope customer existence/data.
19. Hard-coded demo records are never presented as live records when the data source is unavailable.
20. Audit history records sensitive access/actions without secrets or unnecessary full personal data.
21. Stale or incomplete data is labelled accurately; no missing value is represented as verified.
22. Mobile layouts and accessibility labels preserve privacy state and clear action outcomes.

All checks are **PLANNED — NOT EXECUTED**. Automated widget, unit, integration and Emulator coverage must be added only after contracts and policies are approved.

## 13. Decisions required before implementation
- Founder/legal/privacy approval of POL-014, POL-020 and POL-031.
- Final Customer and Dog field schema; mandatory/optional classification and purposes.
- Approved age-verification and contact-verification method.
- Approved customer, support, manager and walker field-level access matrix.
- Exact City/Zone scope enforcement contract from Team 01 (D01/D03).
- Approved dog safety information visibility and walker acknowledgement flow.
- Account restriction, appeal, correction, closure and deletion service contracts.
- Retention periods, legal holds, backup lifecycle and evidence access rules.
- Customer/Pet API read/write contracts and Emulator allow/deny evidence.
- Decision whether any sensitive field reveal/export is needed at all.

## 14. Current status and guardrails
- Notion source policies are Draft / unapproved as fetched; legal/privacy review is pending.
- Existing Customers/Pets Admin screens were previously audited as UI-only hard-coded examples.
- This document is a requirements proposal, not a policy approval or authorization contract.
- No runtime UI, data source, API integration, Firebase rules/functions/schema, production data or Partner permissions changed.
- No tests, Emulator, CI, merge or deployment performed for this documentation-only task.
- PR #51 remains Draft and unmerged.

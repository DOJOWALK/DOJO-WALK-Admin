# DOJO WALK Company Setup — Foundation Specification

Date: 2026-10-22
Repository: `dojoplatform2026/DOJO-WALK-Admin`
Branch: `feature/company-setup-foundation`
Status: Initial UI foundation; not production-ready and not connected to persistent settings.

## Purpose
Provide one Company Setup area inside the existing Admin Panel. Keep the initial operating structure small, while documenting the controls required for future growth.

## Setup sections
1. Company Profile
2. Legal Documents
3. Departments & Designations
4. Roles & Permissions
5. Approval Authority
6. Company Policies & SOPs
7. Document Register
8. Audit & Change Log

## UI behaviour in this change
- Adds a Company Setup navigation entry in the existing Admin sidebar.
- Displays responsive cards using the existing DOJO WALK brand colors.
- Each card opens a checklist dialog explaining the information required.
- The UI explicitly labels every section as Not configured.
- It explicitly discloses that settings, document uploads, permissions and audit records are not yet saved to Firebase.

## Not included / production gates
- No company records are written to Firestore.
- No document uploads are enabled.
- No role or approval rules are enforced by this screen.
- No legal status is inferred from completing the checklist.
- Do not store identity documents, tax documents, credentials or other sensitive files in public GitHub files.
- Before persistence is added, define the Firestore schema and Firebase Rules, enforce access server-side, record audit events, and add tests for unauthorized reads/writes.
- Legal document requirements depend on the selected legal entity and applicable Indian laws; obtain qualified CA/CS/legal advice.

## Suggested implementation sequence
1. Review and merge the UI foundation only after CI passes.
2. Define and approve the company-settings data schema.
3. Implement role-enforced read/write access and audit events.
4. Add secure document storage with metadata and restricted access.
5. Implement approval policies and status transitions.
6. Add widget, rules/emulator, and end-to-end tests.
7. Only then allow real company setup data to be marked complete.

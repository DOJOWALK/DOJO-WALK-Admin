# DOJO WALK Admin — AI Contributor Instructions

## Project scope
This is the DOJO WALK Admin Portal Flutter application. The root `pubspec.yaml` defines Flutter/Dart dependencies including Firebase Auth, Firestore, Functions, Storage, Google Maps, routing, and PDF viewing. The root `firebase.json` configures Firebase Hosting from `build/web`.

## Required workflow
1. Before editing, inspect the relevant screen, state/data layer, route, Firebase service, and existing tests. Trace existing patterns instead of introducing a parallel architecture.
2. Preserve the established DOJO WALK visual system: orange `#FF7900`, warm background `#FFFAF5`, dark text `#252525`, and light premium professional styling.
3. Preserve role boundaries and server-side authorization. UI hiding is not a security control.
4. Use the repository's Flutter version/configuration. Run `flutter pub get`, `flutter analyze`, and relevant `flutter test` tests where available.
5. For web-facing changes, run the existing Admin Web Build and Full Validation workflows; report any workflow not run.

## Product and governance constraints
- Preserve the Founder/CEO → Central Admin → City/Area Manager → Zone Supervisor → Walker governance model and existing permission boundaries.
- Location creation uses State/UT → District → City → Zone; do not add a Locality dropdown. Only Zone has activation/deactivation. Zone boundaries require map verification.
- Do not reintroduce coupons or cash payments.
- Do not change production Firebase configuration, Firestore/Storage rules, user roles, approval authority, or deployment secrets without explicit approval.
- Never fabricate test users, successful approvals, live booking data, or PASS results.

## Safety and privacy
Never log or expose customer personal data, precise home addresses, KYC documents, identity images, tokens, or secrets. Keep authorization checks in trusted backend code.

## Pull requests
Use a feature branch, never commit directly to `main`. Include screenshots for UI changes, affected roles, test evidence, security implications, and rollback notes. No production deploy or merge without owner approval.


## Mandatory DOJO WALK engineering operating rules (Notion-aligned)

Follow the Notion AI Engineering Control Center and Four Team AI Coding Instructions. Central Task Register: https://app.notion.com/p/2f476768c6f14aec9e70bf04afd83df8

Before editing, inspect the assigned task and linked spec, this repository's source and instructions, working tree, active branch, recent commits and open PRs. Record task ID, branch, current commit SHA, scope, acceptance criteria, dependencies and test plan. Continue the exact active task branch; do not create a new branch merely because a chat/session changed. Check for duplicate work first. If a required decision or contract is missing, stop and report BLOCKED.

Keep the smallest safe scope. Do not silently change product policy, API/data contracts, schema, permissions, security rules or payment behavior. Team 01 owns shared backend contracts; notify affected client teams before contract changes. Never force-push, delete branches, close historical PRs or overwrite unmerged work without explicit approval.

Run relevant checks and record exact commands/workflows, timestamps, results and exact commit SHA tested. Use PASS only for checks that passed; FAIL for failures; NOT RUN for checks not executed. PRs and handoffs must include task ID, scope, risk, affected repositories, branch, PR, SHA, contract/schema version where relevant, test evidence, blockers and rollback notes.

Obtain independent review for security, permissions, payment, KYC, GPS/location and migration changes. Do not weaken authentication or security Rules to make tests pass. Production Rules, Storage Rules, Functions, secrets, destructive migrations and production data writes require explicit authorization. Merge/deploy only after required human approval. A green CI result applies only to checks run on that exact SHA and is not blanket production approval.

Do not introduce coupon or cash-payment flows. Protect KYC, selfies, customer data, GPS/location history, payment records and credentials. Do not mark work complete until acceptance criteria, test evidence, review/approval and PR/release state are accurately recorded.

## Team ownership
Admin and Website are coordinated by Team 02. Website remains a separate repository and release pipeline, not a fifth developer team. Preserve the distinction between Founder-reserved approvals and Super Admin technical access; UI hiding is not authorization.

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

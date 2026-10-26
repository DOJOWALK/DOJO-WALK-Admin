# Admin Firebase Emulator Wiring

## Purpose
The Admin app can be pointed at local Firebase emulators for integration testing without changing the default production connection.

## Safety contract
- Emulator routing is **off by default**.
- Only pass `--dart-define=DOJO_USE_FIREBASE_EMULATORS=true` for a local/emulator test session.
- Never pass that define in production builds.
- Default emulator host is `127.0.0.1`; override it only when the browser/device cannot reach the machine running the emulators.
- Emulator routing alone does not seed an authorized admin. Integration tests must create a test Auth user and seed `admin_users/{uid}` through the Emulator Suite's trusted Admin SDK setup, with role/active fields matching the authorization contract.
- Do not point emulator tests at the production project, and do not use production credentials for emulator seeding.

## Emulator endpoints
The current Firebase project configuration uses:
- Auth: `9099`
- Firestore: `8080`
- Functions: `5001`
- Functions region: `asia-south1`

## Run locally
Start the Firebase Emulator Suite using the Firebase repository's documented emulator command and wait for Auth, Firestore, and Functions to report ready. Then run the Flutter app with:

```sh
flutter run -d chrome \
  --dart-define=DOJO_USE_FIREBASE_EMULATORS=true
```

For a non-default host:

```sh
flutter run -d chrome \
  --dart-define=DOJO_USE_FIREBASE_EMULATORS=true \
  --dart-define=DOJO_FIREBASE_EMULATOR_HOST=127.0.0.1
```

## Current validation status
This change wires the app's Firebase Auth, Firestore, and regional Functions clients to the emulator endpoints when explicitly enabled. It does **not** itself constitute a passing Admin UI-to-backend E2E test. The remaining test harness must seed an emulator-only active admin identity, exercise the Add Location UI through the real `saveServiceLocationWithNameIndex` callable, and verify persisted read-back plus duplicate/unauthorized rejection. Do not mark that gate complete until the browser test actually runs in CI.

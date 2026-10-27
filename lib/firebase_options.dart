import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  /// Emulator config is opt-in. Normal builds continue to use the configured
  /// project; E2E jobs must pass --dart-define=DOJO_USE_FIREBASE_EMULATORS=true.
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      if (const bool.fromEnvironment('DOJO_USE_FIREBASE_EMULATORS')) {
        return webEmulator;
      }
      return web;
    }

    throw UnsupportedError(
      'Firebase options are configured only for Web.',
    );
  }

  /// Isolated synthetic project for automated tests. Never use production IDs
  /// for emulator-backed browser runs.
  static const FirebaseOptions webEmulator = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:1234567890:web:abcdef1234567890',
    messagingSenderId: '1234567890',
    projectId: 'demo-dojo-zone-e2e',
    authDomain: 'demo-dojo-zone-e2e.firebaseapp.com',
    storageBucket: 'demo-dojo-zone-e2e.appspot.com',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBgKva52MnBMmclLW_g3D6yHYfDrxqqmiU',
    appId: '1:177087606182:web:3e3695044e6670e6683367',
    messagingSenderId: '177087606182',
    projectId: 'dojo-platform-b68a3',
    authDomain: 'dojo-platform-b68a3.firebaseapp.com',
    storageBucket: 'dojo-platform-b68a3.firebasestorage.app',
    measurementId: 'G-LMY82ERE15',
  );
}

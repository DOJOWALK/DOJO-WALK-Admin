import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

const _firebaseProjectId = String.fromEnvironment(
  'DOJO_FIREBASE_PROJECT_ID',
  defaultValue: 'dojo-platform-b68a3',
);

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    throw UnsupportedError(
      'Firebase options are configured only for Web.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'fake-api-key-for-emulator-tests',
    appId: '1:177087606182:web:3e3695044e6670e6683367',
    messagingSenderId: '177087606182',
    projectId: _firebaseProjectId,
    authDomain: 'localhost',
    storageBucket: 'demo-dojo-platform-b68a3.appspot.com',
    measurementId: 'G-LMY82ERE15',
  );
}

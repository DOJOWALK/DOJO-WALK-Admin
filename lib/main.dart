import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const useEmulators = bool.fromEnvironment('DOJO_USE_FIREBASE_EMULATORS');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Explicit opt-in only. This block is never run in ordinary builds and
  // directs browser E2E traffic to local emulators, not production services.
  if (useEmulators) {
    if (!kIsWeb) {
      throw UnsupportedError(
        'DOJO_USE_FIREBASE_EMULATORS is currently supported for Web only.',
      );
    }
    await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
    FirebaseFunctions.instanceFor(region: 'asia-south1')
        .useFunctionsEmulator('127.0.0.1', 5001);
  }

  runApp(const DojoWalkAdminApp());
}

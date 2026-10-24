import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'firebase_options.dart';

const _useFirebaseEmulators = bool.fromEnvironment(
  'DOJO_USE_FIREBASE_EMULATORS',
  defaultValue: false,
);
const _firebaseEmulatorHost = String.fromEnvironment(
  'DOJO_FIREBASE_EMULATOR_HOST',
  defaultValue: '127.0.0.1',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Emulator routing is opt-in for local/test builds only. Production builds
  // keep using the configured Firebase project unless the explicit test define
  // is supplied at build/run time.
  if (_useFirebaseEmulators) {
    await FirebaseAuth.instance.useAuthEmulator(_firebaseEmulatorHost, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(
      _firebaseEmulatorHost,
      8080,
    );
    FirebaseFunctions.instanceFor(region: 'asia-south1').useFunctionsEmulator(
      _firebaseEmulatorHost,
      5001,
    );
  }

  runApp(const DojoWalkAdminApp());
}

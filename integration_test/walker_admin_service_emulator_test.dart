import 'dart:io' as io;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:dojo_admin/features/walkers/services/walker_admin_contracts.dart';
import 'package:dojo_admin/features/walkers/services/walker_admin_service.dart';

const projectId = String.fromEnvironment(
  'DOJO_EMULATOR_PROJECT_ID',
  defaultValue: 'demo-dojo-admin-integration',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'real WalkerAdminService rejects an unauthorised emulator user without writes',
    (tester) async {
      final app = await Firebase.initializeApp(
        name: 'dojo-walker-emulator-integration',
        options: FirebaseOptions(
          apiKey: 'fake-api-key',
          appId: '1:123456789:web:dojo-walker-integration',
          messagingSenderId: '123456789',
          projectId: projectId,
          authDomain: '$projectId.firebaseapp.com',
        ),
      );
      addTearDown(app.delete);

      final auth = FirebaseAuth.instanceFor(app: app);
      final firestore = FirebaseFirestore.instanceFor(app: app);
      // Android Emulator reaches host-machine services through 10.0.2.2;
      // loopback inside the emulator points back to the Android guest itself.
      final emulatorHost = io.Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
      await auth.useAuthEmulator(emulatorHost, 9099);
      firestore.useFirestoreEmulator(emulatorHost, 8080);

      final credential = await auth.createUserWithEmailAndPassword(
        email: 'unauthorised-${DateTime.now().microsecondsSinceEpoch}@dojo.test',
        password: 'Dojo-Emulator-Test-2026!',
      );
      final uid = credential.user!.uid;

      final service = WalkerAdminService(firestore: firestore, auth: auth);
      await expectLater(
        service.runAdminAction(
          walkerId: uid,
          action: WalkerAdminAction.approve,
        ),
        throwsA(isA<WalkerAdminServiceException>()),
      );

      // The authenticated user may read their own walker path. The service
      // must stop at the missing admin record and leave that path untouched.
      final walker = await firestore.collection('walkers').doc(uid).get();
      expect(walker.exists, isFalse);
      expect(credential.user!.uid, uid);
    },
  );
}

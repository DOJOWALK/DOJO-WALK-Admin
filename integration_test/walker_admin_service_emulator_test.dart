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
const adminEmail = 'walker-admin-integration@dojo.test';
const adminPassword = 'Dojo-Test-Only-Admin-2026!';
const ordinaryEmail = 'walker-ordinary-integration@dojo.test';
const ordinaryPassword = 'Dojo-Test-Only-User-2026!';
const walkerId = 'walker-emulator-integration-1';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('real WalkerAdminService uses Auth and Firestore emulators',
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
    await auth.useAuthEmulator('127.0.0.1', 9099);
    firestore.useFirestoreEmulator('127.0.0.1', 8080);

    await auth.signInWithEmailAndPassword(
      email: adminEmail,
      password: adminPassword,
    );

    final service = WalkerAdminService(firestore: firestore, auth: auth);
    await service.runAdminAction(
      walkerId: walkerId,
      action: WalkerAdminAction.approve,
    );

    final walker = await firestore.collection('walkers').doc(walkerId).get();
    expect(walker.data(), containsPair('status', 'approved'));
    expect(walker.data(), containsPair('verificationStatus', 'verified'));
    expect(walker.data(), containsPair('isApproved', true));
    expect(walker.data(), containsPair('isActive', true));
    expect(walker.data(), containsPair('decisionBy', auth.currentUser!.uid));

    final audit = await firestore
        .collection('audit_logs')
        .where('targetType', isEqualTo: 'walker')
        .where('targetId', isEqualTo: walkerId)
        .get();
    expect(audit.docs, hasLength(1));
    expect(audit.docs.single.data(), containsPair('actorUid', auth.currentUser!.uid));
    expect(audit.docs.single.data(), containsPair('action', 'walker_approved'));
    expect(audit.docs.single.data(), containsPair('afterStatus', 'approved'));

    await auth.signOut();
    await auth.signInWithEmailAndPassword(
      email: ordinaryEmail,
      password: ordinaryPassword,
    );

    final deniedService = WalkerAdminService(firestore: firestore, auth: auth);
    await expectLater(
      deniedService.runAdminAction(
        walkerId: walkerId,
        action: WalkerAdminAction.suspend,
        reason: 'Integration authorization denial',
      ),
      throwsA(isA<WalkerAdminServiceException>()),
    );

    final unchanged = await firestore.collection('walkers').doc(walkerId).get();
    expect(unchanged.data(), containsPair('status', 'approved'));
    expect(unchanged.data(), containsPair('isActive', true));
    final unchangedAudit = await firestore
        .collection('audit_logs')
        .where('targetType', isEqualTo: 'walker')
        .where('targetId', isEqualTo: walkerId)
        .get();
    expect(unchangedAudit.docs, hasLength(1));
  });
}

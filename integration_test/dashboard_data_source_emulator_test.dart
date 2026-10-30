import 'dart:convert';
import 'dart:io' as io;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:dojo_admin/screens/dashboard/dashboard_data_source.dart';

const projectId = String.fromEnvironment(
  'DOJO_DASHBOARD_EMULATOR_PROJECT_ID',
  defaultValue: 'demo-dojo-dashboard-integration',
);

const emulatorFirestorePort = 8080;
const emulatorAuthPort = 9099;

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final emulatorHost = io.Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
  if (!projectId.startsWith('demo-')) {
    throw StateError('Dashboard integration tests require a demo-* project ID.');
  }

  Future<FirebaseApp> createApp(String name) => Firebase.initializeApp(
        name: name,
        options: FirebaseOptions(
          apiKey: 'fake-api-key',
          appId: '1:123456789:web:$name',
          messagingSenderId: '123456789',
          projectId: projectId,
          authDomain: '$projectId.firebaseapp.com',
        ),
      );

  Future<void> connectEmulators(
    FirebaseAuth auth,
    FirebaseFirestore firestore,
  ) async {
    await auth.useAuthEmulator(emulatorHost, emulatorAuthPort);
    firestore.useFirestoreEmulator(emulatorHost, emulatorFirestorePort);
  }

  Future<void> seedDocument(
    io.HttpClient client,
    String collection,
    String id,
    Map<String, Object> fields,
  ) async {
    final uri = Uri.parse(
      'http://$emulatorHost:$emulatorFirestorePort/v1/projects/'
      '$projectId/databases/(default)/documents/$collection/$id',
    );
    final request = await client.patchUrl(uri);
    request.headers.set(io.HttpHeaders.authorizationHeader, 'Bearer owner');
    request.headers.contentType = io.ContentType.json;
    request.write(jsonEncode({'fields': fields}));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    expect(
      response.statusCode,
      anyOf(io.HttpStatus.ok, io.HttpStatus.created),
      reason: 'Emulator-only fixture seed failed: $body',
    );
  }

  testWidgets(
    'super_admin can read Dashboard metrics and recent records from Firestore Emulator',
    (tester) async {
      final app = await createApp('dojo-dashboard-super-admin');
      final auth = FirebaseAuth.instanceFor(app: app);
      final firestore = FirebaseFirestore.instanceFor(app: app);
      await connectEmulators(auth, firestore);

      final credential = await auth.createUserWithEmailAndPassword(
        email: 'dashboard-admin-${DateTime.now().microsecondsSinceEpoch}@dojo.test',
        password: 'Dojo-Dashboard-Test-2026!',
      );
      final uid = credential.user!.uid;

      final client = io.HttpClient();
      addTearDown(client.close);
      final now = DateTime.now().toUtc();
      final earlier = now.subtract(const Duration(minutes: 5));

      await seedDocument(client, 'admin_users', uid, {
        'role': {'stringValue': 'super_admin'},
        'isActive': {'booleanValue': true},
      });
      await seedDocument(client, 'bookings', 'booking-new', {
        'createdAt': {'timestampValue': now.toIso8601String()},
        'petId': {'stringValue': 'pet-new'},
        'status': {'stringValue': 'Pending'},
      });
      await seedDocument(client, 'bookings', 'booking-old', {
        'createdAt': {'timestampValue': earlier.toIso8601String()},
        'petId': {'stringValue': 'pet-old'},
        'status': {'stringValue': 'Completed'},
      });
      await seedDocument(client, 'users', 'customer-fixture', {
        'name': {'stringValue': 'Dashboard Customer'},
      });
      await seedDocument(client, 'walkers', 'walker-fixture', {
        'fullName': {'stringValue': 'Dashboard Walker'},
      });
      await seedDocument(client, 'payments', 'payment-paid', {
        'status': {'stringValue': 'paid'},
        'amount': {'doubleValue': 149.0},
      });
      await seedDocument(client, 'payments', 'payment-unpaid', {
        'status': {'stringValue': 'pending'},
        'amount': {'doubleValue': 999.0},
      });
      await seedDocument(client, 'audit_logs', 'activity-new', {
        'createdAt': {'timestampValue': now.toIso8601String()},
        'action': {'stringValue': 'walker_approved'},
        'actorUid': {'stringValue': uid},
        'actorRole': {'stringValue': 'super_admin'},
        'targetType': {'stringValue': 'walker'},
        'targetId': {'stringValue': 'walker-fixture'},
      });
      await seedDocument(client, 'audit_logs', 'activity-old', {
        'createdAt': {'timestampValue': earlier.toIso8601String()},
        'action': {'stringValue': 'walker_reactivated'},
        'actorUid': {'stringValue': uid},
        'actorRole': {'stringValue': 'super_admin'},
        'targetType': {'stringValue': 'walker'},
        'targetId': {'stringValue': 'walker-fixture'},
      });

      final source = FirestoreDashboardDataSource(firestore);
      expect(await source.countAll('bookings').first, 2);
      expect(await source.countAll('users').first, 1);
      expect(await source.countAll('walkers').first, 1);
      expect(await source.totalPaidAmount().first, 149.0);

      final bookings = await source.recentBookings().first;
      expect(bookings, hasLength(2));
      expect(bookings.first.id, 'booking-new');
      expect(bookings.first.petId, 'pet-new');

      final activity = await source.recentActivity().first;
      expect(activity, hasLength(2));
      expect(activity.first.action, 'walker_approved');
      expect(activity.first.actorRole, 'super_admin');
    },
  );

  testWidgets(
    'active support role is denied Dashboard collection reads by canonical Rules',
    (tester) async {
      final app = await createApp('dojo-dashboard-support');
      final auth = FirebaseAuth.instanceFor(app: app);
      final firestore = FirebaseFirestore.instanceFor(app: app);
      await connectEmulators(auth, firestore);

      final credential = await auth.createUserWithEmailAndPassword(
        email: 'dashboard-support-${DateTime.now().microsecondsSinceEpoch}@dojo.test',
        password: 'Dojo-Dashboard-Test-2026!',
      );
      final uid = credential.user!.uid;
      final client = io.HttpClient();
      addTearDown(client.close);

      await seedDocument(client, 'admin_users', uid, {
        'role': {'stringValue': 'support'},
        'isActive': {'booleanValue': true},
      });

      final source = FirestoreDashboardDataSource(firestore);
      await expectLater(
        source.countAll('bookings').first,
        throwsA(isA<FirebaseException>()),
      );
    },
  );
}

import 'dart:convert';
import 'dart:io' as io;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:dojo_admin/features/service_location/services/service_zone_workflow_service.dart';

const projectId = String.fromEnvironment(
  'DOJO_EMULATOR_PROJECT_ID',
  defaultValue: 'demo-dojo-admin-integration',
);

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final app = await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: 'fake-api-key',
      appId: '1:123456789:android:dojo-zone-integration',
      messagingSenderId: '123456789',
      projectId: projectId,
      authDomain: '$projectId.firebaseapp.com',
    ),
  );

  final host = io.Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
  final firestore = FirebaseFirestore.instanceFor(app: app);
  firestore.useFirestoreEmulator(host, 8080);

  final functions = FirebaseFunctions.instanceFor(
    app: app,
    region: 'asia-south1',
  );
  functions.useFunctionsEmulator(host, 5001);

  final service = ServiceZoneWorkflowService(
    firestore: firestore,
    functions: functions,
  );

  testWidgets(
    'Zone lifecycle callables reject unauthenticated requests without writes',
    (tester) async {
      await expectLater(
        service.saveDraft(
          stateId: 'test-state',
          districtId: 'test-district',
          cityId: 'test-city',
          name: 'Unauthorised Test Zone',
        ),
        throwsA(
          isA<FirebaseFunctionsException>().having(
            (error) => error.code,
            'code',
            'unauthenticated',
          ),
        ),
      );

      await expectLater(
        service.reviewBoundary(
          boundaryId: 'test-boundary',
          verified: true,
          notes: 'Unauthorised integration test',
        ),
        throwsA(
          isA<FirebaseFunctionsException>().having(
            (error) => error.code,
            'code',
            'unauthenticated',
          ),
        ),
      );

      await expectLater(
        service.submitForFounderReview('test-zone'),
        throwsA(
          isA<FirebaseFunctionsException>().having(
            (error) => error.code,
            'code',
            'unauthenticated',
          ),
        ),
      );

      await expectLater(
        service.decideFounderApproval(
          zoneId: 'test-zone',
          decision: 'approve',
          notes: '',
        ),
        throwsA(
          isA<FirebaseFunctionsException>().having(
            (error) => error.code,
            'code',
            'unauthenticated',
          ),
        ),
      );

      await expectLater(
        service.activate('test-zone'),
        throwsA(
          isA<FirebaseFunctionsException>().having(
            (error) => error.code,
            'code',
            'unauthenticated',
          ),
        ),
      );

      // Use the Emulator-only owner token for verification because the
      // unauthenticated app is intentionally not allowed to read these paths.
      // This token must never be used against a production Firebase endpoint.
      final client = io.HttpClient();
      addTearDown(client.close);
      final documentsUri = Uri.parse(
        'http://$host:8080/v1/projects/$projectId/databases/(default)/documents',
      );

      Future<List<dynamic>> readEmulatorCollection(String collection) async {
        final uri = documentsUri.replace(path: '${documentsUri.path}/$collection');
        final request = await client.getUrl(uri);
        request.headers.set(io.HttpHeaders.authorizationHeader, 'Bearer owner');
        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();
        expect(
          response.statusCode,
          io.HttpStatus.ok,
          reason: 'Emulator owner read failed for $collection: $body',
        );
        final decoded = jsonDecode(body) as Map<String, dynamic>;
        return (decoded['documents'] as List<dynamic>?) ?? const [];
      }

      expect(
        await readEmulatorCollection('service_zones'),
        isEmpty,
        reason: 'Unauthenticated Zone requests must not create Zone records.',
      );
      expect(
        await readEmulatorCollection('service_location_boundary_review_audit'),
        isEmpty,
        reason: 'Unauthenticated boundary reviews must not write audit records.',
      );
    },
  );
}

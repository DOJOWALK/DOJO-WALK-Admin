import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/services/location_csv_import_service.dart';

void main() {
  test('preflight exception explains that location writes were not attempted', () {
    const error = LocationCsvImportPreflightException('CSV exceeds plan limit');
    expect(
      error.toString(),
      contains('before any location writes: CSV exceeds plan limit'),
    );
  });

  group('validateLocationCsvImportRunId', () {
    test('trims and preserves a stable valid ID', () {
      expect(validateLocationCsvImportRunId('  import-run-123  '), 'import-run-123');
    });

    test('rejects an empty ID', () {
      expect(() => validateLocationCsvImportRunId('  '), throwsArgumentError);
    });

    test('rejects a slash that is invalid in a Firestore document ID', () {
      expect(() => validateLocationCsvImportRunId('run/child'), throwsArgumentError);
    });
  });

  group('isDefinitiveLocationImportRunNotFound', () {
    test('continues only for a definitive not-found response', () {
      expect(isDefinitiveLocationImportRunNotFound('not-found'), isTrue);
    });

    test('fails closed for authorization, fingerprint, and transient errors', () {
      for (final code in [
        'permission-denied',
        'failed-precondition',
        'unauthenticated',
        'unavailable',
        'deadline-exceeded',
        'internal',
        'unknown',
      ]) {
        expect(isDefinitiveLocationImportRunNotFound(code), isFalse, reason: code);
      }
    });
  });

  group('ensureLocationCsvImportRunMarkerIsNew', () {
    test('allows a run ID when the trusted marker is definitively absent', () {
      expect(
        () => ensureLocationCsvImportRunMarkerIsNew(markerExists: false),
        returnsNormally,
      );
    });

    test('blocks a run ID when a durable marker exists without requiring an audit', () {
      expect(
        () => ensureLocationCsvImportRunMarkerIsNew(markerExists: true),
        throwsStateError,
      );
    });
  });

  group('ensureLocationCsvImportRunIsNew', () {
    test('allows a run ID with no prior audit record', () {
      expect(
        () => ensureLocationCsvImportRunIsNew(auditRecordExists: false),
        returnsNormally,
      );
    });

    test('rejects a run ID that already has an immutable audit record', () {
      expect(
        () => ensureLocationCsvImportRunIsNew(auditRecordExists: true),
        throwsStateError,
      );
    });
  });

  group('classifyLocationCsvImportFailure', () {
    test('reports failed when no location write was attempted', () {
      expect(
        classifyLocationCsvImportFailure(
          allLocationWritesCompleted: false,
          locationWriteAttempted: false,
        ),
        'failed',
      );
    });

    test('reports partial failure when a callable write was attempted', () {
      // The callable may commit remotely even if the client sees a timeout.
      expect(
        classifyLocationCsvImportFailure(
          allLocationWritesCompleted: false,
          locationWriteAttempted: true,
        ),
        'partial_failure',
      );
    });

    test('reports audit failure after all location writes completed', () {
      expect(
        classifyLocationCsvImportFailure(
          allLocationWritesCompleted: true,
          locationWriteAttempted: true,
        ),
        'audit_failed',
      );
    });
  });
}

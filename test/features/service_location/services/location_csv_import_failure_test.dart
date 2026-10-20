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

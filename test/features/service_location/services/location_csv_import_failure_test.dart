import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/services/location_csv_import_service.dart';

void main() {
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

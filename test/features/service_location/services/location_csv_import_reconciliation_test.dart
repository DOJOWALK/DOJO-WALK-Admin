import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/service_location/services/location_csv_import_reconciliation.dart';

void main() {
  group('decideLocationCsvImportRecovery', () {
    test('starts a new run only when no prior run record exists', () {
      expect(
        decideLocationCsvImportRecovery(
          runRecordExists: false,
          priorStatus: null,
          priorFingerprint: null,
          requestedFingerprint: 'sha256:abc',
          hierarchyMatchesPlan: false,
        ),
        LocationCsvImportRecoveryAction.startNewRun,
      );
    });

    test('rejects reuse of a run ID with a different input fingerprint', () {
      expect(
        decideLocationCsvImportRecovery(
          runRecordExists: true,
          priorStatus: 'partial_failure',
          priorFingerprint: 'sha256:old',
          requestedFingerprint: 'sha256:new',
          hierarchyMatchesPlan: true,
        ),
        LocationCsvImportRecoveryAction.rejectRunIdReuse,
      );
    });

    test('requires manual reconciliation when prior metadata is incomplete', () {
      expect(
        decideLocationCsvImportRecovery(
          runRecordExists: true,
          priorStatus: null,
          priorFingerprint: null,
          requestedFingerprint: 'sha256:abc',
          hierarchyMatchesPlan: true,
        ),
        LocationCsvImportRecoveryAction.rejectRunIdReuse,
      );
    });

    test('recognizes a completed run only when hierarchy matches the plan', () {
      expect(
        decideLocationCsvImportRecovery(
          runRecordExists: true,
          priorStatus: 'completed',
          priorFingerprint: 'sha256:abc',
          requestedFingerprint: 'sha256:abc',
          hierarchyMatchesPlan: true,
        ),
        LocationCsvImportRecoveryAction.alreadyCompleted,
      );
      expect(
        decideLocationCsvImportRecovery(
          runRecordExists: true,
          priorStatus: 'completed',
          priorFingerprint: 'sha256:abc',
          requestedFingerprint: 'sha256:abc',
          hierarchyMatchesPlan: false,
        ),
        LocationCsvImportRecoveryAction.requireManualReconciliation,
      );
    });

    test('allows resume only after prior hierarchy is verified against plan', () {
      expect(
        decideLocationCsvImportRecovery(
          runRecordExists: true,
          priorStatus: 'partial_failure',
          priorFingerprint: 'sha256:abc',
          requestedFingerprint: 'sha256:abc',
          hierarchyMatchesPlan: true,
        ),
        LocationCsvImportRecoveryAction.resumeAfterVerification,
      );
      expect(
        decideLocationCsvImportRecovery(
          runRecordExists: true,
          priorStatus: 'partial_failure',
          priorFingerprint: 'sha256:abc',
          requestedFingerprint: 'sha256:abc',
          hierarchyMatchesPlan: false,
        ),
        LocationCsvImportRecoveryAction.requireManualReconciliation,
      );
    });

    test('unknown prior status fails closed', () {
      expect(
        decideLocationCsvImportRecovery(
          runRecordExists: true,
          priorStatus: 'unknown-status',
          priorFingerprint: 'sha256:abc',
          requestedFingerprint: 'sha256:abc',
          hierarchyMatchesPlan: true,
        ),
        LocationCsvImportRecoveryAction.requireManualReconciliation,
      );
    });

    test('rejects an empty requested fingerprint', () {
      expect(
        () => decideLocationCsvImportRecovery(
          runRecordExists: false,
          priorStatus: null,
          priorFingerprint: null,
          requestedFingerprint: ' ',
          hierarchyMatchesPlan: false,
        ),
        throwsArgumentError,
      );
    });
  });
}

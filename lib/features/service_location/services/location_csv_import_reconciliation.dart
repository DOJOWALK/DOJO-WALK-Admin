/// Pure decision rules for a future CSV import resume/reconciliation flow.
///
/// This does not perform Firestore reads or writes and must not be treated as
/// proof that a remote write committed. Callers must first read authoritative
/// run and hierarchy state, validate every existing document against the plan,
/// and stop for manual review when state is missing or inconsistent.
enum LocationCsvImportRecoveryAction {
  startNewRun,
  resumeAfterVerification,
  alreadyCompleted,
  rejectRunIdReuse,
  requireManualReconciliation,
}

/// Chooses a conservative recovery action from persisted run metadata.
///
/// [sameFingerprint] must be computed from a canonical representation of the
/// validated input (not merely the filename). A missing/unknown prior status,
/// mismatched fingerprint, or ambiguous outcome must never trigger writes.
LocationCsvImportRecoveryAction decideLocationCsvImportRecovery({
  required bool runRecordExists,
  required String? priorStatus,
  required String? priorFingerprint,
  required String requestedFingerprint,
  required bool hierarchyMatchesPlan,
}) {
  final requested = requestedFingerprint.trim();
  final fingerprint = priorFingerprint?.trim() ?? '';
  final status = priorStatus?.trim() ?? '';

  if (requested.isEmpty) {
    throw ArgumentError('A validated input fingerprint is required.');
  }
  if (!runRecordExists) {
    return LocationCsvImportRecoveryAction.startNewRun;
  }
  if (fingerprint.isEmpty || status.isEmpty || fingerprint != requested) {
    return LocationCsvImportRecoveryAction.rejectRunIdReuse;
  }
  if (status == 'completed') {
    return hierarchyMatchesPlan
        ? LocationCsvImportRecoveryAction.alreadyCompleted
        : LocationCsvImportRecoveryAction.requireManualReconciliation;
  }
  if (status == 'started' || status == 'partial_failure' ||
      status == 'audit_failed' || status == 'needs_reconciliation') {
    return hierarchyMatchesPlan
        ? LocationCsvImportRecoveryAction.resumeAfterVerification
        : LocationCsvImportRecoveryAction.requireManualReconciliation;
  }
  return LocationCsvImportRecoveryAction.requireManualReconciliation;
}

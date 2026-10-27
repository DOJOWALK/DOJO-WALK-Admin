/// Typed client-side representation of the Zone workflow stored by Firebase.
///
/// This model is a UI projection, not an authorization boundary. Firebase
/// callable functions must re-check role, ancestry, verified boundary geometry,
/// revision and the canonical boundary hash before any state transition.
enum ZoneWorkflowStatus {
  draft,
  submitted,
  changesRequired,
  rejected,
  approved,
  active,
  deactivationSubmitted,
  deactivationApproved,
  reactivationSubmitted,
  suspended,
  deactivated,
}

class ServiceLocationZone {
  const ServiceLocationZone({
    required this.id,
    required this.name,
    required this.stateId,
    required this.districtId,
    required this.cityId,
    required this.workflowStatus,
    required this.revision,
    required this.isServiceActive,
    this.verifiedBoundaryId,
    this.founderDecision,
    this.approvalUid,
    this.approvedRevision,
    this.approvedBoundaryHash,
  });

  final String id;
  final String name;
  final String stateId;
  final String districtId;
  final String cityId;
  final ZoneWorkflowStatus workflowStatus;
  final int revision;
  final bool isServiceActive;
  final String? verifiedBoundaryId;

  /// These names match the actual Zone document fields written by Firebase.
  final String? founderDecision;
  final String? approvalUid;
  final int? approvedRevision;
  final String? approvedBoundaryHash;

  /// UI hint only: this checks the recorded approval and revision.
  ///
  /// It cannot verify that the approved hash still matches the canonical
  /// boundary document. The activateServiceZone callable performs that check.
  bool get hasRecordedFounderApprovalForCurrentRevision =>
      workflowStatus == ZoneWorkflowStatus.approved &&
      founderDecision == 'approve' &&
      approvalUid != null &&
      approvalUid!.isNotEmpty &&
      approvedRevision == revision &&
      approvedBoundaryHash != null &&
      approvedBoundaryHash!.isNotEmpty;

  /// UI hint only; backend remains authoritative for activation eligibility.
  bool get mayRequestActivation =>
      !isServiceActive &&
      hasRecordedFounderApprovalForCurrentRevision &&
      verifiedBoundaryId != null &&
      verifiedBoundaryId!.isNotEmpty;

  factory ServiceLocationZone.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    String requiredString(String key) {
      final value = data[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('Zone field "$key" is missing or invalid.');
      }
      return value.trim();
    }

    int requiredRevision() {
      final value = data['revision'];
      if (value is int && value >= 0) return value;
      throw const FormatException('Zone field "revision" is invalid.');
    }

    bool requiredActive() {
      final value = data['isServiceActive'];
      if (value is bool) return value;
      throw const FormatException('Zone field "isServiceActive" is invalid.');
    }

    String? optionalString(String key) {
      final value = data[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    int? optionalInt(String key) {
      final value = data[key];
      return value is int && value >= 0 ? value : null;
    }

    return ServiceLocationZone(
      id: id,
      name: requiredString('name'),
      stateId: requiredString('stateId'),
      districtId: requiredString('districtId'),
      cityId: requiredString('cityId'),
      workflowStatus: _parseWorkflowStatus(data['workflowStatus']),
      revision: requiredRevision(),
      isServiceActive: requiredActive(),
      verifiedBoundaryId: optionalString('verifiedBoundaryId'),
      founderDecision: optionalString('founderDecision'),
      approvalUid: optionalString('approvalUid'),
      approvedRevision: optionalInt('approvedRevision'),
      approvedBoundaryHash: optionalString('approvedBoundaryHash'),
    );
  }
}

ZoneWorkflowStatus _parseWorkflowStatus(Object? value) {
  switch (value) {
    case 'draft':
      return ZoneWorkflowStatus.draft;
    case 'submitted':
      return ZoneWorkflowStatus.submitted;
    case 'changes_required':
      return ZoneWorkflowStatus.changesRequired;
    case 'rejected':
      return ZoneWorkflowStatus.rejected;
    case 'approved':
      return ZoneWorkflowStatus.approved;
    case 'active':
      return ZoneWorkflowStatus.active;
    case 'deactivation_submitted':
      return ZoneWorkflowStatus.deactivationSubmitted;
    case 'deactivation_approved':
      return ZoneWorkflowStatus.deactivationApproved;
    case 'reactivation_submitted':
      return ZoneWorkflowStatus.reactivationSubmitted;
    case 'suspended':
      return ZoneWorkflowStatus.suspended;
    case 'deactivated':
      return ZoneWorkflowStatus.deactivated;
    default:
      throw FormatException('Unknown Zone workflowStatus: $value');
  }
}

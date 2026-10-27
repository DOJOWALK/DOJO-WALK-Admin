/// Typed client-side representation of the Founder-approved Zone workflow.
///
/// This model deliberately does not grant permissions or decide whether a Zone
/// can be activated. Firebase callable authorization and transactional checks
/// are authoritative; UI state must never be treated as a security boundary.
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

enum ZoneApprovalStatus {
  pending,
  approved,
  rejected,
  changesRequired,
  reactivationApproved,
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
    this.boundaryHash,
    this.approvalStatus,
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
  final String? boundaryHash;
  final ZoneApprovalStatus? approvalStatus;
  final int? approvedRevision;
  final String? approvedBoundaryHash;

  /// True only when the client-visible approval references the current
  /// revision and boundary hash. The backend must re-check this transactionally.
  bool get hasCurrentFounderApproval {
    final currentHash = boundaryHash;
    return approvalStatus == ZoneApprovalStatus.approved &&
        approvedRevision != null &&
        approvedRevision == revision &&
        currentHash != null &&
        currentHash.isNotEmpty &&
        approvedBoundaryHash == currentHash;
  }

  /// UI hint only; activation must always be authorized by the callable.
  bool get mayRequestActivation =>
      workflowStatus == ZoneWorkflowStatus.approved &&
      !isServiceActive &&
      hasCurrentFounderApproval;

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
      boundaryHash: optionalString('boundaryHash'),
      approvalStatus: _parseApprovalStatus(data['approvalStatus']),
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

ZoneApprovalStatus? _parseApprovalStatus(Object? value) {
  switch (value) {
    case null:
      return null;
    case 'pending':
      return ZoneApprovalStatus.pending;
    case 'approved':
      return ZoneApprovalStatus.approved;
    case 'rejected':
      return ZoneApprovalStatus.rejected;
    case 'changes_required':
      return ZoneApprovalStatus.changesRequired;
    case 'reactivation_approved':
      return ZoneApprovalStatus.reactivationApproved;
    default:
      throw FormatException('Unknown Zone approvalStatus: $value');
  }
}

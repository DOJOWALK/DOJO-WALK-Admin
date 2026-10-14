import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Shared Firestore service for DOJO WALK Admin Walker Management.
///
/// Used by:
/// - walker_manager_screen.dart
/// - walker_details_screen.dart
class WalkerAdminService {
  WalkerAdminService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _walkers =>
      _firestore.collection('walkers');

  CollectionReference<Map<String, dynamic>> get _auditLogs =>
      _firestore.collection('audit_logs');

  /// Returns the currently signed-in admin UID.
  String _requireAdminUid() {
    final uid = _auth.currentUser?.uid;

    if (uid == null || uid.isEmpty) {
      throw StateError('Admin login is required.');
    }

    return uid;
  }

  /// Reads a walker document.
  Future<Map<String, dynamic>?> getWalker(String walkerId) async {
    _validateId(walkerId);

    final snapshot = await _walkers.doc(walkerId).get();

    if (!snapshot.exists) {
      return null;
    }

    return snapshot.data();
  }

  /// Approves and activates a verified walker.
  ///
  /// This follows the current Firestore decision rules:
  /// approved => verified, approved, active.
  Future<void> approveWalker({
    required String walkerId,
    String? reason,
  }) {
    return _applyDecision(
      walkerId: walkerId,
      action: 'walker_approved',
      reason: reason,
      newStatus: 'approved',
      verificationStatus: 'verified',
      isApproved: true,
      isActive: true,
    );
  }

  /// Rejects a walker application.
  Future<void> rejectWalker({
    required String walkerId,
    required String reason,
  }) {
    _requireReason(reason);

    return _applyDecision(
      walkerId: walkerId,
      action: 'walker_rejected',
      reason: reason,
      newStatus: 'rejected',
      verificationStatus: 'rejected',
      isApproved: false,
      isActive: false,
    );
  }

  /// Requests corrections from a walker.
  Future<void> requestCorrection({
    required String walkerId,
    required String reason,
  }) {
    _requireReason(reason);

    return _applyDecision(
      walkerId: walkerId,
      action: 'walker_correction_requested',
      reason: reason,
      newStatus: 'correction_required',
      verificationStatus: 'correction_required',
      isApproved: false,
      isActive: false,
    );
  }

  /// Suspends an already verified walker.
  Future<void> suspendWalker({
    required String walkerId,
    required String reason,
  }) {
    _requireReason(reason);

    return _applyDecision(
      walkerId: walkerId,
      action: 'walker_suspended',
      reason: reason,
      newStatus: 'suspended',
      verificationStatus: 'verified',
      isApproved: true,
      isActive: false,
    );
  }

  /// Reactivates a previously suspended, verified walker.
  Future<void> reactivateWalker({
    required String walkerId,
    String? reason,
  }) {
    return _applyDecision(
      walkerId: walkerId,
      action: 'walker_reactivated',
      reason: reason,
      newStatus: 'approved',
      verificationStatus: 'verified',
      isApproved: true,
      isActive: true,
    );
  }

  /// Applies a walker decision and writes its audit log atomically.
  Future<void> _applyDecision({
    required String walkerId,
    required String action,
    required String newStatus,
    required String verificationStatus,
    required bool isApproved,
    required bool isActive,
    String? reason,
  }) async {
    _validateId(walkerId);

    final adminUid = _requireAdminUid();

    final walkerRef = _walkers.doc(walkerId);
    final auditRef = _auditLogs.doc();

    await _firestore.runTransaction<void>((transaction) async {
      final walkerSnapshot = await transaction.get(walkerRef);

      if (!walkerSnapshot.exists) {
        throw StateError('Walker not found.');
      }

      final walkerData = walkerSnapshot.data() ?? <String, dynamic>{};
      final beforeStatus = _statusOf(walkerData);

      _validateTransition(
        action: action,
        currentStatus: beforeStatus,
        currentData: walkerData,
      );

      final walkerUpdate = <String, dynamic>{
        'status': newStatus,
        'verificationStatus': verificationStatus,
        'isApproved': isApproved,
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
        'decisionBy': adminUid,
        'decisionAt': FieldValue.serverTimestamp(),
      };

      final cleanReason = reason?.trim();

      if (cleanReason != null && cleanReason.isNotEmpty) {
        walkerUpdate['decisionReason'] = cleanReason;
      }

      transaction.update(walkerRef, walkerUpdate);

      final auditData = <String, dynamic>{
        'actorUid': adminUid,
        'actorRole': 'super_admin',
        'action': action,
        'targetType': 'walker',
        'targetId': walkerId,
        'beforeStatus': beforeStatus,
        'afterStatus': newStatus,
        'createdAt': FieldValue.serverTimestamp(),
        'metadata': <String, dynamic>{
          'verificationStatus': verificationStatus,
          'isApproved': isApproved,
          'isActive': isActive,
        },
      };

      if (cleanReason != null && cleanReason.isNotEmpty) {
        auditData['reason'] = cleanReason;
      }

      transaction.set(auditRef, auditData);
    });
  }

  /// Prevents decisions that do not match the current walker state.
  void _validateTransition({
    required String action,
    required String currentStatus,
    required Map<String, dynamic> currentData,
  }) {
    switch (action) {
      case 'walker_approved':
        if (currentStatus == 'rejected' ||
            currentStatus == 'suspended' ||
            currentStatus == 'inactive' ||
            currentStatus == 'left') {
          throw StateError(
            'This walker cannot be approved from the current status.',
          );
        }
        break;

      case 'walker_rejected':
      case 'walker_correction_requested':
        if (currentStatus == 'rejected' ||
            currentStatus == 'suspended' ||
            currentStatus == 'inactive' ||
            currentStatus == 'left') {
          throw StateError(
            'This decision is not allowed from the current status.',
          );
        }
        break;

      case 'walker_suspended':
        if (currentStatus != 'approved' ||
            currentData['verificationStatus'] != 'verified' ||
            currentData['isApproved'] != true) {
          throw StateError(
            'Only an approved, verified walker can be suspended.',
          );
        }
        break;

      case 'walker_reactivated':
        if (currentStatus != 'suspended' ||
            currentData['verificationStatus'] != 'verified' ||
            currentData['isApproved'] != true) {
          throw StateError(
            'Only a suspended, verified walker can be reactivated.',
          );
        }
        break;

      default:
        throw ArgumentError('Unsupported walker action: $action');
    }
  }

  String _statusOf(Map<String, dynamic> data) {
    final status = data['status'];

    if (status is String && status.trim().isNotEmpty) {
      return status.trim().toLowerCase();
    }

    return 'pending';
  }

  void _validateId(String walkerId) {
    if (walkerId.trim().isEmpty) {
      throw ArgumentError('Walker ID cannot be empty.');
    }
  }

  void _requireReason(String reason) {
    if (reason.trim().isEmpty) {
      throw ArgumentError('A reason is required for this action.');
    }
  }
}

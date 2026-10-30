import '../utils/walker_admin_helpers.dart';
import 'walker_admin_contracts.dart';

/// Pure, deterministic lifecycle transition validation.
///
/// This class does not authorize callers and does not write Firestore.
/// Authorization and audit persistence remain the responsibility of the
/// trusted service/backend and Firestore Security Rules.
class WalkerAdminTransitionPolicy {
  WalkerAdminTransitionPolicy._();

  static Map<String, dynamic> buildChanges({
    required WalkerAdminAction action,
    required String status,
    required String verificationStatus,
    required bool isApproved,
    required bool isActive,
    required bool applicationSubmitted,
  }) {
    switch (action) {
      case WalkerAdminAction.approve:
        if (!applicationSubmitted ||
            _isTerminalStatus(status) ||
            verificationStatus == 'rejected' ||
            status == 'correction_required') {
          throw const WalkerAdminServiceException(
            'This application is not eligible for approval.',
          );
        }
        return {
          'status': 'approved',
          'verificationStatus': 'verified',
          'isApproved': true,
          'isActive': true,
        };

      case WalkerAdminAction.reject:
        if (!applicationSubmitted ||
            verificationStatus == 'verified' ||
            isApproved ||
            _isTerminalStatus(status)) {
          throw const WalkerAdminServiceException(
            'This application is not eligible for rejection.',
          );
        }
        return {
          'status': 'rejected',
          'verificationStatus': 'rejected',
          'isApproved': false,
          'isActive': false,
        };

      case WalkerAdminAction.suspend:
        if (status != 'approved' ||
            verificationStatus != 'verified' ||
            !isApproved ||
            !isActive) {
          throw const WalkerAdminServiceException(
            'Only an active, approved walker can be suspended.',
          );
        }
        return {
          'status': 'suspended',
          'verificationStatus': 'verified',
          'isApproved': true,
          'isActive': false,
        };

      case WalkerAdminAction.reactivate:
        if (status != 'suspended' ||
            verificationStatus != 'verified' ||
            !isApproved) {
          throw const WalkerAdminServiceException(
            'This walker is not eligible for reactivation.',
          );
        }
        return {
          'status': 'approved',
          'verificationStatus': 'verified',
          'isApproved': true,
          'isActive': true,
        };

      case WalkerAdminAction.requestCorrection:
        if (!applicationSubmitted ||
            _isTerminalStatus(status) ||
            verificationStatus == 'verified' ||
            isApproved) {
          throw const WalkerAdminServiceException(
            'This application is not eligible for correction.',
          );
        }
        return {
          'status': 'correction_required',
          'verificationStatus': 'correction_required',
          'isApproved': false,
          'isActive': false,
        };
    }
  }

  static bool _isTerminalStatus(String status) {
    return status == 'rejected' ||
        status == 'suspended' ||
        status == 'inactive' ||
        status == 'left';
  }
}

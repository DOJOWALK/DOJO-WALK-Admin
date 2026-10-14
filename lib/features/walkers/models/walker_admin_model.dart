import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/walker_admin_helpers.dart';

/// Data model for a DOJO WALK Partner / Walker.
///
/// This model reads walker data from Firestore.
/// Admin decisions and Firestore writes belong in WalkerAdminService.
class WalkerAdminModel {
  final String uid;

  final String name;
  final String? phoneNumber;
  final String? email;
  final String? photoUrl;

  final String status;
  final String verificationStatus;

  final bool isApproved;
  final bool isActive;
  final bool applicationSubmitted;

  final String? area;
  final String? city;
  final String? state;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? submittedAt;
  final DateTime? decisionAt;

  final String? decisionBy;
  final String? decisionReason;

  final Map<String, dynamic> kyc;
  final Map<String, dynamic> rawData;

  const WalkerAdminModel({
    required this.uid,
    required this.name,
    required this.status,
    required this.verificationStatus,
    required this.isApproved,
    required this.isActive,
    required this.applicationSubmitted,
    this.phoneNumber,
    this.email,
    this.photoUrl,
    this.area,
    this.city,
    this.state,
    this.createdAt,
    this.updatedAt,
    this.submittedAt,
    this.decisionAt,
    this.decisionBy,
    this.decisionReason,
    this.kyc = const <String, dynamic>{},
    this.rawData = const <String, dynamic>{},
  });

  // ----------------------------------------------------------
  // FIRESTORE CONVERSION
  // ----------------------------------------------------------

  /// Creates a model from a Firestore walker document.
  factory WalkerAdminModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};

    return WalkerAdminModel.fromMap(
      uid: snapshot.id,
      data: data,
    );
  }

  /// Creates a model from a map.
  ///
  /// The supplied map is not modified.
  factory WalkerAdminModel.fromMap({
    required String uid,
    required Map<String, dynamic> data,
  }) {
    final kycData = WalkerAdminHelpers.asMap(data['kyc']);

    return WalkerAdminModel(
      uid: uid,
      name: WalkerAdminHelpers.walkerName(data),
      phoneNumber: WalkerAdminHelpers.phoneNumber(data),
      email: WalkerAdminHelpers.email(data),
      photoUrl: WalkerAdminHelpers.photoUrl(data),
      status: WalkerAdminHelpers.normalizeStatus(data['status']),
      verificationStatus: WalkerAdminHelpers.normalizeStatus(
        data['verificationStatus'],
      ),
      isApproved: data['isApproved'] == true,
      isActive: data['isActive'] == true,
      applicationSubmitted: data['applicationSubmitted'] == true,
      area: _firstString(data, ['area', 'locality']),
      city: _firstString(data, ['city']),
      state: _firstString(data, ['state', 'stateName']),
      createdAt: WalkerAdminHelpers.toDateTime(
        data['createdAt'],
      ),
      updatedAt: WalkerAdminHelpers.toDateTime(
        data['updatedAt'],
      ),
      submittedAt: WalkerAdminHelpers.toDateTime(
        data['submittedAt'] ?? data['applicationSubmittedAt'],
      ),
      decisionAt: WalkerAdminHelpers.toDateTime(
        data['decisionAt'],
      ),
      decisionBy: _firstString(data, ['decisionBy']),
      decisionReason: _firstString(
        data,
        ['decisionReason'],
      ),
      kyc: Map<String, dynamic>.unmodifiable(kycData),
      rawData: Map<String, dynamic>.unmodifiable(
        Map<String, dynamic>.from(data),
      ),
    );
  }

  // ----------------------------------------------------------
  // STATUS HELPERS
  // ----------------------------------------------------------

  /// Human-readable account status.
  String get displayStatus {
    return WalkerAdminHelpers.displayStatus(status);
  }

  /// Human-readable verification status.
  String get displayVerificationStatus {
    return WalkerAdminHelpers.displayStatus(
      verificationStatus,
    );
  }

  /// Whether the walker is verified.
  bool get isVerified {
    return verificationStatus == 'verified';
  }

  /// Whether the walker is eligible based on account state.
  ///
  /// This does not check booking conflicts or live GPS.
  bool get isEligibleForAvailability {
    return WalkerAdminHelpers.isEligibleForAvailability(
      rawData,
    );
  }

  /// Whether the application is awaiting admin review.
  bool get isUnderReview {
    return WalkerAdminHelpers.isApplicationUnderReview(
      rawData,
    );
  }

  /// Whether the application has been rejected.
  bool get isRejected {
    return WalkerAdminHelpers.isRejected(rawData);
  }

  /// Whether the account is suspended.
  bool get isSuspended {
    return WalkerAdminHelpers.isSuspended(rawData);
  }

  /// Combined location label.
  String get locationLabel {
    return WalkerAdminHelpers.locationLabel(rawData);
  }

  // ----------------------------------------------------------
  // KYC HELPERS
  // ----------------------------------------------------------

  /// Gets a KYC document reference by key.
  ///
  /// Example keys:
  /// aadhaar_front, aadhaar_back, pan_card.
  String? documentReference(String documentKey) {
    return WalkerAdminHelpers.documentReference(
      kyc[documentKey],
    );
  }

  /// Checks whether a KYC document has a reference.
  ///
  /// A reference does not guarantee that the remote file exists.
  bool hasDocument(String documentKey) {
    return WalkerAdminHelpers.hasDocumentReference(
      kyc[documentKey],
    );
  }

  // ----------------------------------------------------------
  // INTERNAL
  // ----------------------------------------------------------

  static String? _firstString(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    return WalkerAdminHelpers.firstString(
      data,
      keys,
    );
  }
}

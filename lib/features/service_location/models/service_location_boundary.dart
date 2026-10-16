import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/service_location_boundary.dart';

/// DOJO WALK Admin
///
/// Service Location Boundary Service.
///
/// Supported lifecycle with the current Firestore Rules:
///
/// New boundary:
///   Create -> Pending
///
/// Review:
///   Pending -> Verified
///   Pending -> Rejected
///
/// Rejected boundary:
///   Rejected -> Pending (after editing/resubmission)
///
/// Important:
/// - Firestore Security Rules remain authoritative.
/// - Verified boundaries cannot be edited or deleted.
/// - Only pending boundaries can be verified or rejected.
/// - Location ID and type cannot be changed after creation.
/// - The current Rules do not support a separate Firestore draft status.
/// - Verification does not automatically activate a service location.
class ServiceLocationBoundaryService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ServiceLocationBoundaryService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _boundaries =>
      _firestore.collection('service_location_boundaries');

  // ============================================================
  // AUTHENTICATION
  // ============================================================

  String get _currentUid {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError(
        'Please sign in before managing service boundaries.',
      );
    }

    return user.uid;
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _required(String value, String field) {
    final result = value.trim();

    if (result.isEmpty) {
      throw ArgumentError('$field is required.');
    }

    return result;
  }

  bool _isSupportedLocationType(String value) {
    return const {'city', 'area', 'locality'}.contains(
      value.trim().toLowerCase(),
    );
  }

  String _normalizeStatus(Object? value) {
    return value?.toString().trim().toLowerCase() ?? '';
  }

  Map<String, dynamic> _serializePoints(
    List<GeoPoint> points,
  ) {
    return {
      'points': points
          .map(
            (point) => GeoPoint(
              point.latitude,
              point.longitude,
            ),
          )
          .toList(growable: false),
    };
  }

  void _validateLocation({
    required String locationId,
    required String locationType,
  }) {
    _required(locationId, 'Location ID');

    if (!_isSupportedLocationType(locationType)) {
      throw ArgumentError(
        'Location type must be city, area, or locality.',
      );
    }
  }

  List<String> _validationErrors(
    ServiceLocationBoundary boundary,
  ) {
    final errors = <String>[
      ...boundary.validate(),
    ];

    if (boundary.locationId.trim().isEmpty) {
      errors.add('Location ID is required.');
    }

    if (!_isSupportedLocationType(boundary.locationType)) {
      errors.add(
        'Location type must be city, area, or locality.',
      );
    }

    if (boundary.sourceName.trim().isEmpty) {
      errors.add('Boundary source name is required.');
    }

    if (boundary.sourceReference.trim().isEmpty) {
      errors.add('Boundary source reference is required.');
    }

    if (boundary.points.length < 3) {
      errors.add(
        'A polygon must contain at least three points.',
      );
    }

    return errors.toSet().toList(growable: false);
  }

  void _throwIfInvalid(
    ServiceLocationBoundary boundary,
  ) {
    final errors = _validationErrors(boundary);

    if (errors.isNotEmpty) {
      throw ArgumentError(
        'Boundary validation failed:\n${errors.join('\n')}',
      );
    }
  }

  void _requireEditableStatus(String status) {
    if (status == BoundaryVerificationStatus.verified.name) {
      throw StateError(
        'Verified boundaries cannot be edited.',
      );
    }

    if (status != BoundaryVerificationStatus.pending.name &&
        status != BoundaryVerificationStatus.rejected.name) {
      throw StateError(
        'Only pending or rejected boundaries can be edited.',
      );
    }
  }

  void _requirePendingStatus(String status) {
    if (status != BoundaryVerificationStatus.pending.name) {
      throw StateError(
        'Only pending boundaries can be reviewed.',
      );
    }
  }

  void _requireSameLocation({
    required Map<String, dynamic> existing,
    required String locationId,
    required String locationType,
  }) {
    final existingLocationId =
        existing['locationId']?.toString() ?? '';

    final existingLocationType =
        existing['locationType']?.toString() ?? '';

    if (existingLocationId != locationId ||
        existingLocationType != locationType) {
      throw StateError(
        'An existing boundary cannot be reassigned '
        'to another location.',
      );
    }
  }

  // ============================================================
  // GET BOUNDARY
  // ============================================================

  Future<ServiceLocationBoundary?> getById(
    String boundaryId,
  ) async {
    _currentUid;

    final id = _required(boundaryId, 'Boundary ID');
    final snapshot = await _boundaries.doc(id).get();

    if (!snapshot.exists) {
      return null;
    }

    final data = snapshot.data();

    if (data == null) {
      return null;
    }

    return ServiceLocationBoundary.fromMap(
      snapshot.id,
      data,
    );
  }

  // ============================================================
  // WATCH BOUNDARIES FOR A LOCATION
  // ============================================================

  Stream<List<ServiceLocationBoundary>> watchForLocation(
    String locationId, {
    String? locationType,
  }) {
    final id = locationId.trim();

    if (id.isEmpty) {
      return Stream.value(
        <ServiceLocationBoundary>[],
      );
    }

    final normalizedType = locationType?.trim().toLowerCase();

    if (normalizedType != null &&
        !_isSupportedLocationType(normalizedType)) {
      return Stream.error(
        ArgumentError(
          'Location type must be city, area, or locality.',
        ),
      );
    }

    return _boundaries
        .where('locationId', isEqualTo: id)
        .snapshots()
        .map((snapshot) {
      final results = <ServiceLocationBoundary>[];

      for (final document in snapshot.docs) {
        final boundary = ServiceLocationBoundary.fromMap(
          document.id,
          document.data(),
        );

        if (normalizedType != null &&
            boundary.locationType.trim().toLowerCase() !=
                normalizedType) {
          continue;
        }

        results.add(boundary);
      }

      results.sort((a, b) {
        // Prefer verified boundaries when choosing a boundary
        // for display. A verified boundary remains read-only.
        final aVerified = a.isVerified ? 1 : 0;
        final bVerified = b.isVerified ? 1 : 0;

        final verifiedComparison =
            bVerified.compareTo(aVerified);

        if (verifiedComparison != 0) {
          return verifiedComparison;
        }

        final dateComparison =
            b.updatedAt.compareTo(a.updatedAt);

        if (dateComparison != 0) {
          return dateComparison;
        }

        return b.id.compareTo(a.id);
      });

      return results;
    });
  }

  // ============================================================
  // SAVE / UPDATE BOUNDARY
  // ============================================================

  /// Creates a boundary or updates an editable boundary.
  ///
  /// Compatibility note:
  /// The existing Firestore Rules require newly created records
  /// to have verificationStatus == "pending".
  ///
  /// Therefore, this method cannot create a separate persisted
  /// "draft" status without a corresponding Rules change.
  ///
  /// For existing rejected records, this method saves the edited
  /// geometry and returns the record to pending. The UI must
  /// reflect this actual status and must not tell the user that
  /// the record is still a draft.
  Future<String> saveDraft(
    ServiceLocationBoundary boundary,
  ) async {
    _currentUid;

    final locationId = _required(
      boundary.locationId,
      'Location ID',
    );

    final locationType = _required(
      boundary.locationType,
      'Location type',
    ).toLowerCase();

    _validateLocation(
      locationId: locationId,
      locationType: locationType,
    );

    if (boundary.isVerified) {
      throw StateError(
        'A verified boundary cannot be saved as a draft.',
      );
    }

    _throwIfInvalid(boundary);

    final suppliedId = boundary.id.trim();

    final document = suppliedId.isEmpty
        ? _boundaries.doc()
        : _boundaries.doc(suppliedId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);
      final existing = snapshot.data();

      if (snapshot.exists) {
        if (existing == null) {
          throw StateError(
            'Boundary data could not be loaded.',
          );
        }

        final existingStatus = _normalizeStatus(
          existing['verificationStatus'],
        );

        _requireEditableStatus(existingStatus);

        _requireSameLocation(
          existing: existing,
          locationId: locationId,
          locationType: locationType,
        );
      }

      final now = FieldValue.serverTimestamp();

      final data = <String, dynamic>{
        'locationId': locationId,
        'locationType': locationType,
        ..._serializePoints(boundary.points),
        'sourceType': boundary.sourceType.name,
        'sourceName': boundary.sourceName.trim(),
        'sourceReference': boundary.sourceReference.trim(),
        'verificationStatus':
            BoundaryVerificationStatus.pending.name,
        'verifiedBy': null,
        'verifiedAt': null,
        'verificationNotes': null,
        'updatedAt': now,
      };

      if (!snapshot.exists) {
        data['createdAt'] = now;
      }

      transaction.set(
        document,
        data,
        SetOptions(merge: true),
      );
    });

    return document.id;
  }

  // ============================================================
  // REQUEST VERIFICATION / RESUBMIT
  // ============================================================

  /// Submits an existing rejected boundary for review.
  ///
  /// For a boundary that is already pending, this method performs
  /// no write. This prevents unnecessary timestamp changes.
  ///
  /// The current Rules allow rejected -> pending only when the
  /// required fields are valid and verification notes are null.
  Future<void> requestVerification(
    String boundaryId,
  ) async {
    _currentUid;

    final id = _required(boundaryId, 'Boundary ID');
    final reference = _boundaries.doc(id);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);

      if (!snapshot.exists) {
        throw StateError('Boundary not found.');
      }

      final data = snapshot.data();

      if (data == null) {
        throw StateError(
          'Boundary data could not be loaded.',
        );
      }

      final status = _normalizeStatus(
        data['verificationStatus'],
      );

      if (status == BoundaryVerificationStatus.verified.name) {
        throw StateError(
          'This boundary is already verified.',
        );
      }

      if (status == BoundaryVerificationStatus.pending.name) {
        // Already submitted. Do not rewrite the document.
        return;
      }

      if (status != BoundaryVerificationStatus.rejected.name) {
        throw StateError(
          'Only rejected boundaries can be resubmitted.',
        );
      }

      final boundary = ServiceLocationBoundary.fromMap(
        snapshot.id,
        data,
      );

      _throwIfInvalid(boundary);

      transaction.update(reference, {
        'verificationStatus':
            BoundaryVerificationStatus.pending.name,
        'verifiedBy': null,
        'verifiedAt': null,
        'verificationNotes': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ============================================================
  // MARK VERIFIED
  // ============================================================

  Future<void> markVerified({
    required String boundaryId,
    String? reviewerId,
    required String verificationNotes,
  }) async {
    final uid = _currentUid;

    if (reviewerId != null &&
        reviewerId.trim().isNotEmpty &&
        reviewerId.trim() != uid) {
      throw StateError(
        'Reviewer ID must match the signed-in user.',
      );
    }

    final notes = _required(
      verificationNotes,
      'Verification notes',
    );

    final id = _required(boundaryId, 'Boundary ID');
    final reference = _boundaries.doc(id);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);

      if (!snapshot.exists) {
        throw StateError('Boundary not found.');
      }

      final data = snapshot.data();

      if (data == null) {
        throw StateError(
          'Boundary data could not be loaded.',
        );
      }

      final status = _normalizeStatus(
        data['verificationStatus'],
      );

      _requirePendingStatus(status);

      final boundary = ServiceLocationBoundary.fromMap(
        snapshot.id,
        data,
      );

      _throwIfInvalid(boundary);

      transaction.update(reference, {
        'verificationStatus':
            BoundaryVerificationStatus.verified.name,
        'verifiedBy': uid,
        'verifiedAt': FieldValue.serverTimestamp(),
        'verificationNotes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ============================================================
  // REJECT BOUNDARY
  // ============================================================

  Future<void> rejectBoundary({
    required String boundaryId,
    String? reviewerId,
    required String reason,
  }) async {
    final uid = _currentUid;

    if (reviewerId != null &&
        reviewerId.trim().isNotEmpty &&
        reviewerId.trim() != uid) {
      throw StateError(
        'Reviewer ID must match the signed-in user.',
      );
    }

    final rejectionReason = _required(
      reason,
      'Rejection reason',
    );

    final id = _required(boundaryId, 'Boundary ID');
    final reference = _boundaries.doc(id);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);

      if (!snapshot.exists) {
        throw StateError('Boundary not found.');
      }

      final data = snapshot.data();

      if (data == null) {
        throw StateError(
          'Boundary data could not be loaded.',
        );
      }

      final status = _normalizeStatus(
        data['verificationStatus'],
      );

      _requirePendingStatus(status);

      transaction.update(reference, {
        'verificationStatus':
            BoundaryVerificationStatus.rejected.name,
        'verifiedBy': uid,
        'verifiedAt': null,
        'verificationNotes': rejectionReason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ============================================================
  // DELETE PENDING / REJECTED BOUNDARY
  // ============================================================

  Future<void> deleteDraft(
    String boundaryId,
  ) async {
    _currentUid;

    final id = _required(boundaryId, 'Boundary ID');
    final reference = _boundaries.doc(id);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);

      if (!snapshot.exists) {
        return;
      }

      final data = snapshot.data();

      if (data == null) {
        throw StateError(
          'Boundary data could not be loaded.',
        );
      }

      final status = _normalizeStatus(
        data['verificationStatus'],
      );

      if (status == BoundaryVerificationStatus.verified.name) {
        throw StateError(
          'Verified boundaries cannot be deleted.',
        );
      }

      transaction.delete(reference);
    });
  }
}

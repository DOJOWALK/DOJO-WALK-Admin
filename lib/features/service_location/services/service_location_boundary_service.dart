import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/service_location_boundary.dart';

/// ===========================================================
/// DOJO WALK ADMIN
/// Service Location Boundary Service
///
/// Firestore collection:
/// service_location_boundaries
///
/// Boundary lifecycle:
/// Draft -> Pending -> Verified / Rejected
///
/// IMPORTANT:
/// - Verified boundaries cannot be edited or deleted.
/// - Only pending boundaries can be verified or rejected.
/// - Firestore Security Rules must enforce admin permissions.
/// ===========================================================

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

  String get _currentUid {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError(
        'Please sign in before managing service boundaries.',
      );
    }

    return user.uid;
  }

  /// =========================================================
  /// HELPERS
  /// =========================================================

  String _normalizeRequired(
    String value,
    String fieldName,
  ) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError('$fieldName is required.');
    }

    return normalized;
  }

  bool _isSupportedLocationType(String value) {
    return const {
      'city',
      'area',
      'locality',
    }.contains(value.trim().toLowerCase());
  }

  Map<String, dynamic> _serializePoints(
    List<GeoPoint> points,
  ) {
    // Store points consistently as Firestore GeoPoints.
    return {
      'points': points
          .map(
            (point) => GeoPoint(
              point.latitude,
              point.longitude,
            ),
          )
          .toList(),
    };
  }

  List<String> _validateBoundaryForReview(
    ServiceLocationBoundary boundary,
  ) {
    final errors = <String>[];

    errors.addAll(boundary.validate());

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

    return errors.toSet().toList();
  }

  void _throwValidationErrors(List<String> errors) {
    if (errors.isEmpty) return;

    throw ArgumentError(
      'Boundary validation failed:\n'
      '${errors.join('\n')}',
    );
  }

  /// =========================================================
  /// GET BOUNDARY
  /// =========================================================

  Future<ServiceLocationBoundary?> getById(
    String boundaryId,
  ) async {
    final id = _normalizeRequired(
      boundaryId,
      'Boundary ID',
    );

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

  /// =========================================================
  /// WATCH BOUNDARIES FOR A LOCATION
  /// =========================================================

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

    final normalizedType = locationType
        ?.trim()
        .toLowerCase();

    return _boundaries
        .where('locationId', isEqualTo: id)
        .snapshots()
        .map((snapshot) {
      final results = <ServiceLocationBoundary>[];

      for (final document in snapshot.docs) {
        final data = document.data();

        final boundary = ServiceLocationBoundary.fromMap(
          document.id,
          data,
        );

        if (normalizedType != null &&
            boundary.locationType.toLowerCase() !=
                normalizedType) {
          continue;
        }

        results.add(boundary);
      }

      results.sort((a, b) {
        return b.updatedAt.compareTo(a.updatedAt);
      });

      return results;
    });
  }

  /// =========================================================
  /// SAVE DRAFT
  ///
  /// A draft is saved with pending verification status.
  /// Existing verified documents cannot be overwritten.
  /// =========================================================

  Future<String> saveDraft(
    ServiceLocationBoundary boundary,
  ) async {
    _currentUid;

    final locationId = _normalizeRequired(
      boundary.locationId,
      'Location ID',
    );

    final locationType = _normalizeRequired(
      boundary.locationType,
      'Location type',
    ).toLowerCase();

    if (!_isSupportedLocationType(locationType)) {
      throw ArgumentError(
        'Location type must be city, area, or locality.',
      );
    }

    if (boundary.isVerified) {
      throw StateError(
        'A verified boundary cannot be saved as a draft.',
      );
    }

    final errors = _validateBoundaryForReview(
      boundary,
    );

    // Drafts can be incomplete in source metadata while being
    // edited. However, coordinates must still be structurally
    // valid before they are saved.
    final coordinateErrors = boundary
        .validate()
        .where(
          (error) =>
              error.toLowerCase().contains('point') ||
              error.toLowerCase().contains('coordinate') ||
              error.toLowerCase().contains('polygon'),
        )
        .toList();

    if (coordinateErrors.isNotEmpty) {
      _throwValidationErrors(coordinateErrors);
    }

    // Remove only metadata errors that can be completed before
    // verification. Structural coordinate errors remain fatal.
    final fatalErrors = errors.where((error) {
      final normalized = error.toLowerCase();

      return normalized.contains('latitude') ||
          normalized.contains('longitude') ||
          normalized.contains('coordinate') ||
          normalized.contains('polygon') ||
          normalized.contains('distinct') ||
          normalized.contains('location id') ||
          normalized.contains('location type');
    }).toList();

    if (fatalErrors.isNotEmpty) {
      _throwValidationErrors(fatalErrors);
    }

    final document = boundary.id.trim().isEmpty
        ? _boundaries.doc()
        : _boundaries.doc(boundary.id.trim());

    await _firestore.runTransaction((transaction) async {
      final existingSnapshot =
          await transaction.get(document);

      final existing = existingSnapshot.data();

      if (existingSnapshot.exists && existing != null) {
        final existingStatus =
            existing['verificationStatus']?.toString() ?? '';

        if (existingStatus == 'verified') {
          throw StateError(
            'Verified boundaries cannot be edited.',
          );
        }

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
        'verificationNotes': '',
        'updatedAt': now,
      };

      if (!existingSnapshot.exists) {
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

  /// =========================================================
  /// REQUEST VERIFICATION
  ///
  /// Moves an editable boundary into pending review.
  /// =========================================================

  Future<void> requestVerification(
    String boundaryId,
  ) async {
    _currentUid;

    final id = _normalizeRequired(
      boundaryId,
      'Boundary ID',
    );

    final reference = _boundaries.doc(id);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);

      if (!snapshot.exists) {
        throw StateError('Boundary not found.');
      }

      final data = snapshot.data()!;

      final currentStatus =
          data['verificationStatus']?.toString() ?? '';

      if (currentStatus == 'verified') {
        throw StateError(
          'This boundary is already verified.',
        );
      }

      final boundary = ServiceLocationBoundary.fromMap(
        snapshot.id,
        data,
      );

      final errors = _validateBoundaryForReview(boundary);

      _throwValidationErrors(errors);

      transaction.update(reference, {
        'verificationStatus':
            BoundaryVerificationStatus.pending.name,
        'verifiedBy': null,
        'verifiedAt': null,
        'verificationNotes': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// =========================================================
  /// MARK VERIFIED
  ///
  /// IMPORTANT:
  /// The application should call this only after an authorized
  /// reviewer has checked the polygon and its source.
  ///
  /// Firestore Rules must independently restrict this operation
  /// to authorized admins.
  /// =========================================================

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

    final notes = _normalizeRequired(
      verificationNotes,
      'Verification notes',
    );

    final id = _normalizeRequired(
      boundaryId,
      'Boundary ID',
    );

    final reference = _boundaries.doc(id);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);

      if (!snapshot.exists) {
        throw StateError('Boundary not found.');
      }

      final data = snapshot.data()!;

      final currentStatus =
          data['verificationStatus']?.toString() ?? '';

      if (currentStatus !=
          BoundaryVerificationStatus.pending.name) {
        throw StateError(
          'Only pending boundaries can be verified.',
        );
      }

      final boundary = ServiceLocationBoundary.fromMap(
        snapshot.id,
        data,
      );

      final errors = _validateBoundaryForReview(boundary);

      _throwValidationErrors(errors);

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

  /// =========================================================
  /// REJECT BOUNDARY
  ///
  /// Only pending boundaries can be rejected.
  /// =========================================================

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

    final rejectionReason = _normalizeRequired(
      reason,
      'Rejection reason',
    );

    final id = _normalizeRequired(
      boundaryId,
      'Boundary ID',
    );

    final reference = _boundaries.doc(id);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);

      if (!snapshot.exists) {
        throw StateError('Boundary not found.');
      }

      final data = snapshot.data()!;

      final currentStatus =
          data['verificationStatus']?.toString() ?? '';

      if (currentStatus !=
          BoundaryVerificationStatus.pending.name) {
        throw StateError(
          'Only pending boundaries can be rejected.',
        );
      }

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

  /// =========================================================
  /// DELETE DRAFT / REJECTED BOUNDARY
  ///
  /// Verified boundaries cannot be deleted through this method.
  /// =========================================================

  Future<void> deleteDraft(
    String boundaryId,
  ) async {
    _currentUid;

    final id = _normalizeRequired(
      boundaryId,
      'Boundary ID',
    );

    final reference = _boundaries.doc(id);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);

      if (!snapshot.exists) {
        return;
      }

      final data = snapshot.data()!;

      final status =
          data['verificationStatus']?.toString() ?? '';

      if (status ==
          BoundaryVerificationStatus.verified.name) {
        throw StateError(
          'Verified boundaries cannot be deleted.',
        );
      }

      transaction.delete(reference);
    });
  }
}

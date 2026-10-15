/// DOJO WALK Admin
///
/// Firestore persistence for service-location boundaries.
///
/// Responsibilities:
/// - Save boundary drafts.
/// - Load a boundary by ID.
/// - Stream boundaries for a location.
/// - Update verification status.
/// - Prevent activation of unverified boundaries.
///
/// Important:
/// This service does not determine whether a boundary matches
/// an official government map. That requires a separate review.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/service_location_boundary.dart';

class ServiceLocationBoundaryService {
  ServiceLocationBoundaryService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collectionName =
      'service_location_boundaries';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  /// Save a new boundary or update an existing boundary draft.
  ///
  /// New boundaries must start as pending verification.
  /// Saving a draft must never automatically verify it.
  Future<String> saveDraft(
    ServiceLocationBoundary boundary,
  ) async {
    final errors = boundary.validate();

    if (errors.isNotEmpty) {
      throw ArgumentError(
        'Boundary validation failed: ${errors.join(' ')}',
      );
    }

    if (boundary.isVerified) {
      throw StateError(
        'A verified boundary cannot be saved as a draft. '
        'Save a pending draft and use the verification workflow.',
      );
    }

    final data = boundary.toMap()
      ..['verificationStatus'] =
          BoundaryVerificationStatus.pending.name
      ..['verifiedBy'] = null
      ..['verifiedAt'] = null;

    final now = Timestamp.now();
    data['updatedAt'] = now;

    if (boundary.id.trim().isEmpty) {
      data['createdAt'] = now;

      final reference = await _collection.add(data);
      return reference.id;
    }

    final reference = _collection.doc(boundary.id);

    final existing = await reference.get();

    if (existing.exists) {
      // Preserve original creation time when editing.
      data.remove('createdAt');

      await reference.update(data);
    } else {
      data['createdAt'] = now;
      await reference.set(data);
    }

    return reference.id;
  }

  /// Fetch a single boundary.
  Future<ServiceLocationBoundary?> getById(
    String boundaryId,
  ) async {
    final snapshot = await _collection.doc(boundaryId).get();

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

  /// Watch all boundaries associated with a location.
  Stream<List<ServiceLocationBoundary>> watchForLocation(
    String locationId,
  ) {
    return _collection
        .where('locationId', isEqualTo: locationId)
        .snapshots()
        .map((snapshot) {
      final boundaries = snapshot.docs.map((document) {
        return ServiceLocationBoundary.fromMap(
          document.id,
          document.data(),
        );
      }).toList();

      boundaries.sort(
        (a, b) => b.updatedAt.compareTo(a.updatedAt),
      );

      return List.unmodifiable(boundaries);
    });
  }

  /// Request verification by setting the status to pending.
  ///
  /// This does not verify the boundary itself.
  Future<void> requestVerification(
    String boundaryId,
  ) async {
    final reference = _collection.doc(boundaryId);
    final snapshot = await reference.get();

    if (!snapshot.exists) {
      throw StateError('Boundary not found.');
    }

    final data = snapshot.data();

    if (data == null) {
      throw StateError('Boundary data is missing.');
    }

    final boundary = ServiceLocationBoundary.fromMap(
      snapshot.id,
      data,
    );

    final errors = boundary.validate();

    if (errors.isNotEmpty) {
      throw ArgumentError(
        'Boundary cannot be submitted: ${errors.join(' ')}',
      );
    }

    await reference.update({
      'verificationStatus':
          BoundaryVerificationStatus.pending.name,
      'verifiedBy': null,
      'verifiedAt': null,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Mark a boundary as verified after an authorized reviewer
  /// has checked the real-world geometry and its source.
  ///
  /// IMPORTANT:
  /// Enforce reviewer permissions in Firestore Security Rules
  /// or a trusted backend. Client-side checks alone are not enough.
  Future<void> markVerified({
    required String boundaryId,
    required String reviewerId,
    required String verificationNotes,
  }) async {
    if (reviewerId.trim().isEmpty) {
      throw ArgumentError('Reviewer ID is required.');
    }

    if (verificationNotes.trim().isEmpty) {
      throw ArgumentError(
        'Verification notes are required.',
      );
    }

    final reference = _collection.doc(boundaryId);
    final snapshot = await reference.get();

    if (!snapshot.exists) {
      throw StateError('Boundary not found.');
    }

    final data = snapshot.data();

    if (data == null) {
      throw StateError('Boundary data is missing.');
    }

    final boundary = ServiceLocationBoundary.fromMap(
      snapshot.id,
      data,
    );

    // Check the geometry and source fields before allowing
    // a reviewer to mark the record verified.
    final errors = boundary.validate();

    if (errors.isNotEmpty) {
      throw ArgumentError(
        'Boundary cannot be verified: ${errors.join(' ')}',
      );
    }

    await reference.update({
      'verificationStatus':
          BoundaryVerificationStatus.verified.name,
      'verifiedBy': reviewerId,
      'verifiedAt': Timestamp.now(),
      'verificationNotes': verificationNotes.trim(),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Reject a boundary and retain the reason for audit.
  Future<void> rejectBoundary({
    required String boundaryId,
    required String reviewerId,
    required String reason,
  }) async {
    if (reviewerId.trim().isEmpty) {
      throw ArgumentError('Reviewer ID is required.');
    }

    if (reason.trim().isEmpty) {
      throw ArgumentError('Rejection reason is required.');
    }

    final reference = _collection.doc(boundaryId);
    final snapshot = await reference.get();

    if (!snapshot.exists) {
      throw StateError('Boundary not found.');
    }

    await reference.update({
      'verificationStatus':
          BoundaryVerificationStatus.rejected.name,
      'verifiedBy': reviewerId,
      'verifiedAt': null,
      'verificationNotes': reason.trim(),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Delete a draft only.
  ///
  /// Verified boundaries must not be deleted through this method.
  Future<void> deleteDraft(String boundaryId) async {
    final reference = _collection.doc(boundaryId);
    final snapshot = await reference.get();

    if (!snapshot.exists) {
      return;
    }

    final data = snapshot.data();

    if (data == null) {
      throw StateError('Boundary data is missing.');
    }

    final boundary = ServiceLocationBoundary.fromMap(
      snapshot.id,
      data,
    );

    if (boundary.isVerified) {
      throw StateError(
        'Verified boundaries cannot be deleted as drafts.',
      );
    }

    await reference.delete();
  }
}

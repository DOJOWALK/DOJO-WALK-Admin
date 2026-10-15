/// DOJO WALK Admin
///
/// Firestore persistence for service-location boundaries.
///
/// Verified boundaries must not be overwritten by ordinary draft saves.
/// Reviewer authorization must also be enforced by Firestore Security Rules
/// or a trusted backend.

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

  /// Saves a new draft or updates an existing unverified draft.
  ///
  /// A verified boundary cannot be overwritten through this method.
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
        'A verified boundary cannot be saved as a draft.',
      );
    }

    final now = Timestamp.now();

    final data = boundary.toMap()
      ..['verificationStatus'] =
          BoundaryVerificationStatus.pending.name
      ..['verifiedBy'] = null
      ..['verifiedAt'] = null
      ..['updatedAt'] = now;

    if (boundary.id.trim().isEmpty) {
      data['createdAt'] = now;

      final reference = await _collection.add(data);
      return reference.id;
    }

    final reference = _collection.doc(boundary.id);
    final existing = await reference.get();

    if (existing.exists) {
      final existingData = existing.data();

      if (existingData == null) {
        throw StateError('Existing boundary data is missing.');
      }

      final existingBoundary = ServiceLocationBoundary.fromMap(
        existing.id,
        existingData,
      );

      if (existingBoundary.isVerified) {
        throw StateError(
          'Verified boundaries cannot be overwritten as drafts.',
        );
      }

      if (existingBoundary.locationId != boundary.locationId ||
          existingBoundary.locationType != boundary.locationType) {
        throw StateError(
          'A boundary cannot be moved to another location.',
        );
      }

      data.remove('createdAt');
      await reference.update(data);
    } else {
      data['createdAt'] = now;
      await reference.set(data);
    }

    return reference.id;
  }

  Future<ServiceLocationBoundary?> getById(
    String boundaryId,
  ) async {
    final snapshot = await _collection.doc(boundaryId).get();

    if (!snapshot.exists) return null;

    final data = snapshot.data();
    if (data == null) return null;

    return ServiceLocationBoundary.fromMap(snapshot.id, data);
  }

  /// Watches boundaries for a location.
  ///
  /// Pass locationType to avoid mixing different location categories
  /// that happen to share an ID.
  Stream<List<ServiceLocationBoundary>> watchForLocation(
    String locationId, {
    String? locationType,
  }) {
    Query<Map<String, dynamic>> query = _collection.where(
      'locationId',
      isEqualTo: locationId,
    );

    if (locationType != null) {
      query = query.where(
        'locationType',
        isEqualTo: locationType,
      );
    }

    return query.snapshots().map((snapshot) {
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

    if (boundary.isVerified) {
      throw StateError('Boundary is already verified.');
    }

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

  Future<void> markVerified({
    required String boundaryId,
    required String reviewerId,
    required String verificationNotes,
  }) async {
    if (reviewerId.trim().isEmpty) {
      throw ArgumentError('Reviewer ID is required.');
    }

    if (verificationNotes.trim().isEmpty) {
      throw ArgumentError('Verification notes are required.');
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

    final errors = boundary.validate();

    if (errors.isNotEmpty) {
      throw ArgumentError(
        'Boundary cannot be verified: ${errors.join(' ')}',
      );
    }

    final now = Timestamp.now();

    await reference.update({
      'verificationStatus':
          BoundaryVerificationStatus.verified.name,
      'verifiedBy': reviewerId,
      'verifiedAt': now,
      'verificationNotes': verificationNotes.trim(),
      'updatedAt': now,
    });
  }

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

  Future<void> deleteDraft(String boundaryId) async {
    final reference = _collection.doc(boundaryId);
    final snapshot = await reference.get();

    if (!snapshot.exists) return;

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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/service_location_boundary.dart';

/// ===========================================================
/// DOJO WALK ADMIN
/// Service Location Boundary Service
///
/// Collection:
/// service_location_boundaries
///
/// Security:
/// - Active super_admin access is enforced by Firestore Rules.
/// - The authenticated admin's UID is used as reviewer ID.
/// - Verified boundaries cannot be edited, rejected or deleted.
/// - Existing boundary location/type cannot be changed.
/// ===========================================================

class ServiceLocationBoundaryService {
  ServiceLocationBoundaryService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String collectionName =
      'service_location_boundaries';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  // =========================================================
  // AUTHENTICATION
  // =========================================================

  String get _currentUid {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError(
        'आपको पहले Admin के रूप में लॉगिन करना होगा।',
      );
    }

    return user.uid;
  }

  // =========================================================
  // DOCUMENT HELPERS
  // =========================================================

  Future<ServiceLocationBoundary?> getById(
    String boundaryId,
  ) async {
    final id = boundaryId.trim();

    if (id.isEmpty) {
      return null;
    }

    final snapshot = await _collection.doc(id).get();

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

    return _collection
        .where('locationId', isEqualTo: id)
        .snapshots()
        .map((snapshot) {
      final boundaries = snapshot.docs
          .map(
            (document) => ServiceLocationBoundary.fromMap(
              document.id,
              document.data(),
            ),
          )
          .where((boundary) {
        if (locationType == null ||
            locationType.trim().isEmpty) {
          return true;
        }

        return boundary.locationType == locationType.trim();
      }).toList();

      boundaries.sort((a, b) {
        final aTime = a.updatedAt;
        final bTime = b.updatedAt;

        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;

        return bTime.compareTo(aTime);
      });

      return boundaries;
    });
  }

  // =========================================================
  // SAVE DRAFT
  //
  // New boundaries must begin as pending.
  // Verified boundaries cannot be edited.
  // =========================================================

  Future<String> saveDraft(
    ServiceLocationBoundary boundary,
  ) async {
    _currentUid;

    final errors = boundary.validate();

    if (errors.isNotEmpty) {
      throw ArgumentError(
        'Boundary में गलत डेटा है: ${errors.join(', ')}',
      );
    }

    if (boundary.isVerified) {
      throw StateError(
        'Verified Boundary को Draft के रूप में सेव नहीं किया जा सकता।',
      );
    }

    final locationId = boundary.locationId.trim();
    final locationType = boundary.locationType.trim();

    if (locationId.isEmpty || locationType.isEmpty) {
      throw ArgumentError(
        'Location ID और Location Type जरूरी हैं।',
      );
    }

    final documentRef = boundary.id.trim().isEmpty
        ? _collection.doc()
        : _collection.doc(boundary.id.trim());

    await _firestore.runTransaction((transaction) async {
      final existingSnapshot =
          await transaction.get(documentRef);

      final now = FieldValue.serverTimestamp();

      if (existingSnapshot.exists) {
        final existingData = existingSnapshot.data();

        if (existingData == null) {
          throw StateError(
            'मौजूदा Boundary का डेटा उपलब्ध नहीं है।',
          );
        }

        final existingStatus =
            existingData['verificationStatus'];

        if (existingStatus == 'verified') {
          throw StateError(
            'Verified Boundary को बदला नहीं जा सकता।',
          );
        }

        if (existingData['locationId'] != locationId ||
            existingData['locationType'] != locationType) {
          throw StateError(
            'मौजूदा Boundary का Location ID या Type नहीं बदला जा सकता।',
          );
        }

        transaction.update(
          documentRef,
          {
            'points': boundary.points,
            'sourceType': boundary.sourceType.name,
            'sourceName': boundary.sourceName.trim(),
            'sourceReference':
                boundary.sourceReference.trim(),
            'verificationStatus': 'pending',
            'verifiedBy': null,
            'verifiedAt': null,
            'verificationNotes': '',
            'updatedAt': now,
          },
        );
      } else {
        transaction.set(
          documentRef,
          {
            'locationId': locationId,
            'locationType': locationType,
            'points': boundary.points,
            'sourceType': boundary.sourceType.name,
            'sourceName': boundary.sourceName.trim(),
            'sourceReference':
                boundary.sourceReference.trim(),
            'verificationStatus': 'pending',
            'verifiedBy': null,
            'verifiedAt': null,
            'verificationNotes': '',
            'createdAt': now,
            'updatedAt': now,
          },
        );
      }
    });

    return documentRef.id;
  }

  // =========================================================
  // REQUEST VERIFICATION
  //
  // Only non-verified boundaries can be submitted.
  // =========================================================

  Future<void> requestVerification(
    String boundaryId,
  ) async {
    _currentUid;

    final id = boundaryId.trim();

    if (id.isEmpty) {
      throw ArgumentError(
        'Boundary ID जरूरी है।',
      );
    }

    final documentRef = _collection.doc(id);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(documentRef);

      if (!snapshot.exists) {
        throw StateError(
          'Boundary नहीं मिली।',
        );
      }

      final data = snapshot.data()!;

      if (data['verificationStatus'] == 'verified') {
        throw StateError(
          'यह Boundary पहले से Verified है।',
        );
      }

      final boundary =
          ServiceLocationBoundary.fromMap(id, data);

      final errors = boundary.validate();

      if (errors.isNotEmpty) {
        throw StateError(
          'Verification से पहले Boundary ठीक करें: '
          '${errors.join(', ')}',
        );
      }

      transaction.update(
        documentRef,
        {
          'verificationStatus': 'pending',
          'verifiedBy': null,
          'verifiedAt': null,
          'verificationNotes': '',
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    });
  }

  // =========================================================
  // MARK VERIFIED
  //
  // Reviewer ID is always the authenticated user's UID.
  // Firestore Rules must also check:
  // verifiedBy == request.auth.uid
  // =========================================================

  Future<void> markVerified({
    required String boundaryId,
    String? reviewerId,
    required String verificationNotes,
  }) async {
    final uid = _currentUid;
    final id = boundaryId.trim();
    final notes = verificationNotes.trim();

    if (id.isEmpty) {
      throw ArgumentError(
        'Boundary ID जरूरी है।',
      );
    }

    if (notes.isEmpty) {
      throw ArgumentError(
        'Verification Notes देना जरूरी है।',
      );
    }

    // Reject a caller-supplied identity that differs
    // from the authenticated Firebase user.
    if (reviewerId != null &&
        reviewerId.trim() != uid) {
      throw StateError(
        'Reviewer ID लॉगिन किए हुए Admin से मेल नहीं खाती।',
      );
    }

    final documentRef = _collection.doc(id);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(documentRef);

      if (!snapshot.exists) {
        throw StateError(
          'Boundary नहीं मिली।',
        );
      }

      final data = snapshot.data()!;

      if (data['verificationStatus'] == 'verified') {
        throw StateError(
          'यह Boundary पहले से Verified है।',
        );
      }

      final boundary =
          ServiceLocationBoundary.fromMap(id, data);

      final errors = boundary.validate();

      if (errors.isNotEmpty) {
        throw StateError(
          'Boundary Verify नहीं की जा सकती: '
          '${errors.join(', ')}',
        );
      }

      transaction.update(
        documentRef,
        {
          'verificationStatus': 'verified',
          'verifiedBy': uid,
          'verifiedAt': FieldValue.serverTimestamp(),
          'verificationNotes': notes,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    });
  }

  // =========================================================
  // REJECT BOUNDARY
  //
  // A verified boundary cannot be rejected.
  // =========================================================

  Future<void> rejectBoundary({
    required String boundaryId,
    String? reviewerId,
    required String reason,
  }) async {
    final uid = _currentUid;
    final id = boundaryId.trim();
    final rejectionReason = reason.trim();

    if (id.isEmpty) {
      throw ArgumentError(
        'Boundary ID जरूरी है।',
      );
    }

    if (rejectionReason.isEmpty) {
      throw ArgumentError(
        'Reject करने का कारण देना जरूरी है।',
      );
    }

    if (reviewerId != null &&
        reviewerId.trim() != uid) {
      throw StateError(
        'Reviewer ID लॉगिन किए हुए Admin से मेल नहीं खाती।',
      );
    }

    final documentRef = _collection.doc(id);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(documentRef);

      if (!snapshot.exists) {
        throw StateError(
          'Boundary नहीं मिली।',
        );
      }

      final data = snapshot.data()!;

      if (data['verificationStatus'] == 'verified') {
        throw StateError(
          'Verified Boundary को Reject नहीं किया जा सकता।',
        );
      }

      transaction.update(
        documentRef,
        {
          'verificationStatus': 'rejected',
          'verifiedBy': uid,
          'verifiedAt': null,
          'verificationNotes': rejectionReason,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    });
  }

  // =========================================================
  // DELETE DRAFT
  //
  // Only non-verified boundaries may be deleted.
  // =========================================================

  Future<void> deleteDraft(
    String boundaryId,
  ) async {
    _currentUid;

    final id = boundaryId.trim();

    if (id.isEmpty) {
      throw ArgumentError(
        'Boundary ID जरूरी है।',
      );
    }

    final documentRef = _collection.doc(id);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(documentRef);

      if (!snapshot.exists) {
        return;
      }

      final data = snapshot.data()!;

      if (data['verificationStatus'] == 'verified') {
        throw StateError(
          'Verified Boundary को डिलीट नहीं किया जा सकता।',
        );
      }

      transaction.delete(documentRef);
    });
  }
}

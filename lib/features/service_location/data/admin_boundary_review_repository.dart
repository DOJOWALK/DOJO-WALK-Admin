import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Fresh boundary-review data adapter. Review decisions are always made by
/// the trusted callable; this client only reads pending records.
class AdminBoundaryReviewRepository {
  AdminBoundaryReviewRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1');

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Stream<List<AdminBoundaryReviewItem>> watchPending() {
    return _firestore
        .collection('service_location_boundaries')
        .where('verificationStatus', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) => AdminBoundaryReviewItem.fromMap(doc.id, doc.data()))
          .where((item) =>
              item.locationId.isNotEmpty &&
              const {'city', 'area'}.contains(item.locationType))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return items;
    });
  }

  Future<void> review({
    required String boundaryId,
    required bool approve,
    required String notes,
  }) async {
    final cleanNotes = notes.trim();
    if (cleanNotes.isEmpty || cleanNotes.length > 2000) {
      throw ArgumentError('Review notes must contain 1 to 2000 characters.');
    }
    await _functions.httpsCallable('reviewServiceLocationBoundary').call({
      'boundaryId': boundaryId,
      'decision': approve ? 'verified' : 'rejected',
      'notes': cleanNotes,
    });
  }
}

class AdminBoundaryReviewItem {
  const AdminBoundaryReviewItem({
    required this.id,
    required this.locationId,
    required this.locationType,
    required this.sourceType,
    required this.sourceName,
    required this.sourceReference,
    required this.points,
    required this.updatedAt,
  });

  final String id;
  final String locationId;
  final String locationType;
  final String sourceType;
  final String sourceName;
  final String sourceReference;
  final List<String> points;
  final DateTime updatedAt;

  factory AdminBoundaryReviewItem.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    final rawPoints = data['points'];
    final points = <String>[];
    if (rawPoints is Iterable) {
      for (final point in rawPoints) {
        if (point is GeoPoint) {
          points.add(
            '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
          );
        } else if (point is Map) {
          final lat = point['latitude'];
          final lng = point['longitude'];
          if (lat is num && lng is num) {
            points.add(
              '${lat.toDouble().toStringAsFixed(6)}, ${lng.toDouble().toStringAsFixed(6)}',
            );
          }
        }
      }
    }
    final timestamp = data['updatedAt'];
    return AdminBoundaryReviewItem(
      id: id,
      locationId: (data['locationId'] ?? '').toString(),
      locationType: (data['locationType'] ?? '').toString().toLowerCase(),
      sourceType: (data['sourceType'] ?? 'Unknown').toString(),
      sourceName: (data['sourceName'] ?? '').toString(),
      sourceReference: (data['sourceReference'] ?? '').toString(),
      points: List.unmodifiable(points),
      updatedAt: timestamp is Timestamp ? timestamp.toDate() : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

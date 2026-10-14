import 'package:cloud_firestore/cloud_firestore.dart';

/// Shared helper functions for DOJO WALK Admin Walker Management.
class WalkerAdminHelpers {
  WalkerAdminHelpers._();

  // ----------------------------------------------------------
  // STATUS
  // ----------------------------------------------------------

  /// Safely normalizes a status value.
  static String normalizeStatus(dynamic value) {
    if (value is! String || value.trim().isEmpty) {
      return 'pending';
    }

    return value.trim().toLowerCase().replaceAll(' ', '_');
  }

  /// Returns a readable status label.
  static String displayStatus(dynamic value) {
    final status = normalizeStatus(value);

    switch (status) {
      case 'under_review':
        return 'Under Review';
      case 'correction_required':
        return 'Correction Required';
      case 'active_walk':
      case 'walk_started':
        return 'Running';
      case 'verified':
        return 'Verified';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'suspended':
        return 'Suspended';
      case 'inactive':
        return 'Inactive';
      case 'left':
        return 'Left';
      case 'pending':
        return 'Pending';
      case 'finding_walker':
        return 'Finding Walker';
      case 'walker_assigned':
        return 'Walker Assigned';
      case 'walker_arriving':
        return 'Walker Arriving';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status
            .split('_')
            .where((word) => word.isNotEmpty)
            .map(_capitalize)
            .join(' ');
    }
  }

  /// Checks whether the walker has a verified status.
  static bool isVerified(Map<String, dynamic> data) {
    return normalizeStatus(data['verificationStatus']) == 'verified';
  }

  /// Checks whether the walker is approved.
  static bool isApproved(Map<String, dynamic> data) {
    return data['isApproved'] == true;
  }

  /// Checks whether the walker is active.
  static bool isActive(Map<String, dynamic> data) {
    return data['isActive'] == true;
  }

  /// Checks whether the walker can be treated as available.
  ///
  /// This does not check current bookings or location.
  static bool isEligibleForAvailability(
    Map<String, dynamic> data,
  ) {
    final status = normalizeStatus(data['status']);

    return isVerified(data) &&
        isApproved(data) &&
        isActive(data) &&
        status == 'approved';
  }

  /// Identifies an application awaiting admin review.
  static bool isApplicationUnderReview(
    Map<String, dynamic> data,
  ) {
    final status = normalizeStatus(data['status']);
    final verificationStatus =
        normalizeStatus(data['verificationStatus']);

    if (status == 'rejected' ||
        status == 'suspended' ||
        status == 'inactive' ||
        status == 'left' ||
        status == 'approved') {
      return false;
    }

    if (verificationStatus == 'verified' ||
        verificationStatus == 'rejected') {
      return false;
    }

    return data['applicationSubmitted'] == true ||
        status == 'under_review' ||
        status == 'correction_required';
  }

  // ----------------------------------------------------------
  // STRING AND PROFILE DATA
  // ----------------------------------------------------------

  /// Returns the first non-empty string from the supplied keys.
  static String? firstString(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }

  /// Returns a display name, with a safe fallback.
  static String walkerName(Map<String, dynamic> data) {
    return firstString(data, [
          'name',
          'fullName',
          'displayName',
        ]) ??
        'Walker';
  }

  /// Returns a phone number from supported field names.
  static String? phoneNumber(Map<String, dynamic> data) {
    return firstString(data, [
      'phoneNumber',
      'phone',
      'mobile',
    ]);
  }

  /// Returns a profile photo URL.
  static String? photoUrl(Map<String, dynamic> data) {
    return firstString(data, [
      'photoUrl',
      'profilePhoto',
      'profileImage',
      'profileImageUrl',
    ]);
  }

  /// Returns an email address.
  static String? email(Map<String, dynamic> data) {
    return firstString(data, ['email']);
  }

  // ----------------------------------------------------------
  // LOCATION
  // ----------------------------------------------------------

  /// Builds a readable location from available fields.
  static String locationLabel(Map<String, dynamic> data) {
    final parts = <String>[];

    for (final key in [
      'area',
      'city',
      'state',
    ]) {
      final value = data[key];

      if (value is String &&
          value.trim().isNotEmpty &&
          !parts.any(
            (part) => part.toLowerCase() == value.trim().toLowerCase(),
          )) {
        parts.add(value.trim());
      }
    }

    return parts.isEmpty ? 'Location not provided' : parts.join(', ');
  }

  // ----------------------------------------------------------
  // DATE AND TIME
  // ----------------------------------------------------------

  /// Converts supported Firestore date values to DateTime.
  static DateTime? toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim());
    }

    return null;
  }

  /// Formats a date as DD/MM/YYYY.
  static String formatDate(dynamic value) {
    final date = toDateTime(value);

    if (date == null) {
      return 'Not available';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  // ----------------------------------------------------------
  // DOCUMENTS
  // ----------------------------------------------------------

  /// Extracts a URL or Storage path from a document field.
  ///
  /// Supported formats:
  /// - A direct URL string.
  /// - A map containing downloadUrl or url.
  /// - A map containing storagePath or path.
  static String? documentReference(dynamic document) {
    if (document is String && document.trim().isNotEmpty) {
      return document.trim();
    }

    if (document is Map) {
      final url = document['downloadUrl'] ?? document['url'];

      if (url is String && url.trim().isNotEmpty) {
        return url.trim();
      }

      final path = document['storagePath'] ?? document['path'];

      if (path is String && path.trim().isNotEmpty) {
        return path.trim();
      }
    }

    return null;
  }

  /// Checks whether a document reference is an HTTP(S) URL.
  static bool isHttpUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return false;
    }

    final uri = Uri.tryParse(value.trim());

    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  // ----------------------------------------------------------
  // INTERNAL
  // ----------------------------------------------------------

  static String _capitalize(String value) {
    if (value.isEmpty) return value;

    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

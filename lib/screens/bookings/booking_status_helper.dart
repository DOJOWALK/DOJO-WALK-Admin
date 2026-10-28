/// Normalizes Firestore booking status values for the Admin UI.
String displayBookingStatus(dynamic rawValue) {
  final raw = rawValue?.toString().trim() ?? '';
  if (raw.isEmpty) return 'Unknown';

  final normalized = raw
      .toLowerCase()
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  switch (normalized) {
    case 'pending':
      return 'Pending';
    case 'walker assigned':
    case 'assigned':
      return 'Walker Assigned';
    case 'walker accepted':
    case 'accepted':
      return 'Walker Accepted';
    case 'in progress':
    case 'active walk':
    case 'walking':
    case 'walk started':
      return 'Walk In Progress';
    case 'completed':
    case 'complete':
      return 'Completed';
    case 'cancelled':
    case 'canceled':
      return 'Cancelled';
    default:
      // Preserve unknown statuses for investigation instead of silently
      // mapping them to an unrelated lifecycle state.
      return raw;
  }
}

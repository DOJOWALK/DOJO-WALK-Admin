import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/screens/bookings/booking_status_helper.dart';

void main() {
  group('displayBookingStatus', () {
    test('normalizes underscore and hyphen lifecycle values', () {
      expect(displayBookingStatus('walker_assigned'), 'Walker Assigned');
      expect(displayBookingStatus('walker-accepted'), 'Walker Accepted');
      expect(displayBookingStatus('in_progress'), 'Walk In Progress');
      expect(displayBookingStatus('walk_started'), 'Walk In Progress');
      expect(displayBookingStatus('active-walk'), 'Walk In Progress');
      expect(displayBookingStatus('canceled'), 'Cancelled');
    });

    test('preserves unknown status values for investigation', () {
      expect(displayBookingStatus('needs_manual_review'), 'needs_manual_review');
      expect(displayBookingStatus(null), 'Unknown');
      expect(displayBookingStatus('  '), 'Unknown');
    });
  });
}

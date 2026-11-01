import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/screens/live/live_route_state_helper.dart';

void main() {
  group('liveRouteEmptyMessage', () {
    test('explains when no GPS points are available', () {
      expect(
        liveRouteEmptyMessage(0),
        'Route data not available yet. No GPS points have been received.',
      );
    });

    test('explains when only one GPS point is available', () {
      expect(
        liveRouteEmptyMessage(1),
        'Not enough GPS points to draw a route yet.',
      );
    });

    test('returns no empty state when a route can be drawn', () {
      expect(liveRouteEmptyMessage(2), isNull);
      expect(liveRouteEmptyMessage(300), isNull);
    });
  });
}

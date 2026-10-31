import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_walk_admin/screens/live/live_operations_screen.dart';

void main() {
  group('liveWalkerPresenceLabel', () {
    test('does not imply that online presence is an active walk', () {
      expect(
        liveWalkerPresenceLabel(3),
        '3 walkers online · active walk not verified',
      );
    });

    test('handles an empty online presence result', () {
      expect(
        liveWalkerPresenceLabel(0),
        '0 walkers online · active walk not verified',
      );
    });
    test('applies a route only to the currently selected walker', () {
      expect(
        shouldApplyLiveRoute(
          selectedWalkerId: 'walker-a',
          requestedWalkerId: 'walker-a',
        ),
        isTrue,
      );
      expect(
        shouldApplyLiveRoute(
          selectedWalkerId: 'walker-b',
          requestedWalkerId: 'walker-a',
        ),
        isFalse,
      );
      expect(
        shouldApplyLiveRoute(
          selectedWalkerId: null,
          requestedWalkerId: 'walker-a',
        ),
        isFalse,
      );
    });
  });
}

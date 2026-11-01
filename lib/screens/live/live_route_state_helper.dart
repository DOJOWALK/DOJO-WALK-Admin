/// Returns a clear empty-state message when a route cannot be drawn.
/// A route needs at least two GPS points to form a line.
String? liveRouteEmptyMessage(int pointCount) {
  if (pointCount <= 0) {
    return 'Route data not available yet. No GPS points have been received.';
  }
  if (pointCount == 1) {
    return 'Not enough GPS points to draw a route yet.';
  }
  return null;
}

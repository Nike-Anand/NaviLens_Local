import 'dart:ui';

/// Maps coordinates from the raw camera image space into the box that the
/// [CameraPreview] fills on screen.
///
/// ML Kit returns landmarks/bounding boxes in the coordinate space of the raw
/// (pre-rotation) camera frame. On a portrait phone the sensor frame is
/// landscape, so we rotate points 90° to align with the portrait preview.
class CoordinateMapper {
  const CoordinateMapper._();

  /// Maps a single point from the source camera image space to the on-screen
  /// preview box of size [box].
  static Offset mapPoint(Offset point, Size src, Size box) {
    final srcIsLandscape = src.width > src.height;
    if (srcIsLandscape) {
      // Rotate 90°: source (W,H) -> display (H,W). Source height maps to box width.
      final scale = box.width / src.height;
      return Offset((src.height - point.dy) * scale, point.dx * scale);
    } else {
      final scale = box.width / src.width;
      return Offset(point.dx * scale, point.dy * scale);
    }
  }

  /// Maps a rectangle (e.g. an object detection bounding box) to the on-screen
  /// preview box of size [box].
  static Rect mapRect(Rect rect, Size src, Size box) {
    final tl = mapPoint(rect.topLeft, src, box);
    final br = mapPoint(rect.bottomRight, src, box);
    return Rect.fromPoints(tl, br);
  }
}
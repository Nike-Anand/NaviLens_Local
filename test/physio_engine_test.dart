import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:navilens_local/ai/physio_engine.dart';

// ────────────────────────────────────────────────────────────
// Helpers to build minimal Pose / PoseLandmark objects
// ────────────────────────────────────────────────────────────

/// Creates a mock [Pose] with only the three landmarks needed for squat
/// analysis (leftHip, leftKnee, leftAnkle), at positions that produce
/// [kneeAngle] degrees when fed through [PhysioEngine._calculateAngle].
///
/// The landmarks are placed along a simple 2-D geometry:
///   hip  = (0,  0)
///   knee = (0,  kneeDist)
///   ankle= placed so that atan2 math yields the desired angle
Pose _buildSquatPose(double kneeAngle) {
  // knee at origin, hip directly above, ankle at angle from knee
  const kHipY = -1.0;
  const kHipX = 0.0;
  const kKneeX = 0.0;
  const kKneeY = 0.0;

  // vector from knee→hip points upward; we want the angle
  // between knee→hip and knee→ankle to equal kneeAngle.
  // ankle sits below/behind the knee as the knee bends forward:
  //   v = (sinθ, -cosθ)  ⇒  knee→hip · v = cosθ  (true knee-bend angle)
  final radians = kneeAngle * pi / 180;
  final ankleX = sin(radians);
  final ankleY = -cos(radians);

  return _MockPose({
    PoseLandmarkType.leftHip: _landmark(kHipX, kHipY),
    PoseLandmarkType.leftKnee: _landmark(kKneeX, kKneeY),
    PoseLandmarkType.leftAnkle: _landmark(ankleX, ankleY),
  });
}

/// A [Pose] missing the ankle landmark.
Pose _missingAnklePose() => _MockPose({
      PoseLandmarkType.leftHip: _landmark(0, -1),
      PoseLandmarkType.leftKnee: _landmark(0, 0),
    });

PoseLandmark _landmark(double x, double y) => _MockLandmark(x, y);

// ────────────────────────────────────────────────────────────
// Minimal mock implementations
// ────────────────────────────────────────────────────────────

class _MockPose implements Pose {
  final Map<PoseLandmarkType, PoseLandmark> _landmarks;
  _MockPose(this._landmarks);

  @override
  Map<PoseLandmarkType, PoseLandmark> get landmarks => _landmarks;
}

class _MockLandmark implements PoseLandmark {
  @override
  final double x;
  @override
  final double y;
  _MockLandmark(this.x, this.y);

  @override
  double get z => 0;
  @override
  double get likelihood => 1.0;
  @override
  PoseLandmarkType get type => PoseLandmarkType.leftKnee;
}

// ────────────────────────────────────────────────────────────
// PhysioEngine tests
// ────────────────────────────────────────────────────────────

void main() {
  group('PhysioEngine', () {
    late PhysioEngine engine;

    setUp(() => engine = PhysioEngine());

    // ──── Boundary conditions ────

    test('returns "No person detected" for empty pose list', () {
      final msg = engine.processPose([]);
      expect(msg, contains('No person detected'));
    });

    test('returns body-visibility hint when landmarks are missing', () {
      final msg = engine.processPose([_missingAnklePose()]);
      expect(msg.toLowerCase(), contains('visible'));
    });

    test('state resets to idle on empty input after partial movement', () {
      // put engine into descending
      engine.processPose([_buildSquatPose(120)]); // mid-range
      expect(engine.reps, 0);
      // clear pose
      engine.processPose([]);
      // subsequent standing read should work normally (idle → idle)
      final msg = engine.processPose([_buildSquatPose(165)]);
      expect(msg.toLowerCase(), anyOf(contains('stand'), contains('ready')));
    });

    // ──── Standing detection ────

    test('detects standing position (angle > 140°)', () {
      final msg = engine.processPose([_buildSquatPose(165)]);
      expect(msg.toLowerCase(), anyOf(contains('stand'), contains('ready')));
    });

    // ──── Squat bottom detection ────

    test('detects squat bottom (angle < 90°)', () {
      // Need to transition idle → descending first
      engine.processPose([_buildSquatPose(165)]); // standing
      engine.processPose([_buildSquatPose(120)]); // descending
      engine.processPose([_buildSquatPose(120)]); // descending
      engine.processPose([_buildSquatPose(120)]); // descending

      // Now go to squat bottom several times to satisfy stableFrames
      String msg = '';
      for (int i = 0; i < 5; i++) {
        msg = engine.processPose([_buildSquatPose(75)]);
      }
      expect(msg.toLowerCase(),
          anyOf(contains('hold'), contains('push'), contains('good depth')));
    });

    // ──── Rep counting ────

    test('counts a full rep: stand → squat bottom → stand', () {
      engine.processPose([_buildSquatPose(165)]); // standing (idle)
      // Descend
      for (int i = 0; i < 4; i++) {
        engine.processPose([_buildSquatPose(120)]);
      }
      // Squat bottom
      for (int i = 0; i < 4; i++) {
        engine.processPose([_buildSquatPose(75)]);
      }
      // Ascend
      for (int i = 0; i < 4; i++) {
        engine.processPose([_buildSquatPose(120)]);
      }
      // Stand — should complete rep
      String lastMsg = '';
      for (int i = 0; i < 4; i++) {
        lastMsg = engine.processPose([_buildSquatPose(165)]);
      }
      // Either rep was counted or final message says completed
      expect(
        engine.reps >= 1 || lastMsg.toLowerCase().contains('completed'),
        isTrue,
        reason: 'Expected ≥1 rep after full squat cycle',
      );
    });

    test('stable-frame requirement prevents premature rep count', () {
      // Immediately stand after only 1 squat-bottom frame
      engine.processPose([_buildSquatPose(165)]); // idle
      engine.processPose([_buildSquatPose(75)]);  // 1 squat frame (not enough)
      engine.processPose([_buildSquatPose(165)]); // back to standing
      // should NOT count a rep
      expect(engine.reps, 0);
    });

    test('incomplete squat (partial descent, no bottom) does not count rep', () {
      engine.processPose([_buildSquatPose(165)]);
      engine.processPose([_buildSquatPose(130)]); // partial — not at bottom
      engine.processPose([_buildSquatPose(165)]); // back to standing
      expect(engine.reps, 0);
    });

    // ──── Reset ────

    test('reset() clears rep count and state', () {
      engine.reps = 5;
      engine.reset();
      expect(engine.reps, 0);
    });

    // ──── Angle calculation sanity (via processPose) ────

    test('high angle (> squatConfig.targetMaxAngle − tolerance) gives standing feedback', () {
      final standing = engine.processPose([_buildSquatPose(170)]);
      expect(
        standing.toLowerCase(),
        anyOf(contains('stand'), contains('ready'), contains('completed')),
      );
    });

    test('low angle (< squatConfig.targetMinAngle + tolerance) gives squat feedback', () {
      // Prime state
      engine.processPose([_buildSquatPose(165)]);
      for (int i = 0; i < 3; i++) {
        engine.processPose([_buildSquatPose(120)]);
      }
      final deep = engine.processPose([_buildSquatPose(60)]);
      expect(
        deep.toLowerCase(),
        anyOf(contains('hold'), contains('push'), contains('good'), contains('depth')),
      );
    });
  });
}

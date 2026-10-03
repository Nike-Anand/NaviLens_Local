import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

enum ExerciseState { idle, descending, bottom, ascending, repCompleted }

class ExerciseConfig {
  final String name;
  final double targetMinAngle;
  final double targetMaxAngle;
  final double tolerance;
  final int requiredStableFrames;

  ExerciseConfig({
    required this.name,
    required this.targetMinAngle,
    required this.targetMaxAngle,
    this.tolerance = 15.0,
    this.requiredStableFrames = 3,
  });
}

class PhysioEngine {
  int reps = 0;
  ExerciseState _state = ExerciseState.idle;
  int _stableFrames = 0;
  
  final ExerciseConfig squatConfig = ExerciseConfig(
    name: 'Squat',
    targetMinAngle: 70.0, // Angle at bottom of squat
    targetMaxAngle: 160.0, // Angle when standing
    tolerance: 20.0,
  );

  double _calculateAngle(PoseLandmark first, PoseLandmark middle, PoseLandmark last) {
    double angle = atan2(last.y - middle.y, last.x - middle.x) -
        atan2(first.y - middle.y, first.x - middle.x);
    angle = angle * (180 / pi);
    angle = angle.abs();
    if (angle > 180) {
      angle = 360 - angle;
    }
    return angle;
  }

  String processPose(List<Pose> poses) {
    if (poses.isEmpty) {
      _state = ExerciseState.idle;
      return "No person detected.";
    }

    final pose = poses.first;
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];

    // Ensure confidence is high enough (ML Kit doesn't expose confidence on PoseLandmark directly in this wrapper, so we check nullity/bounds)
    if (leftHip == null || leftKnee == null || leftAnkle == null) {
      return "Ensure your full body is visible.";
    }

    final kneeAngle = _calculateAngle(leftHip, leftKnee, leftAnkle);

    // State Machine
    if (kneeAngle > squatConfig.targetMaxAngle - squatConfig.tolerance) {
      if (_state == ExerciseState.ascending || _state == ExerciseState.bottom) {
        _stableFrames++;
        if (_stableFrames >= squatConfig.requiredStableFrames) {
          reps++;
          _state = ExerciseState.idle;
          _stableFrames = 0;
          return "Repetition completed. Good form.";
        }
      } else {
        _state = ExerciseState.idle;
      }
      return "Standing. Ready.";
    } 
    else if (kneeAngle < squatConfig.targetMinAngle + squatConfig.tolerance) {
      if (_state == ExerciseState.descending || _state == ExerciseState.idle) {
        _stableFrames++;
        if (_stableFrames >= squatConfig.requiredStableFrames) {
          _state = ExerciseState.bottom;
          _stableFrames = 0;
          return "Good depth. Now push up.";
        }
      }
      return "Hold position.";
    } 
    else {
      // In transition
      _stableFrames = 0;
      if (_state == ExerciseState.idle || _state == ExerciseState.descending) {
        _state = ExerciseState.descending;
        return "Going down...";
      } else {
        _state = ExerciseState.ascending;
        return "Pushing up...";
      }
    }
  }

  void reset() {
    reps = 0;
    _state = ExerciseState.idle;
    _stableFrames = 0;
  }
}

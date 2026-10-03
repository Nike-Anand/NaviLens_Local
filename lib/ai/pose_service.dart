import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseService {
  final PoseDetector _poseDetector = PoseDetector(options: PoseDetectorOptions());

  Future<List<Pose>> analyzeImage(InputImage inputImage) async {
    try {
      return await _poseDetector.processImage(inputImage);
    } catch (e) {
      return [];
    }
  }

  void dispose() {
    _poseDetector.close();
  }
}

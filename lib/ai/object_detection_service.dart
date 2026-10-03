import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

class ObjectDetectionService {
  late ObjectDetector _objectDetector;

  ObjectDetectionService() {
    final options = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: options);
  }

  Future<List<DetectedObject>> analyzeImage(InputImage inputImage) async {
    try {
      return await _objectDetector.processImage(inputImage);
    } catch (e) {
      print('Object Detection Error: $e');
      return [];
    }
  }

  void dispose() {
    _objectDetector.close();
  }
}

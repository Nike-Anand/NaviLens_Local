import 'package:flutter/foundation.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

class ObjectDetectionService {
  // singleImage mode works reliably on all devices with the built-in ML Kit
  // base model. stream mode can silently drop frames and produce empty label
  // lists when no custom tflite model is bundled.
  late final ObjectDetector _objectDetector;

  ObjectDetectionService() {
    _objectDetector = ObjectDetector(
      options: ObjectDetectorOptions(
        mode: DetectionMode.single,
        // classifyObjects requires a custom tflite model bundled in assets.
        // The base ML Kit model only provides bounding boxes — enabling
        // classifyObjects with no model always returns empty label lists,
        // which is why image classification appeared broken.
        classifyObjects: false,
        multipleObjects: true,
      ),
    );
  }

  Future<List<DetectedObject>> analyzeImage(InputImage inputImage) async {
    try {
      final results = await _objectDetector.processImage(inputImage);
      // Filter out zero-area or non-finite bounding boxes.
      return results
          .where((o) =>
              o.boundingBox.isFinite &&
              o.boundingBox.width > 0 &&
              o.boundingBox.height > 0)
          .toList();
    } catch (e) {
      debugPrint('Object Detection Error: $e');
      return [];
    }
  }

  void dispose() {
    _objectDetector.close();
  }
}

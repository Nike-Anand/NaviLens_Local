import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:navilens_local/camera/camera_view.dart';
import 'package:navilens_local/ai/object_detection_service.dart';
import 'package:navilens_local/accessibility/feedback_engine.dart';
import 'package:navilens_local/main.dart';

class EnvironmentScreen extends StatefulWidget {
  const EnvironmentScreen({super.key});

  @override
  State<EnvironmentScreen> createState() => _EnvironmentScreenState();
}

class _EnvironmentScreenState extends State<EnvironmentScreen> {
  final ObjectDetectionService _detectionService = ObjectDetectionService();
  String _environmentDescription = "Scanning surroundings...";
  bool _isProcessing = false;
  DateTime _lastSpokenTime = DateTime.now();

  @override
  void dispose() {
    _detectionService.dispose();
    super.dispose();
  }

  void _processCameraImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) {
      _isProcessing = false;
      return;
    }

    final objects = await _detectionService.analyzeImage(inputImage);
    
    if (objects.isNotEmpty && mounted) {
      // Find the most prominent object
      final label = objects.first.labels.isNotEmpty 
          ? objects.first.labels.first.text 
          : "Object";
          
      final description = "$label ahead.";
      
      setState(() {
        _environmentDescription = description;
      });

      // Throttle speech so it doesn't spam the user
      if (DateTime.now().difference(_lastSpokenTime).inSeconds > 3) {
        FeedbackEngine.speak(description);
        _lastSpokenTime = DateTime.now();
      }
    }

    _isProcessing = false;
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (cameras.isEmpty) return null;
    final camera = cameras.first;
    return InputImage.fromBytes(
      bytes: image.planes[0].bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotationValue.fromRawValue(camera.sensorOrientation) ?? InputImageRotation.rotation0deg,
        format: InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.yuv420,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Environment Assistant')),
      body: Stack(
        children: [
          if (cameras.isNotEmpty)
            CameraView(cameras: cameras, onImage: _processCameraImage)
          else
            const Center(child: Text("No camera available")),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.orange.shade900,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _environmentDescription, 
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

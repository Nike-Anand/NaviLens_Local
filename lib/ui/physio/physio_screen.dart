import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:navilens_local/camera/camera_view.dart';
import 'package:navilens_local/ai/physio_engine.dart';
import 'package:navilens_local/accessibility/feedback_engine.dart';
import 'package:navilens_local/main.dart';

class PhysioScreen extends StatefulWidget {
  const PhysioScreen({super.key});

  @override
  State<PhysioScreen> createState() => _PhysioScreenState();
}

class _PhysioScreenState extends State<PhysioScreen> {
  final PoseService _poseService = PoseService();
  final PhysioEngine _physioEngine = PhysioEngine();
  
  String _feedback = "Position yourself in frame";
  bool _isProcessing = false;
  int _lastRepCount = 0;

  @override
  void dispose() {
    _poseService.dispose();
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

    final poses = await _poseService.analyzeImage(inputImage);
    final feedback = _physioEngine.processPose(poses);

    if (mounted) {
      setState(() {
        _feedback = feedback;
      });
      
      if (_physioEngine.reps > _lastRepCount) {
        _lastRepCount = _physioEngine.reps;
        FeedbackEngine.speak("Repetition $_lastRepCount completed.");
        FeedbackEngine.vibrateInfo();
      }
    }

    _isProcessing = false;
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (cameras.isEmpty) return null;
    final camera = cameras.first;
    // Basic conversion logic (simplified for constraints)
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
      appBar: AppBar(title: const Text('Physio Coach')),
      body: Stack(
        children: [
          if (cameras.isNotEmpty)
            CameraView(cameras: cameras, onImage: _processCameraImage)
          else
            const Center(child: Text("No camera available")),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade900,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Reps: ${_physioEngine.reps}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(_feedback, style: const TextStyle(fontSize: 20, color: Colors.white70)),
                  const SizedBox(height: 16),
                  const Text('Assistive exercise guidance. Not a substitute for professional physiotherapy.', 
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.white70), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

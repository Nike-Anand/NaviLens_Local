import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:navilens_local/camera/camera_view.dart';
import 'package:navilens_local/ai/ocr_service.dart';
import 'package:navilens_local/ai/models.dart';
import 'package:navilens_local/main.dart'; // To access global cameras list

class MedicineScreen extends StatefulWidget {
  const MedicineScreen({super.key});

  @override
  State<MedicineScreen> createState() => _MedicineScreenState();
}

class _MedicineScreenState extends State<MedicineScreen> {
  final OcrService _ocrService = OcrService();
  MedicineInfo? _currentMedicine;
  bool _isProcessing = false;

  @override
  void dispose() {
    _ocrService.dispose();
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

    final result = await _ocrService.analyzeImage(inputImage);
    if (mounted && result != null) {
      setState(() {
        _currentMedicine = result;
      });
    }

    _isProcessing = false;
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (cameras.isEmpty) return null;
    final camera = cameras.first;
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation = _orientations[DeviceOrientation.portraitUp];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    
    if (rotation == null) return null;
    
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null || (Platform.isAndroid && format != InputImageFormat.nv21 && format != InputImageFormat.yuv420)) return null;

    if (image.planes.isEmpty) return null;

    return InputImage.fromBytes(
      bytes: image.planes[0].bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medicine Reader')),
      body: Stack(
        children: [
          if (cameras.isNotEmpty)
            CameraView(
              cameras: cameras,
              onImage: _processCameraImage,
            )
          else
            const Center(child: Text("No camera available")),
          if (_currentMedicine != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue.shade900,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Detected Medicine', style: TextStyle(fontSize: 16, color: Colors.blue.shade100)),
                    const SizedBox(height: 8),
                    Text(_currentMedicine!.name ?? 'Unknown', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    if (_currentMedicine!.strength != null) ...[
                      const SizedBox(height: 4),
                      Text('Strength: ${_currentMedicine!.strength}', style: const TextStyle(fontSize: 18, color: Colors.white)),
                    ],
                    if (_currentMedicine!.expiryDate != null) ...[
                      const SizedBox(height: 4),
                      Text('Expiry: ${_currentMedicine!.expiryDate}', style: const TextStyle(fontSize: 18, color: Colors.redAccent)),
                    ],
                    const SizedBox(height: 16),
                    const Text('For information only. Follow your prescription and healthcare professional\'s instructions.', 
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.white70)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

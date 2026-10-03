import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraView extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Function(CameraImage image) onImage;

  const CameraView({
    super.key,
    required this.cameras,
    required this.onImage,
  });

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  CameraController? _controller;
  int _cameraIndex = -1;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    if (widget.cameras.any((element) => element.lensDirection == CameraLensDirection.back)) {
      _cameraIndex = widget.cameras.indexOf(
        widget.cameras.firstWhere((element) => element.lensDirection == CameraLensDirection.back),
      );
    } else if (widget.cameras.isNotEmpty) {
      _cameraIndex = 0;
    }

    if (_cameraIndex != -1) {
      _startLiveFeed();
    }
  }

  @override
  void dispose() {
    _stopLiveFeed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || _controller?.value.isInitialized == false) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          CameraPreview(_controller!),
        ],
      ),
    );
  }

  Future _startLiveFeed() async {
    final camera = widget.cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    
    try {
      await _controller?.initialize();
      if (!mounted) return;
      
      _controller?.startImageStream((CameraImage image) {
        if (!_isBusy) {
          _isBusy = true;
          widget.onImage(image);
          // Throttle frames to not overload the ML models
          Future.delayed(const Duration(milliseconds: 100), () {
            _isBusy = false;
          });
        }
      });
      setState(() {});
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future _stopLiveFeed() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }
}

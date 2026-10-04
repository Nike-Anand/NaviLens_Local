import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Full-screen live camera feed with optional aligned overlays and flash
/// control.
///
/// The preview is placed inside an [AspectRatio] that matches the controller's
/// native aspect ratio. Any [overlayBuilder] content is laid inside that same
/// box so UI such as detection boxes / landmarks align with the preview.
class CameraView extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Function(CameraImage image) onImage;

  /// Optional builder layered over the preview. Receives the most recent raw
  /// camera frame size so coordinates can be mapped via [CoordinateMapper].
  final Widget Function(BuildContext context, Size imageSize)? overlayBuilder;

  /// When provided, toggling this notifier switches the camera torch on/off.
  final ValueNotifier<bool>? flashControl;

  const CameraView({
    super.key,
    required this.cameras,
    required this.onImage,
    this.overlayBuilder,
    this.flashControl,
  });

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  CameraController? _controller;
  int _cameraIndex = -1;
  bool _isBusy = false;
  Size _imageSize = Size.zero;
  bool _torch = false;

  @override
  void initState() {
    super.initState();
    widget.flashControl?.addListener(_onFlashChanged);
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

  void _onFlashChanged() {
    final on = widget.flashControl?.value ?? false;
    if (on == _torch) return;
    _torch = on;
    if (_controller != null && _controller!.value.isInitialized) {
      _controller!.setFlashMode(on ? FlashMode.torch : FlashMode.off).catchError((_) {});
    }
  }

  @override
  void dispose() {
    widget.flashControl?.removeListener(_onFlashChanged);
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
      body: Center(
        child: AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              CameraPreview(_controller!),
              if (widget.overlayBuilder != null && _imageSize != Size.zero)
                IgnorePointer(
                  child: widget.overlayBuilder!(context, _imageSize),
                ),
            ],
          ),
        ),
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
          _imageSize = Size(image.width.toDouble(), image.height.toDouble());
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

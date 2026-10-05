import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'package:navilens_local/accessibility/feedback_engine.dart';
import 'package:navilens_local/ai/physio_engine.dart';
import 'package:navilens_local/ai/pose_service.dart';
import 'package:navilens_local/camera/camera_view.dart';
import 'package:navilens_local/main.dart';

import '../components/app_components.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class PhysioScreen extends StatefulWidget {
  const PhysioScreen({super.key});

  @override
  State<PhysioScreen> createState() => _PhysioScreenState();
}

class _PhysioScreenState extends State<PhysioScreen> {
  final PoseService _poseService = PoseService();
  final PhysioEngine _physioEngine = PhysioEngine();

  String _feedback = 'Position yourself in frame';

  bool _isProcessing = false;
  int _lastRepCount = 0;
  bool _isPaused = false;

  @override
  void dispose() {
    _poseService.dispose();
    super.dispose();
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing || _isPaused) {
      return;
    }

    _isProcessing = true;

    final inputImage = _inputImageFromCameraImage(image);

    if (inputImage == null) {
      _isProcessing = false;
      return;
    }

    try {
      final poses = await _poseService.analyzeImage(inputImage);
      final feedback = _physioEngine.processPose(poses);

      if (mounted) {
        setState(() {
          _feedback = feedback;
        });

        if (_physioEngine.reps > _lastRepCount) {
          _lastRepCount = _physioEngine.reps;

          FeedbackEngine.speak(
            'Repetition $_lastRepCount completed.',
          );

          FeedbackEngine.vibrateInfo();
          HapticFeedback.mediumImpact();
        }
      }
    } catch (e) {
      debugPrint('Physio processing error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (cameras.isEmpty || image.planes.isEmpty) return null;

    // Use the back camera for correct sensor-orientation metadata.
    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    // ML Kit on Android expects a full NV21 buffer (Y plane + interleaved UV).
    // Passing only planes[0] (Y plane alone) produces incorrect pose results.
    final Uint8List bytes;
    if (image.planes.length == 1) {
      bytes = image.planes[0].bytes;
    } else {
      final allBytes = <int>[];
      for (final plane in image.planes) {
        allBytes.addAll(plane.bytes);
      }
      bytes = Uint8List.fromList(allBytes);
    }

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(
          image.width.toDouble(),
          image.height.toDouble(),
        ),
        rotation:
            InputImageRotationValue.fromRawValue(
              camera.sensorOrientation,
            ) ??
            InputImageRotation.rotation0deg,
        format:
            InputImageFormatValue.fromRawValue(
              image.format.raw,
            ) ??
            InputImageFormat.yuv420,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  void _togglePause() {
    HapticFeedback.selectionClick();

    setState(() {
      _isPaused = !_isPaused;
    });

    FeedbackEngine.speak(
      _isPaused
          ? 'Exercise paused.'
          : 'Exercise resumed.',
    );
  }

  void _stopExercise() {
    HapticFeedback.heavyImpact();

    FeedbackEngine.speak(
      'Exercise stopped. ${_physioEngine.reps} repetitions completed.',
    );

    Navigator.of(context).pop();
  }

  bool get _isGoodForm {
    final text = _feedback.toLowerCase();

    return text.contains('good') ||
        text.contains('completed') ||
        text.contains('ready');
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            cameras.isNotEmpty
                ? CameraView(
                    cameras: cameras,
                    onImage: _processCameraImage,
                  )
                : const AppErrorState(
                    title: 'We can\'t see your full body',
                    message:
                        'Move the phone farther away\nand make sure your body is visible.',
                  ),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _PhysioTopBar(
                isPaused: _isPaused,
                onPause: _togglePause,
                topInset: topInset,
              ),
            ),

            if (_isPaused)
              Positioned.fill(
                child: Container(
                  color: AppColors.overlayDark.withValues(
                    alpha: 0.86,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.pause_circle_outline_rounded,
                            color: Colors.white,
                            size: 76,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Paused',
                            style: AppTypography.headline,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: 220,
                            child: AppButton(
                              label: 'Resume',
                              icon: Icons.play_arrow_rounded,
                              color: AppColors.physio,
                              onTap: _togglePause,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            if (!_isPaused)
              Align(
                alignment: Alignment.bottomCenter,
                child: DraggableScrollableSheet(
                  initialChildSize: 0.38,
                  minChildSize: 0.28,
                  maxChildSize: 0.72,
                  snap: true,
                  snapSizes: const [
                    0.38,
                    0.72,
                  ],
                  expand: false,
                  builder: (
                    context,
                    scrollController,
                  ) {
                    return _PhysioCoachPanel(
                      reps: _physioEngine.reps,
                      feedback: _feedback,
                      isGoodForm: _isGoodForm,
                      onStop: _stopExercise,
                      scrollController: scrollController,
                      bottomInset: bottomInset,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PhysioTopBar extends StatelessWidget {
  final bool isPaused;
  final VoidCallback onPause;
  final double topInset;

  const _PhysioTopBar({
    required this.isPaused,
    required this.onPause,
    required this.topInset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        6,
        topInset + 4,
        8,
        18,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.84),
            Colors.black.withValues(alpha: 0.20),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Go back',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),

          const SizedBox(width: 4),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Physio Coach',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSmall.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Squat Exercise',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.70),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          AppIconButton(
            icon: isPaused
                ? Icons.play_arrow_rounded
                : Icons.pause_rounded,
            semanticsLabel: isPaused ? 'Resume' : 'Pause',
            color: AppColors.physio.withValues(alpha: 0.20),
            iconColor: AppColors.physio,
            onTap: onPause,
          ),
        ],
      ),
    );
  }
}

class _PhysioCoachPanel extends StatelessWidget {
  final int reps;
  final String feedback;
  final bool isGoodForm;
  final VoidCallback onStop;
  final ScrollController scrollController;
  final double bottomInset;

  const _PhysioCoachPanel({
    required this.reps,
    required this.feedback,
    required this.isGoodForm,
    required this.onStop,
    required this.scrollController,
    required this.bottomInset,
  });

  @override
  Widget build(BuildContext context) {
    final formColor =
        isGoodForm ? AppColors.physio : AppColors.warning;

    return Material(
      color: AppColors.surface,
      elevation: 16,
      shadowColor: Colors.black.withValues(alpha: 0.50),
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(28),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const SizedBox(height: 10),

          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(99),
            ),
          ),

          Expanded(
            child: ListView(
              controller: scrollController,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                18,
                AppSpacing.lg,
                bottomInset + 24,
              ),
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        Semantics(
                          label: 'Repetitions completed: $reps',
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$reps',
                                style: AppTypography.counter.copyWith(
                                  color: AppColors.physio,
                                ),
                              ),
                              Text(
                                'REPS',
                                style: AppTypography.label.copyWith(
                                  color: AppColors.physio,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Semantics(
                          label:
                              'Form status: ${isGoodForm ? "Good" : "Needs adjustment"}',
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: formColor.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius:
                                  BorderRadius.circular(14),
                              border: Border.all(
                                color: formColor.withValues(
                                  alpha: 0.32,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isGoodForm
                                      ? Icons.check_circle_outline
                                      : Icons.adjust_rounded,
                                  color: formColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  isGoodForm
                                      ? 'GOOD FORM'
                                      : 'ADJUST POSTURE',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      AppTypography.label.copyWith(
                                    color: formColor,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 18),

                Semantics(
                  liveRegion: true,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: 0.08,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.primary.withValues(
                          alpha: 0.18,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.volume_up_rounded,
                          color: AppColors.primary,
                          size: 19,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            feedback,
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textPrimary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onStop,
                    icon: const Icon(
                      Icons.stop_rounded,
                    ),
                    label: const Text('Stop Exercise'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          AppColors.error.withValues(
                        alpha: 0.90,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Assistive exercise guidance. Not a substitute for professional physiotherapy.',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
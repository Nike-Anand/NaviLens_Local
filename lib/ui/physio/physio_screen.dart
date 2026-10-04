import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:navilens_local/camera/camera_view.dart';
import 'package:navilens_local/ai/physio_engine.dart';
import 'package:navilens_local/ai/pose_service.dart';
import 'package:navilens_local/accessibility/feedback_engine.dart';
import 'package:navilens_local/main.dart';
import 'package:navilens_local/ui/theme/app_colors.dart';
import 'package:navilens_local/ui/theme/app_typography.dart';
import 'package:navilens_local/ui/theme/app_spacing.dart';
import 'package:navilens_local/ui/components/app_components.dart';

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

  void _processCameraImage(CameraImage image) async {
    if (_isProcessing || _isPaused) return;
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
        FeedbackEngine.speak('Repetition $_lastRepCount completed.');
        FeedbackEngine.vibrateInfo();
        HapticFeedback.mediumImpact();
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
        rotation: InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
            InputImageRotation.rotation0deg,
        format: InputImageFormatValue.fromRawValue(image.format.raw) ??
            InputImageFormat.yuv420,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  void _togglePause() {
    HapticFeedback.selectionClick();
    setState(() => _isPaused = !_isPaused);
    if (_isPaused) {
      FeedbackEngine.speak('Exercise paused.');
    } else {
      FeedbackEngine.speak('Exercise resumed.');
    }
  }

  void _stopExercise() {
    HapticFeedback.heavyImpact();
    FeedbackEngine.speak('Exercise stopped. ${_physioEngine.reps} repetitions completed.');
    Navigator.of(context).pop();
  }

  bool get _isGoodForm {
    final f = _feedback.toLowerCase();
    return f.contains('good') || f.contains('completed') || f.contains('ready');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Camera
            cameras.isNotEmpty
                ? CameraView(cameras: cameras, onImage: _processCameraImage)
                : const AppErrorState(
                    title: "We can't see your full body",
                    message:
                        'Move the phone farther away\nand make sure your body is visible.',
                  ),

            // Top bar
            Positioned(
              top: 0, left: 0, right: 0,
              child: _PhysioTopBar(
                isPaused: _isPaused,
                onPause: _togglePause,
              ),
            ),

            // Paused overlay
            if (_isPaused)
              Container(
                color: AppColors.overlayDark,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.pause_circle_outline, color: Colors.white, size: 80),
                      const SizedBox(height: AppSpacing.md),
                      const Text('Paused', style: AppTypography.headline),
                      const SizedBox(height: AppSpacing.xl),
                      AppButton(
                        label: 'Resume',
                        icon: Icons.play_arrow_rounded,
                        color: AppColors.physio,
                        onTap: _togglePause,
                      ),
                    ],
                  ),
                ),
              ),

            // Bottom coaching panel
            if (!_isPaused)
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: _PhysioCoachPanel(
                  reps: _physioEngine.reps,
                  feedback: _feedback,
                  isGoodForm: _isGoodForm,
                  onStop: _stopExercise,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Physio Top Bar
// ─────────────────────────────────────────────
class _PhysioTopBar extends StatelessWidget {
  final bool isPaused;
  final VoidCallback onPause;

  const _PhysioTopBar({required this.isPaused, required this.onPause});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.85), Colors.transparent],
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Go back',
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Physio Coach', style: AppTypography.titleSmall),
                Text('Squat Exercise', style: AppTypography.caption),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: isPaused ? 'Resume exercise' : 'Pause exercise',
            child: AppIconButton(
              icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              semanticsLabel: isPaused ? 'Resume' : 'Pause',
              color: AppColors.physio.withValues(alpha: 0.25),
              iconColor: AppColors.physio,
              onTap: onPause,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Physio Coaching Panel
// ─────────────────────────────────────────────
class _PhysioCoachPanel extends StatelessWidget {
  final int reps;
  final String feedback;
  final bool isGoodForm;
  final VoidCallback onStop;

  const _PhysioCoachPanel({
    required this.reps,
    required this.feedback,
    required this.isGoodForm,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final formColor = isGoodForm ? AppColors.physio : AppColors.warning;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Rep counter + form status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Rep counter
              Semantics(
                label: 'Repetitions completed: $reps',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$reps',
                      style: AppTypography.counter.copyWith(color: AppColors.physio),
                    ),
                    Text('REPS', style: AppTypography.label.copyWith(
                      color: AppColors.physio,
                      letterSpacing: 2,
                    )),
                  ],
                ),
              ),

              // Form status badge
              Semantics(
                label: 'Form status: ${isGoodForm ? "Good" : "Needs adjustment"}',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: formColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: formColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isGoodForm ? Icons.check_circle_outline : Icons.adjust_rounded,
                        color: formColor, size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isGoodForm ? 'GOOD FORM' : 'ADJUST POSTURE',
                        style: AppTypography.label.copyWith(color: formColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Feedback text
          Semantics(
            liveRegion: true,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      feedback,
                      style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Stop button
          Semantics(
            button: true,
            label: 'Stop exercise session',
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onStop,
                icon: const Icon(Icons.stop_rounded),
                label: const Text('Stop Exercise'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error.withValues(alpha: 0.85),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xs),
          Text(
            'Assistive exercise guidance. Not a substitute for professional physiotherapy.',
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

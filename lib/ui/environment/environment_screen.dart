import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:navilens_local/camera/camera_view.dart';
import 'package:navilens_local/ai/object_detection_service.dart';
import 'package:navilens_local/accessibility/feedback_engine.dart';
import 'package:navilens_local/main.dart';
import 'package:navilens_local/ui/theme/app_colors.dart';
import 'package:navilens_local/ui/theme/app_typography.dart';
import 'package:navilens_local/ui/theme/app_spacing.dart';
import 'package:navilens_local/ui/components/app_components.dart';
import 'package:navilens_local/ui/components/coordinate_mapper.dart';

class EnvironmentScreen extends StatefulWidget {
  const EnvironmentScreen({super.key});

  @override
  State<EnvironmentScreen> createState() => _EnvironmentScreenState();
}

class _EnvironmentScreenState extends State<EnvironmentScreen> {
  final ObjectDetectionService _detectionService = ObjectDetectionService();
  List<_DetectedItem> _detectedItems = [];
  String _primaryDescription = 'Scanning surroundings...';
  bool _isProcessing = false;
  DateTime _lastSpokenTime = DateTime.fromMillisecondsSinceEpoch(0);

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
      final items = objects.take(3).map((obj) {
        final label = obj.labels.isNotEmpty ? obj.labels.first.text : 'Object';
        final confidence = obj.labels.isNotEmpty ? obj.labels.first.confidence : 0.0;
        return _DetectedItem(
          label: label,
          confidence: confidence,
          rect: obj.boundingBox,
        );
      }).toList();

      final primaryLabel = items.first.label;
      final description = '$primaryLabel ahead.';

      setState(() {
        _detectedItems = items;
        _primaryDescription = description;
      });

      // Throttle speech — existing 3-second constraint preserved
      if (DateTime.now().difference(_lastSpokenTime).inSeconds > 3) {
        FeedbackEngine.speak(description);
        HapticFeedback.lightImpact();
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
        rotation: InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
            InputImageRotation.rotation0deg,
        format: InputImageFormatValue.fromRawValue(image.format.raw) ??
            InputImageFormat.yuv420,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Camera + bounding box overlays
            cameras.isNotEmpty
                ? CameraView(
                    cameras: cameras,
                    onImage: _processCameraImage,
                    overlayBuilder:
                        _detectedItems.isEmpty
                            ? null
                            : (context, imageSize) => LayoutBuilder(
                                builder: (context, constraints) {
                                  final box = Size(
                                    constraints.maxWidth,
                                    constraints.maxHeight,
                                  );
                                  return Stack(
                                    clipBehavior: Clip.none,
                                    children: _detectedItems
                                        .where((i) => i.rect.isFinite)
                                        .map(
                                          (item) => _BoundingBox(
                                            item: item,
                                            src: imageSize,
                                            box: box,
                                          ),
                                        )
                                        .toList(),
                                  );
                                },
                              ),
                  )
                : const AppErrorState(
                    title: 'Camera access needed',
                    message: 'NaviLens uses your camera to describe surroundings.',
                  ),

            // Top bar
            Positioned(
              top: 0, left: 0, right: 0,
              child: _TopBar(
                title: 'Environment Assistant',
                accentColor: AppColors.environment,
              ),
            ),

            // Detection overlays
            if (_detectedItems.isNotEmpty)
              Positioned(
                top: 80, left: AppSpacing.md, right: AppSpacing.md,
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _detectedItems
                      .map((item) => _DetectionChip(item: item))
                      .toList(),
                ),
              ),

            // Bottom description panel
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: _EnvironmentPanel(description: _primaryDescription),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Detection Chip
// ─────────────────────────────────────────────
class _DetectedItem {
  final String label;
  final double confidence;
  final Rect rect;
  const _DetectedItem({
    required this.label,
    required this.confidence,
    required this.rect,
  });
}

/// Draws a detection bounding box aligned to the camera preview. Coordinates
/// are mapped from the raw camera frame into the preview box via
/// [CoordinateMapper].
class _BoundingBox extends StatelessWidget {
  final _DetectedItem item;
  final Size src;
  final Size box;

  const _BoundingBox({
    required this.item,
    required this.src,
    required this.box,
  });

  @override
  Widget build(BuildContext context) {
    if (box.width <= 0 || box.height <= 0 || src.width <= 0 || src.height <= 0) {
      return const SizedBox.shrink();
    }
    final mapped = CoordinateMapper.mapRect(item.rect, src, box);
    final pct = (item.confidence * 100).round().clamp(0, 100);

    return Positioned(
      left: mapped.left,
      top: mapped.top,
      width: mapped.width,
      height: mapped.height,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.environmentLight, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            margin: const EdgeInsets.all(2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.environment,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${item.label} $pct%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetectionChip extends StatelessWidget {
  final _DetectedItem item;
  const _DetectionChip({required this.item});

  @override
  Widget build(BuildContext context) {
    final pct = (item.confidence * 100).round();
    return Semantics(
      label: '${item.label}, $pct percent confidence',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.environment.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.environmentLight.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.label,
              style: AppTypography.titleSmall.copyWith(fontSize: 16),
            ),
            Text(
              '$pct%',
              style: AppTypography.caption.copyWith(
                color: AppColors.environmentLight,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Top Bar (local)
// ─────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String title;
  final Color accentColor;

  const _TopBar({required this.title, required this.accentColor});

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
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(title, style: AppTypography.titleSmall)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              border: Border.all(color: accentColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: accentColor, size: 8),
                const SizedBox(width: 5),
                Text('LIVE', style: AppTypography.label.copyWith(color: accentColor, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EnvironmentPanel extends StatelessWidget {
  final String description;
  const _EnvironmentPanel({required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppColors.environment.withValues(alpha: 0.9),
            AppColors.environment.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 1.0],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.xxl, AppSpacing.lg, AppSpacing.xl,
      ),
      child: Semantics(
        liveRegion: true,
        label: description,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Icon(Icons.volume_up_rounded, color: Colors.white, size: 28),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                description,
                style: AppTypography.headline.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

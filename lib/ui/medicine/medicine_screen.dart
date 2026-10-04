import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:navilens_local/camera/camera_view.dart';
import 'package:navilens_local/ai/ocr_service.dart';
import 'package:navilens_local/ai/models.dart';
import 'package:navilens_local/accessibility/feedback_engine.dart';
import 'package:navilens_local/main.dart';
import 'package:navilens_local/ui/theme/app_colors.dart';
import 'package:navilens_local/ui/theme/app_typography.dart';
import 'package:navilens_local/ui/theme/app_spacing.dart';
import 'package:navilens_local/ui/components/app_components.dart';

class MedicineScreen extends StatefulWidget {
  const MedicineScreen({super.key});

  @override
  State<MedicineScreen> createState() => _MedicineScreenState();
}

class _MedicineScreenState extends State<MedicineScreen> {
  final OcrService _ocrService = OcrService();
  final ValueNotifier<bool> _flashOn = ValueNotifier<bool>(false);
  MedicineInfo? _currentMedicine;
  bool _isProcessing = false;
  bool _showResult = false;

  @override
  void dispose() {
    _flashOn.dispose();
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
        _showResult = true;
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
    if (format == null ||
        (Platform.isAndroid &&
            format != InputImageFormat.nv21 &&
            format != InputImageFormat.yuv420)) return null;

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

  void _speak() {
    if (_currentMedicine == null) return;
    final m = _currentMedicine!;
    final parts = [
      if (m.name != null) m.name!,
      if (m.strength != null) 'Strength: ${m.strength}',
      if (m.expiryDate != null) 'Expiry: ${m.expiryDate}',
      m.dosageInstruction ?? '',
      'Always follow your prescription and healthcare professional\'s instructions.',
    ].where((s) => s.isNotEmpty).join('. ');
    FeedbackEngine.speak(parts);
    HapticFeedback.lightImpact();
  }

  void _scanAgain() {
    HapticFeedback.selectionClick();
    setState(() {
      _showResult = false;
      _currentMedicine = null;
    });
    FeedbackEngine.stopSpeech();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Camera layer
            cameras.isNotEmpty
                ? CameraView(
                    cameras: cameras,
                    onImage: _processCameraImage,
                    flashControl: _flashOn,
                  )
                : const AppErrorState(
                    title: 'Camera access needed',
                    message:
                        'NaviLens uses your camera to read labels.\nPlease grant camera permission in Settings.',
                  ),

            // Top bar
            Positioned(
              top: 0, left: 0, right: 0,
              child: _TopBar(title: 'Medicine Reader', accentColor: AppColors.medicine),
            ),

            // Scan overlay (hidden when result shows)
            if (!_showResult)
              const CameraScanOverlay(
                hint: 'Hold the label steady for a clearer scan',
              ),

            // Processing indicator
            if (_isProcessing && !_showResult)
              const Positioned(
                bottom: 120,
                left: 0, right: 0,
                child: Center(
                  child: AppLoadingState(message: 'Reading medicine label...'),
                ),
              ),

            // Bottom controls (gallery / scan / flash) — hidden while result shows
            if (!_showResult)
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: _MedicineControls(
                  flashOn: _flashOn,
                  onGallery: () {
                    HapticFeedback.selectionClick();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('NaviLens is fully offline — scanning happens through the camera.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),

            // Result panel
            if (_showResult && _currentMedicine != null)
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: _MedicineResultPanel(
                  medicine: _currentMedicine!,
                  onListen: _speak,
                  onScanAgain: _scanAgain,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Top Bar
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
          Expanded(
            child: Text(title, style: AppTypography.titleSmall),
          ),
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

// ─────────────────────────────────────────────
// Medicine Result Panel
// ─────────────────────────────────────────────
class _MedicineResultPanel extends StatelessWidget {
  final MedicineInfo medicine;
  final VoidCallback onListen;
  final VoidCallback onScanAgain;

  const _MedicineResultPanel({
    required this.medicine,
    required this.onListen,
    required this.onScanAgain,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
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

          // Medicine name
          Semantics(
            header: true,
            child: Text(
              medicine.name ?? 'Unknown Medicine',
              style: AppTypography.headline.copyWith(color: AppColors.textPrimary),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Info rows
          if (medicine.strength != null)
            _InfoRow(Icons.science_outlined, 'Strength', medicine.strength!, AppColors.medicine),
          if (medicine.expiryDate != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(Icons.calendar_today_outlined, 'Expiry Date', medicine.expiryDate!, AppColors.warning),
          ],
          if (medicine.dosageInstruction != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(Icons.info_outline, 'Instructions', medicine.dosageInstruction!, AppColors.primary),
          ],

          const SizedBox(height: AppSpacing.md),

          // Safety card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Text(
                    'Safety Notice\n\nInformation extracted from the package. Always follow your prescription and healthcare professional\'s instructions.',
                    style: AppTypography.body,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Listen to medicine information',
                  child: ElevatedButton.icon(
                    onPressed: onListen,
                    icon: const Icon(Icons.volume_up_rounded),
                    label: const Text('Listen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.medicine,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Scan a different label',
                  child: OutlinedButton.icon(
                    onPressed: onScanAgain,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Scan Again'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.medicine,
                      side: const BorderSide(color: AppColors.medicine, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow(this.icon, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$label:  ',
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          ),
          Expanded(
            child: Text(value, style: AppTypography.titleSmall.copyWith(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Medicine Camera Controls — matches the reference
// bottom bar: gallery / scan / flash.
// ─────────────────────────────────────────────
class _MedicineControls extends StatelessWidget {
  final ValueNotifier<bool> flashOn;
  final VoidCallback onGallery;

  const _MedicineControls({
    required this.flashOn,
    required this.onGallery,
  });

  void _toggleFlash() {
    flashOn.value = !flashOn.value;
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: flashOn,
      builder: (context, isFlashOn, _) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withValues(alpha: 0.75),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ControlIconButton(
                icon: Icons.photo_library_outlined,
                label: 'Gallery',
                onTap: onGallery,
              ),
              Semantics(
                button: true,
                label: 'Scan medicine label',
                child: GestureDetector(
                  onTap: () => HapticFeedback.mediumImpact(),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: AppColors.medicine,
                        width: 5,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.medication_rounded,
                        color: AppColors.medicine,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
              _ControlIconButton(
                icon: isFlashOn
                    ? Icons.flash_on_rounded
                    : Icons.flash_off_rounded,
                label: isFlashOn ? 'Flash On' : 'Flash',
                active: isFlashOn,
                onTap: _toggleFlash,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ControlIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _ControlIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: active ? AppColors.medicine : Colors.white,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

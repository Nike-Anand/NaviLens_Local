import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import 'package:navilens_local/accessibility/feedback_engine.dart';
import 'package:navilens_local/ai/models.dart';
import 'package:navilens_local/ai/ocr_service.dart';
import 'package:navilens_local/camera/camera_view.dart';
import 'package:navilens_local/main.dart';
import 'package:navilens_local/data/history_db.dart';

import '../components/app_components.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class MedicineScreen extends StatefulWidget {
  const MedicineScreen({super.key});

  @override
  State<MedicineScreen> createState() => _MedicineScreenState();
}

class _MedicineScreenState extends State<MedicineScreen> {
  final OcrService _ocrService = OcrService();
  final ImagePicker _imagePicker = ImagePicker();
  final GlobalKey<CameraViewState> _cameraKey = GlobalKey<CameraViewState>();

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

  bool get _supportsOnDeviceOcr =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _captureImage() async {
    if (_isProcessing) return;
    if (!_supportsOnDeviceOcr) {
      _showMessage('Medicine reading is supported on Android and iOS.');
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final photo = await _cameraKey.currentState?.capturePhoto();
      if (photo == null) {
        _showMessage(
            'Could not capture a photo. Check camera access and try again.');
        return;
      }
      await _readImage(photo.path);
    } catch (e) {
      debugPrint('Medicine capture error: $e');
      _showMessage('Could not capture the medicine label. Please try again.');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _selectImage() async {
    if (_isProcessing) return;
    if (!_supportsOnDeviceOcr) {
      _showMessage('Medicine reading is supported on Android and iOS.');
      return;
    }

    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) await _processImage(image.path);
    } catch (e) {
      debugPrint('Medicine image selection error: $e');
      _showMessage('Could not open the photo library. Please try again.');
    }
  }

  Future<void> _processImage(String path) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await _readImage(path);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _readImage(String path) async {
    final result =
        await _ocrService.analyzeImage(InputImage.fromFilePath(path));
    if (!mounted) return;
    if (result == null) {
      _showMessage(
          'No readable medicine label found. Move closer and try again.');
      return;
    }

    setState(() {
      _currentMedicine = result;
      _showResult = true;
    });
    try {
      await HistoryDB.instance.logMedicineScan(result);
    } catch (e) {
      debugPrint('Medicine scan history error: $e');
    }
  }

  void _speak() {
    final medicine = _currentMedicine;

    if (medicine == null) {
      return;
    }

    final parts = [
      if (medicine.name != null) medicine.name!,
      if (medicine.strength != null) 'Strength: ${medicine.strength}',
      if (medicine.expiryDate != null) 'Expiry: ${medicine.expiryDate}',
      medicine.dosageInstruction ?? '',
      'Always follow your prescription and healthcare professional\'s instructions.',
    ].where((value) => value.isNotEmpty).join('. ');

    FeedbackEngine.speak(parts);
    HapticFeedback.lightImpact();
  }

  void _scanAgain() {
    HapticFeedback.selectionClick();

    FeedbackEngine.stopSpeech();

    setState(() {
      _showResult = false;
      _currentMedicine = null;
    });
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
                    key: _cameraKey,
                    cameras: cameras,
                    flashControl: _flashOn,
                  )
                : const AppErrorState(
                    title: 'Camera access needed',
                    message:
                        'NaviLens uses your camera to read labels.\nPlease grant camera permission in Settings.',
                  ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _TopBar(
                title: 'Medicine Reader',
                accentColor: AppColors.medicine,
                topInset: topInset,
              ),
            ),
            if (!_showResult)
              const CameraScanOverlay(
                hint: 'Frame the label, then tap to capture',
              ),
            if (_isProcessing && !_showResult)
              Positioned(
                left: 20,
                right: 20,
                bottom: bottomInset + 124,
                child: const Center(
                  child: AppLoadingState(
                    message: 'Reading medicine label...',
                  ),
                ),
              ),
            if (!_showResult)
              Align(
                alignment: Alignment.bottomCenter,
                child: _MedicineControls(
                  flashOn: _flashOn,
                  bottomInset: bottomInset,
                  isProcessing: _isProcessing,
                  onCapture: _captureImage,
                  onGallery: _selectImage,
                ),
              ),
            if (_showResult && _currentMedicine != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: DraggableScrollableSheet(
                  initialChildSize: 0.72,
                  minChildSize: 0.48,
                  maxChildSize: 0.94,
                  snap: true,
                  snapSizes: const [
                    0.72,
                    0.94,
                  ],
                  expand: false,
                  builder: (
                    context,
                    scrollController,
                  ) {
                    return _MedicineResultPanel(
                      medicine: _currentMedicine!,
                      scrollController: scrollController,
                      onListen: _speak,
                      onScanAgain: _scanAgain,
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

class _TopBar extends StatelessWidget {
  final String title;
  final Color accentColor;
  final double topInset;

  const _TopBar({
    required this.title,
    required this.accentColor,
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
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleSmall.copyWith(
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.17),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.36),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      'LIVE',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label.copyWith(
                        color: accentColor,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicineResultPanel extends StatelessWidget {
  final MedicineInfo medicine;
  final ScrollController scrollController;
  final VoidCallback onListen;
  final VoidCallback onScanAgain;
  final double bottomInset;

  const _MedicineResultPanel({
    required this.medicine,
    required this.scrollController,
    required this.onListen,
    required this.onScanAgain,
    required this.bottomInset,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 16,
      shadowColor: Colors.black.withValues(alpha: 0.45),
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        medicine.name ?? 'Unknown Medicine',
                        style: AppTypography.headline.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (medicine.strength != null)
                  _InfoRow(
                    Icons.science_outlined,
                    'Strength',
                    medicine.strength!,
                    AppColors.medicine,
                  ),
                if (medicine.expiryDate != null) ...[
                  const SizedBox(height: 12),
                  _InfoRow(
                    Icons.calendar_today_outlined,
                    'Expiry Date',
                    medicine.expiryDate!,
                    AppColors.warning,
                  ),
                ],
                if (medicine.dosageInstruction != null) ...[
                  const SizedBox(height: 12),
                  _InfoRow(
                    Icons.info_outline_rounded,
                    'Instructions',
                    medicine.dosageInstruction!,
                    AppColors.primary,
                  ),
                ],
                const SizedBox(height: 20),
                _SafetyNotice(),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 390;

                    if (compact) {
                      return Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: onListen,
                              icon: const Icon(
                                Icons.volume_up_rounded,
                              ),
                              label: const Text('Listen'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.medicine,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: onScanAgain,
                              icon: const Icon(
                                Icons.refresh_rounded,
                              ),
                              label: const Text('Scan Again'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.medicine,
                                side: const BorderSide(
                                  color: AppColors.medicine,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onListen,
                            icon: const Icon(
                              Icons.volume_up_rounded,
                            ),
                            label: const Text('Listen'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.medicine,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onScanAgain,
                            icon: const Icon(
                              Icons.refresh_rounded,
                            ),
                            label: const Text('Scan Again'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.medicine,
                              side: const BorderSide(
                                color: AppColors.medicine,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
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

  const _InfoRow(
    this.icon,
    this.label,
    this.value,
    this.color,
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 4,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafetyNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Safety Notice',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Information extracted from the package. Always follow your prescription and healthcare professional\'s instructions.',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
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

class _MedicineControls extends StatelessWidget {
  final ValueNotifier<bool> flashOn;
  final VoidCallback onGallery;
  final VoidCallback onCapture;
  final bool isProcessing;
  final double bottomInset;

  const _MedicineControls({
    required this.flashOn,
    required this.onGallery,
    required this.onCapture,
    required this.isProcessing,
    required this.bottomInset,
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
          padding: EdgeInsets.fromLTRB(
            14,
            24,
            24,
            bottomInset + 12,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withValues(alpha: 0.84),
                Colors.black.withValues(alpha: 0.36),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
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
                  onTap: isProcessing
                      ? null
                      : () {
                          HapticFeedback.mediumImpact();
                          onCapture();
                        },
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.medicine,
                        width: 5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: 0.25,
                          ),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: isProcessing
                        ? const Padding(
                            padding: EdgeInsets.all(22),
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: AppColors.medicine,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_rounded,
                            color: AppColors.medicine,
                            size: 31,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.26),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: active ? AppColors.medicine : Colors.white,
                    size: 25,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

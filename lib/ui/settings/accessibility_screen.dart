import 'package:flutter/material.dart';
import 'package:navilens_local/accessibility/feedback_engine.dart';
import 'package:navilens_local/ui/components/app_components.dart';
import 'package:navilens_local/ui/theme/app_colors.dart';
import 'package:navilens_local/ui/theme/app_settings.dart';
import 'package:navilens_local/ui/theme/app_spacing.dart';
import 'package:navilens_local/ui/theme/app_typography.dart';

class AccessibilityScreen extends StatefulWidget {
  const AccessibilityScreen({super.key});

  @override
  State<AccessibilityScreen> createState() => _AccessibilityScreenState();
}

class _AccessibilityScreenState extends State<AccessibilityScreen> {
  void _toggle(bool Function(AppSettings) get, void Function(AppSettings, bool) set) {
    final settings = AppSettingsScope.of(context);
    set(settings, !get(settings));
    FeedbackEngine.vibrateInfo();
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Go back',
        ),
        title: const Text('Accessibility'),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary),
            onPressed: () => FeedbackEngine.speak(
              'Accessibility settings. High contrast, large text, and simple navigation.',
            ),
            tooltip: 'Speak page',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text('Make NaviLens easier to see and use.', style: AppTypography.body),
          const SizedBox(height: AppSpacing.lg),

          _A11yToggleRow(
            icon: Icons.contrast_rounded,
            color: AppColors.primary,
            title: 'High Contrast Mode',
            description: 'Stronger contrast and clearer outlines',
            value: settings.highContrast,
            onChanged: (v) => _toggle((s) => s.highContrast, (s, x) => s.highContrast = x),
          ),
          const SizedBox(height: AppSpacing.sm),
          _A11yToggleRow(
            icon: Icons.text_fields_rounded,
            color: AppColors.medicine,
            title: 'Large Text',
            description: 'Increases text size throughout the app',
            value: settings.largeText,
            onChanged: (v) => _toggle((s) => s.largeText, (s, x) => s.largeText = x),
          ),
          const SizedBox(height: AppSpacing.sm),
          _A11yToggleRow(
            icon: Icons.navigation_rounded,
            color: AppColors.environment,
            title: 'Simple Navigation',
            description: 'Shows only the most essential actions',
            value: settings.simpleNavigation,
            onChanged: (v) =>
                _toggle((s) => s.simpleNavigation, (s, x) => s.simpleNavigation = x),
          ),

          const SizedBox(height: AppSpacing.xl),
          const AppSectionHeader(title: 'PREVIEW'),
          const SizedBox(height: AppSpacing.sm),
          _buildPreview(context, settings),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildPreview(BuildContext context, AppSettings settings) {
    final highContrast = settings.highContrast;
final textColor = highContrast ? Colors.black : const Color(0xFF263238);
    final borderColor = highContrast ? AppColors.medicine : const Color(0xFFE0E0E0);
    final buttonColor = highContrast ? AppColors.primaryDark : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: borderColor, width: highContrast ? 3 : 1),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.medicine.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(Icons.medication_outlined, color: AppColors.medicine, size: 22),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('Medicine Reader', style: AppTypography.title.copyWith(color: textColor)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Scan and understand medicine labels',
            style: AppTypography.body.copyWith(color: textColor.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(Icons.contrast, size: 16, color: highContrast ? AppColors.primaryDark : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                highContrast ? 'High contrast on' : 'High contrast off',
                style: AppTypography.caption.copyWith(
                  color: highContrast ? AppColors.primaryDark : AppColors.textMuted,
                  fontWeight: highContrast ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(Icons.text_fields, size: 16, color: settings.largeText ? AppColors.medicine : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                settings.largeText ? 'Large text on' : 'Large text off',
                style: AppTypography.caption.copyWith(
                  color: settings.largeText ? AppColors.medicine : AppColors.textMuted,
                  fontWeight: settings.largeText ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => FeedbackEngine.speak(
                'Preview button. This shows how accessibility settings look.',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: const Text('Open feature'),
            ),
          ),
        ],
      ),
    );
  }
}
class _A11yToggleRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _A11yToggleRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: '$title: ${value ? 'On' : 'Off'}, $description',
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.titleSmall),
                  const SizedBox(height: 2),
                  Text(description, style: AppTypography.body),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: color,
            ),
          ],
        ),
      ),
    );
  }
}
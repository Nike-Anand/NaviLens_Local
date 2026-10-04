import 'package:flutter/material.dart';
import 'package:navilens_local/accessibility/feedback_engine.dart';
import 'package:navilens_local/data/history_db.dart';
import 'package:navilens_local/ui/components/app_components.dart';
import 'package:navilens_local/ui/settings/accessibility_screen.dart';
import 'package:navilens_local/ui/theme/app_colors.dart';
import 'package:navilens_local/ui/theme/app_settings.dart';
import 'package:navilens_local/ui/theme/app_spacing.dart';
import 'package:navilens_local/ui/theme/app_typography.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _voiceEnabled = true;
  bool _voiceOnTap = true;
  bool _exerciseAlerts = true;
  int _repTarget = 10;

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        title: const Text('Clear History', style: AppTypography.title),
        content: const Text(
          'This will permanently delete all your scan and exercise records.',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final db = await HistoryDB.instance.database;
        await db.delete('medicine_scans');
        await db.delete('exercise_sessions');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('History cleared.'),
              backgroundColor: AppColors.surface,
            ),
          );
        }
      } catch (_) {}
    }
  }

  Future<void> _chooseRepTarget() async {
    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Target Repetitions', style: AppTypography.title),
        children: [3, 5, 8, 10, 12, 15]
            .map(
              (r) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, r),
                child: Text('$r reps', style: AppTypography.title),
              ),
            )
            .toList(),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _repTarget = selected);
    }
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
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const AppSectionHeader(title: 'VOICE SETTINGS'),
            const SizedBox(height: AppSpacing.sm),
            _SettingToggleRow(
              icon: Icons.record_voice_over,
              color: AppColors.primary,
              title: 'Voice Feedback',
              description: 'Speaks results aloud',
              value: _voiceEnabled,
              onChanged: (v) {
                setState(() => _voiceEnabled = v);
                if (v) FeedbackEngine.speak('Voice feedback on');
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _SettingToggleRow(
              icon: Icons.touch_app,
              color: AppColors.primary,
              title: 'Speak on Tap',
              description: 'Reads items when tapped',
              value: _voiceOnTap,
              onChanged: (v) => setState(() => _voiceOnTap = v),
            ),

            const SizedBox(height: AppSpacing.lg),
            const AppSectionHeader(title: 'ACCESSIBILITY'),
            const SizedBox(height: AppSpacing.sm),
            SettingsRow(
              icon: Icons.accessible_rounded,
              iconColor: AppColors.primary,
              title: 'Accessibility',
              description: settings.highContrast
                  ? 'High contrast on · Large text ${settings.largeText ? "on" : "off"}'
                  : 'High contrast, large text, navigation',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AccessibilityScreen()),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            const AppSectionHeader(title: 'EXERCISE SETTINGS'),
            const SizedBox(height: AppSpacing.sm),
            _SettingToggleRow(
              icon: Icons.notifications_active_outlined,
              color: AppColors.physio,
              title: 'Exercise Alerts',
              description: 'Voice and haptic coaching alerts',
              value: _exerciseAlerts,
              onChanged: (v) => setState(() => _exerciseAlerts = v),
            ),
            const SizedBox(height: AppSpacing.sm),
            SettingsRow(
              icon: Icons.repeat_rounded,
              iconColor: AppColors.physio,
              title: 'Target Repetitions',
              description: 'Goal of $_repTarget reps per session',
              onTap: _chooseRepTarget,
            ),

            const SizedBox(height: AppSpacing.lg),
            const AppSectionHeader(title: 'OFFLINE MODE'),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.environment.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(Icons.offline_bolt_rounded, color: AppColors.environment, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Offline Mode', style: AppTypography.titleSmall),
                        SizedBox(height: 2),
                        Text(
                          'All AI runs on-device. No internet required.',
                          style: AppTypography.body,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.physio.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: AppColors.physio, size: 16),
                        SizedBox(width: 4),
                        Text('Active', style: TextStyle(color: AppColors.physio)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
            const AppSectionHeader(title: 'DATA MANAGEMENT'),
            const SizedBox(height: AppSpacing.sm),
            SettingsRow(
              icon: Icons.delete_outline,
              iconColor: AppColors.error,
              title: 'Clear History',
              description: 'Delete all scan and exercise records',
              onTap: _clearHistory,
            ),

            const SizedBox(height: AppSpacing.lg),
            const AppSectionHeader(title: 'ABOUT'),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('NaviLens Local', style: AppTypography.titleSmall),
                  SizedBox(height: 4),
                  Text(
                    'An offline-first AI assistant for medicine reading, exercise guidance, and environment awareness.',
                    style: AppTypography.body,
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Powered by Google ML Kit · On-device inference only',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _SettingToggleRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingToggleRow({
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
            Switch(value: value, onChanged: onChanged, activeThumbColor: color),
          ],
        ),
      ),
    );
  }
}
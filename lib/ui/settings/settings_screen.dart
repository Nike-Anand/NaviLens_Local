import 'package:flutter/material.dart';

import 'package:navilens_local/accessibility/feedback_engine.dart';
import 'package:navilens_local/data/history_db.dart';
import 'package:navilens_local/ui/components/app_components.dart';
import 'package:navilens_local/ui/settings/accessibility_screen.dart';
import 'package:navilens_local/ui/theme/app_colors.dart';
import 'package:navilens_local/ui/theme/app_settings.dart';
import 'package:navilens_local/ui/theme/app_spacing.dart';
import 'package:navilens_local/ui/theme/app_typography.dart';
import 'package:navilens_local/ui/theme/responsive.dart';

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
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Clear History',
            style: AppTypography.title,
          ),
          content: const Text(
            'This will permanently delete all your scan and exercise records.',
            style: AppTypography.body,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx, true);
              },
              child: const Text(
                'Clear All',
                style: TextStyle(
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) {
      return;
    }

    try {
      final db = await HistoryDB.instance.database;

      await db.delete('medicine_scans');
      await db.delete('exercise_sessions');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('History cleared.'),
        ),
      );
    } catch (e) {
      debugPrint('Error clearing history: $e');
    }
  }

  Future<void> _chooseRepTarget() async {
    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Target Repetitions',
            style: AppTypography.title,
          ),
          children: [
            for (final reps in [3, 5, 8, 10, 12, 15])
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(ctx, reps);
                },
                child: Text(
                  '$reps reps',
                  style: AppTypography.title,
                ),
              ),
          ],
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _repTarget = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Go back',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
          ),
        ),
        title: const Text(
          'Settings',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.maxContentWidth(
                context,
              ),
            ),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                Responsive.horizontalPadding(context),
                8,
                Responsive.horizontalPadding(context),
                28,
              ),
              children: [
                const AppSectionHeader(
                  title: 'VOICE SETTINGS',
                ),

                const SizedBox(height: 10),

                _SettingToggleRow(
                  icon: Icons.record_voice_over_rounded,
                  color: AppColors.primary,
                  title: 'Voice Feedback',
                  description: 'Speaks results aloud',
                  value: _voiceEnabled,
                  onChanged: (value) {
                    setState(() {
                      _voiceEnabled = value;
                    });

                    if (value) {
                      FeedbackEngine.speak(
                        'Voice feedback on',
                      );
                    }
                  },
                ),

                const SizedBox(height: 10),

                _SettingToggleRow(
                  icon: Icons.touch_app_rounded,
                  color: AppColors.primary,
                  title: 'Speak on Tap',
                  description: 'Reads items when tapped',
                  value: _voiceOnTap,
                  onChanged: (value) {
                    setState(() {
                      _voiceOnTap = value;
                    });
                  },
                ),

                const SizedBox(height: 24),

                const AppSectionHeader(
                  title: 'ACCESSIBILITY',
                ),

                const SizedBox(height: 10),

                SettingsRow(
                  icon: Icons.accessible_rounded,
                  iconColor: AppColors.primary,
                  title: 'Accessibility',
                  description: settings.highContrast
                      ? 'High contrast on · Large text ${settings.largeText ? "on" : "off"}'
                      : 'High contrast, large text, navigation',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const AccessibilityScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                const AppSectionHeader(
                  title: 'EXERCISE SETTINGS',
                ),

                const SizedBox(height: 10),

                _SettingToggleRow(
                  icon:
                      Icons.notifications_active_outlined,
                  color: AppColors.physio,
                  title: 'Exercise Alerts',
                  description:
                      'Voice and haptic coaching alerts',
                  value: _exerciseAlerts,
                  onChanged: (value) {
                    setState(() {
                      _exerciseAlerts = value;
                    });
                  },
                ),

                const SizedBox(height: 10),

                SettingsRow(
                  icon: Icons.repeat_rounded,
                  iconColor: AppColors.physio,
                  title: 'Target Repetitions',
                  description:
                      'Goal of $_repTarget reps per session',
                  onTap: _chooseRepTarget,
                ),

                const SizedBox(height: 24),

                const AppSectionHeader(
                  title: 'OFFLINE MODE',
                ),

                const SizedBox(height: 10),

                const _OfflineSettingsCard(),

                const SizedBox(height: 24),

                const AppSectionHeader(
                  title: 'DATA MANAGEMENT',
                ),

                const SizedBox(height: 10),

                SettingsRow(
                  icon: Icons.delete_outline_rounded,
                  iconColor: AppColors.error,
                  title: 'Clear History',
                  description:
                      'Delete all scan and exercise records',
                  onTap: _clearHistory,
                ),

                const SizedBox(height: 24),

                const AppSectionHeader(
                  title: 'ABOUT',
                ),

                const SizedBox(height: 10),

                const AppCard(
                  padding: EdgeInsets.all(
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NaviLens Local',
                        style: AppTypography.titleSmall,
                      ),
                      SizedBox(height: 6),
                      Text(
                        'An offline-first AI assistant for medicine reading, exercise guidance, and environment awareness.',
                        style: AppTypography.body,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Powered by Google ML Kit · On-device inference only',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OfflineSettingsCard extends StatelessWidget {
  const _OfflineSettingsCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.environment.withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.offline_bolt_rounded,
              color: AppColors.environment,
              size: 24,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Offline Mode',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSmall,
                ),
                const SizedBox(height: 3),
                Text(
                  'All AI runs on-device. No internet required.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.physio.withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(
                999,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.physio,
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  'Active',
                  style: TextStyle(
                    color: AppColors.physio,
                    fontWeight: FontWeight.w600,
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
      label:
          '$title: ${value ? 'On' : 'Off'}, $description',
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: color,
                size: 23,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleSmall,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

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
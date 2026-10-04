import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:navilens_local/ui/medicine/medicine_screen.dart';
import 'package:navilens_local/ui/physio/physio_screen.dart';
import 'package:navilens_local/ui/environment/environment_screen.dart';
import 'package:navilens_local/ui/history/history_screen.dart';
import 'package:navilens_local/ui/settings/settings_screen.dart';
import 'package:navilens_local/ui/theme/app_colors.dart';
import 'package:navilens_local/ui/theme/app_typography.dart';
import 'package:navilens_local/ui/theme/app_spacing.dart';
import 'package:navilens_local/ui/components/app_components.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: const Padding(
          padding: EdgeInsets.only(left: AppSpacing.md),
          child: Center(
            child: NaviLensLogo(size: 44, iconSize: 26),
          ),
        ),
        titleSpacing: 0,
        title: const Text(
          'NaviLens Local',
          style: AppTypography.title,
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              _slideRoute(const SettingsScreen()),
            ),
            icon: const Icon(Icons.settings_rounded, color: AppColors.textPrimary),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: AppSpacing.sm),
                  Text('What do you need help with?', style: AppTypography.body),
                  const SizedBox(height: AppSpacing.md),

                  _FeatureCard(
                    icon: Icons.medication_outlined,
                    title: 'Medicine Reader',
                    subtitle: 'Scan and understand\nmedicine labels',
                    color: AppColors.medicine,
                    semanticHint: 'Opens camera to scan medicine labels',
                    onTap: () => Navigator.push(
                      context,
                      _slideRoute(const MedicineScreen()),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  _FeatureCard(
                    icon: Icons.directions_run,
                    title: 'Physio Coach',
                    subtitle: 'Get real-time\nposture feedback',
                    color: AppColors.physio,
                    semanticHint: 'Opens camera for exercise coaching',
                    onTap: () => Navigator.push(
                      context,
                      _slideRoute(const PhysioScreen()),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  _FeatureCard(
                    icon: Icons.near_me_outlined,
                    title: 'Environment\nAssistant',
                    subtitle: 'Detect and describe\nobjects around you',
                    color: AppColors.environment,
                    semanticHint: 'Opens camera to identify surroundings',
                    onTap: () => Navigator.push(
                      context,
                      _slideRoute(const EnvironmentScreen()),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),
                  const _OfflineBanner(),
                  const SizedBox(height: AppSpacing.xl),

                  const AppSectionHeader(title: 'MORE'),
                  const SizedBox(height: AppSpacing.sm),
                  LightCard(
                    semanticsLabel: 'Open history',
                    onTap: () => Navigator.push(
                      context,
                      _slideRoute(const HistoryScreen()),
                    ),
                    child: const _SecondaryRow(
                      icon: Icons.history_rounded,
                      color: AppColors.primary,
                      title: 'History',
                      subtitle: 'Your past scans and exercises',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  LightCard(
                    semanticsLabel: 'Open settings',
                    onTap: () => Navigator.push(
                      context,
                      _slideRoute(const SettingsScreen()),
                    ),
                    child: const _SecondaryRow(
                      icon: Icons.settings_rounded,
                      color: AppColors.primary,
                      title: 'Settings',
                      subtitle: 'Voice, accessibility and more',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PageRouteBuilder _slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
// ─────────────────────────────────────────────
// Feature Card
// ─────────────────────────────────────────────
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String semanticHint;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.semanticHint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      hint: semanticHint,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          splashColor: Colors.white.withValues(alpha: 0.15),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.35),
                  color.withValues(alpha: 0.18),
                ],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(icon, color: Colors.white, size: 36),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.title),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTypography.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Offline banner
// ─────────────────────────────────────────────
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.physio.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.physio.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.offline_bolt_rounded, color: AppColors.physio, size: 22),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Works fully offline. Your data stays on your device.',
              style: AppTypography.body,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Secondary row (used inside light cards)
// ─────────────────────────────────────────────
class _SecondaryRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _SecondaryRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
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
              Text(
                title,
                style: AppTypography.titleSmall.copyWith(color: const Color(0xFF1F2933)),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.body.copyWith(
                  color: const Color(0xFF52606D),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: Color(0xFF9AA5B1), size: 26),
      ],
    );
  }
}
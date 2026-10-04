import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:navilens_local/ui/environment/environment_screen.dart';
import 'package:navilens_local/ui/medicine/medicine_screen.dart';
import 'package:navilens_local/ui/physio/physio_screen.dart';
import 'package:navilens_local/ui/settings/settings_screen.dart';

import '../components/app_components.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/responsive.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeScreenContent();
  }
}

class HomeScreenContent extends StatelessWidget {
  const HomeScreenContent({super.key});

  void _open(
    BuildContext context,
    Widget page,
  ) {
    HapticFeedback.lightImpact();

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration:
            const Duration(milliseconds: 220),
        transitionsBuilder: (_, animation, __, child) {
          final curve = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curve,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.025, 0),
                end: Offset.zero,
              ).animate(curve),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontal =
        Responsive.horizontalPadding(context);

    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.maxContentWidth(context),
            ),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontal,
                    10,
                    horizontal,
                    24,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildTopBar(context),

                      const SizedBox(height: 18),

                      _buildGreeting(),

                      const SizedBox(height: 18),

                      _buildCommandBar(),

                      const SizedBox(height: 24),

                      _buildSectionTitle(
                        'QUICK ACTIONS',
                        'Start something',
                      ),

                      const SizedBox(height: 12),

                      _buildQuickActions(context),

                      const SizedBox(height: 28),

                      _buildSectionTitle(
                        'RECENT ACTIVITY',
                        'Today',
                      ),

                      const SizedBox(height: 12),

                      _RecentActivityCard(
                        icon: Icons.medication_rounded,
                        color: AppColors.medicine,
                        title: 'Amlodipine 5 mg',
                        subtitle: 'Medicine scanned',
                        time: '10:32 AM',
                        onTap: () => _open(
                          context,
                          const MedicineScreen(),
                        ),
                      ),

                      const SizedBox(height: 10),

                      _RecentActivityCard(
                        icon: Icons.accessibility_new_rounded,
                        color: AppColors.physio,
                        title: 'Squat Exercise',
                        subtitle: '10 reps • Good Form',
                        time: '10:15 AM',
                        onTap: () => _open(
                          context,
                          const PhysioScreen(),
                        ),
                      ),

                      const SizedBox(height: 10),

                      _RecentActivityCard(
                        icon: Icons.chair_rounded,
                        color: AppColors.environment,
                        title: 'Chair',
                        subtitle: 'Detected in Living Room',
                        time: '09:50 AM',
                        onTap: () => _open(
                          context,
                          const EnvironmentScreen(),
                        ),
                      ),

                      const SizedBox(height: 26),

                      _buildTipCard(),

                      const SizedBox(height: 18),

                      _buildOfflineStatus(),

                      const SizedBox(height: 10),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        const NaviLensLogo(
          size: 46,
          iconSize: 27,
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NaviLens Local',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.title.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Private • On-device AI',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        _HeaderIcon(
          icon: Icons.notifications_none_rounded,
          semanticLabel: 'Notifications',
          onTap: () {},
        ),

        const SizedBox(width: 6),

        _HeaderIcon(
          icon: Icons.settings_rounded,
          semanticLabel: 'Settings',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SettingsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good evening',
          style: AppTypography.headline.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'What can NaviLens help you with?',
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCommandBar() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),

          const Icon(
            Icons.search_rounded,
            color: AppColors.textMuted,
            size: 23,
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Text(
              'What do you need help with?',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),

          Container(
            margin: const EdgeInsets.only(right: 8),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.mic_none_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.medication_outlined,
                color: AppColors.medicine,
                title: 'Medicine',
                subtitle: 'Read labels',
                onTap: () => _open(
                  context,
                  const MedicineScreen(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.accessibility_new_rounded,
                color: AppColors.physio,
                title: 'Physio',
                subtitle: 'Coach exercise',
                onTap: () => _open(
                  context,
                  const PhysioScreen(),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        _EnvironmentActionCard(
          onTap: () => _open(
            context,
            const EnvironmentScreen(),
          ),
        ),
      ],
    );
  }

  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.medicine.withValues(alpha: 0.07),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(
                alpha: 0.12,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QUICK TIP',
                  style: AppTypography.label.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Keep medicine labels flat and well lit for clearer scanning.',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.physio.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.physio.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.physio.withValues(
                alpha: 0.12,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.physio,
              size: 17,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              'Everything is running locally on your device.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
          ),

          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: AppColors.physio.withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'ACTIVE',
              style: AppTypography.label.copyWith(
                color: AppColors.physio,
                fontSize: 9,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    String trailing,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTypography.label.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 1.4,
            ),
          ),
        ),
        Text(
          trailing,
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  const _HeaderIcon({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: Icon(
              icon,
              color: AppColors.textPrimary,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: 150,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withValues(alpha: 0.22),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 25,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSmall,
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
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

class _EnvironmentActionCard extends StatelessWidget {
  final VoidCallback onTap;

  const _EnvironmentActionCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          'Environment Assistant. Detect and describe objects around you',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.environment.withValues(
                alpha: 0.09,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.environment.withValues(
                  alpha: 0.22,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.environment.withValues(
                      alpha: 0.14,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.visibility_outlined,
                    color: AppColors.environment,
                    size: 27,
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Environment Assistant',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSmall,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Detect and describe objects around you',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.environment.withValues(
                      alpha: 0.12,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.environment,
                    size: 14,
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

class _RecentActivityCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;
  final VoidCallback onTap;

  const _RecentActivityCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle. $time',
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE7EBEF),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 23,
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSmall.copyWith(
                          color: const Color(0xFF17202A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: const Color(0xFF66727E),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      time,
                      style: AppTypography.caption.copyWith(
                        color: const Color(0xFF8B96A1),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF9CA6AF),
                      size: 23,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:navilens_local/data/history_db.dart';
import 'package:navilens_local/ui/theme/app_colors.dart';
import 'package:navilens_local/ui/theme/app_typography.dart';
import 'package:navilens_local/ui/theme/app_spacing.dart';
import 'package:navilens_local/ui/components/app_components.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _filterIndex = 0;
  List<Map<String, dynamic>> _medicineScans = [];
  List<Map<String, dynamic>> _exerciseSessions = [];
  bool _isLoading = true;

  static const List<String> _filters = ['All', 'Medicine', 'Exercises'];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final db = await HistoryDB.instance.database;
      final meds = await db.query('medicine_scans', orderBy: 'timestamp DESC', limit: 50);
      final exs = await db.query('exercise_sessions', orderBy: 'timestamp DESC', limit: 50);
      if (mounted) {
        setState(() {
          _medicineScans = meds;
          _exerciseSessions = exs;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<_HistoryItem> get _filteredItems {
    final allItems = <_HistoryItem>[];

    if (_filterIndex == 0 || _filterIndex == 1) {
      for (final scan in _medicineScans) {
        allItems.add(_HistoryItem(
          type: 'medicine',
          title: scan['name'] as String? ?? 'Unknown Medicine',
          subtitle: _formatMedicineSubtitle(scan),
          timestamp: _parseTimestamp(scan['timestamp'] as String?),
        ));
      }
    }

    if (_filterIndex == 0 || _filterIndex == 2) {
      for (final session in _exerciseSessions) {
        allItems.add(_HistoryItem(
          type: 'exercise',
          title: session['exerciseName'] as String? ?? 'Exercise',
          subtitle: '${session['repetitions']} reps · ${_formatDuration(session['durationSeconds'] as int? ?? 0)}',
          timestamp: _parseTimestamp(session['timestamp'] as String?),
        ));
      }
    }

    allItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return allItems;
  }

  String _formatMedicineSubtitle(Map<String, dynamic> scan) {
    final strength = scan['strength'] as String?;
    final expiry = scan['expiry'] as String?;
    final parts = <String>[];
    if (strength != null) parts.add(strength);
    if (expiry != null) parts.add('Exp: $expiry');
    return parts.isEmpty ? 'Scanned' : parts.join(' · ');
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    return '${seconds ~/ 60}m ${seconds % 60}s';
  }

  DateTime _parseTimestamp(String? ts) {
    if (ts == null) return DateTime.now();
    try {
      return DateTime.parse(ts);
    } catch (_) {
      return DateTime.now();
    }
  }

  String _formatRelativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today · ${_formatTime(dt)}';
    if (diff.inDays == 1) return 'Yesterday · ${_formatTime(dt)}';
    return '${diff.inDays} days ago · ${_formatTime(dt)}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildFilters(),
          const SizedBox(height: AppSpacing.sm),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.md, AppSpacing.md, 0,
      ),
      child: Row(
        children: [
          const Expanded(child: Text('History', style: AppTypography.headline)),
          Semantics(
            button: true,
            label: 'Refresh history',
            child: AppIconButton(
              icon: Icons.refresh_rounded,
              semanticsLabel: 'Refresh',
              color: AppColors.surface,
              iconColor: AppColors.textSecondary,
              onTap: _loadHistory,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Semantics(
            button: true,
            label: 'Delete all history',
            child: AppIconButton(
              icon: Icons.delete_outline_rounded,
              semanticsLabel: 'Delete',
              color: AppColors.surface,
              iconColor: AppColors.error,
              onTap: _confirmClearHistory,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Clear history?'),
        content: const Text(
          'This permanently deletes all medicine scans and exercise sessions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.mediumImpact();
      try {
        final db = await HistoryDB.instance.database;
        await db.delete('medicine_scans');
        await db.delete('exercise_sessions');
      } catch (_) {
        // Fall through and reload regardless.
      }
      await _loadHistory();
    }
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.md, AppSpacing.md, 0,
      ),
      child: Row(
        children: List.generate(_filters.length, (i) {
          final isActive = _filterIndex == i;
          return Padding(
            padding: EdgeInsets.only(right: i < _filters.length - 1 ? AppSpacing.sm : 0),
            child: Semantics(
              button: true,
              selected: isActive,
              label: '${_filters[i]} filter',
              child: GestureDetector(
                onTap: () => setState(() => _filterIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    border: Border.all(
                      color: isActive ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    _filters[i],
                    style: AppTypography.label.copyWith(
                      color: isActive ? Colors.white : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const AppLoadingState(message: 'Loading history...');
    }

    final items = _filteredItems;

    if (items.isEmpty) {
      return AppEmptyState(
        icon: Icons.history_rounded,
        title: 'No activity yet',
        subtitle: 'Your medicine scans and exercise\nsessions will appear here.',
        action: AppButton(
          label: 'Refresh',
          icon: Icons.refresh_rounded,
          color: AppColors.primary,
          onTap: _loadHistory,
          isOutlined: true,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) => _HistoryCard(
        item: items[i],
        relativeTime: _formatRelativeTime(items[i].timestamp),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// History Item Model
// ─────────────────────────────────────────────
class _HistoryItem {
  final String type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  const _HistoryItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
  });
}

// ─────────────────────────────────────────────
// History Card
// ─────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final _HistoryItem item;
  final String relativeTime;

  const _HistoryCard({required this.item, required this.relativeTime});

  @override
  Widget build(BuildContext context) {
    final isMedicine = item.type == 'medicine';
    final color = isMedicine ? AppColors.medicine : AppColors.physio;
    final icon = isMedicine ? Icons.medication_outlined : Icons.accessibility_new;

    return Semantics(
      label: '${item.title}, ${item.subtitle}, $relativeTime',
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: AppTypography.titleSmall),
                  const SizedBox(height: 2),
                  Text(item.subtitle, style: AppTypography.body),
                  const SizedBox(height: 4),
                  Text(relativeTime, style: AppTypography.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

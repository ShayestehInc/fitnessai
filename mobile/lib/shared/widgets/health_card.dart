import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/health_metrics.dart';
import '../../core/providers/health_provider.dart';
import '../../core/services/health_service.dart';

/// Displays today's health metrics (steps, active calories, heart rate, weight)
/// from HealthKit / Health Connect.
///
/// Shows a skeleton loading state while data is fetching, hides entirely
/// when permissions are denied or the platform is unsupported.
class TodaysHealthCard extends ConsumerWidget {
  const TodaysHealthCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthState = ref.watch(healthDataProvider);

    return switch (healthState) {
      HealthDataLoading() => const _SkeletonHealthCard(),
      HealthDataLoaded(metrics: final metrics) =>
        _LoadedHealthCard(metrics: metrics),
      // Hide card for all other states (initial, denied, unavailable)
      _ => const SizedBox.shrink(),
    };
  }
}

/// The populated health card showing 4 metric tiles.
class _LoadedHealthCard extends StatefulWidget {
  final HealthMetrics metrics;

  const _LoadedHealthCard({required this.metrics});

  @override
  State<_LoadedHealthCard> createState() => _LoadedHealthCardState();
}

class _LoadedHealthCardState extends State<_LoadedHealthCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numberFormat = NumberFormat('#,###');

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and settings gear
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Health",
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Open health settings',
                  child: GestureDetector(
                    onTap: _openHealthSettings,
                    child: Icon(
                      Icons.settings_outlined,
                      size: 18,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 2x2 metric grid
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    icon: Icons.directions_walk,
                    iconColor: const Color(0xFF22C55E),
                    label: 'Steps',
                    value: numberFormat.format(widget.metrics.steps),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.local_fire_department,
                    iconColor: const Color(0xFFEF4444),
                    label: 'Active Cal',
                    value:
                        '${numberFormat.format(widget.metrics.activeCalories)} cal',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    icon: Icons.favorite,
                    iconColor: const Color(0xFFEC4899),
                    label: 'Heart Rate',
                    value: widget.metrics.heartRate != null
                        ? '${widget.metrics.heartRate} bpm'
                        : '--',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.monitor_weight_outlined,
                    iconColor: const Color(0xFF3B82F6),
                    label: 'Weight',
                    value: widget.metrics.latestWeightKg != null
                        ? '${widget.metrics.latestWeightKg!.toStringAsFixed(1)} kg'
                        : '--',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openHealthSettings() async {
    final uri = Uri.parse(HealthService.healthSettingsUri);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Silently fail -- user can open manually
    }
  }
}

/// A single metric tile inside the health card.
class _MetricTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _MetricTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton shimmer placeholder matching the health card layout.
class _SkeletonHealthCard extends StatelessWidget {
  const _SkeletonHealthCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          Container(
            width: 100,
            height: 12,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          // 2x2 skeleton grid
          Row(
            children: [
              Expanded(child: _SkeletonTile(theme: theme)),
              const SizedBox(width: 12),
              Expanded(child: _SkeletonTile(theme: theme)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _SkeletonTile(theme: theme)),
              const SizedBox(width: 12),
              Expanded(child: _SkeletonTile(theme: theme)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonTile extends StatelessWidget {
  final ThemeData theme;

  const _SkeletonTile({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 60,
                  height: 12,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(4),
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

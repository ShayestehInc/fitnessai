import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/health_provider.dart';
import '../../../../core/theme/app_theme.dart';
import 'dashboard_section_header.dart';

/// Weight log section with latest entry, trend indicator, and "Weight In" CTA.
class WeightLogCard extends ConsumerWidget {
  const WeightLogCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthState = ref.watch(healthDataProvider);
    final metrics = healthState is HealthDataLoaded ? healthState.metrics : null;

    final weightKg = metrics?.latestWeightKg;
    final weightDate = metrics?.weightDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardSectionHeader(
          title: 'Weight Log',
          actionLabel: 'View All',
          onAction: () => context.push('/weight-trends'),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: weightKg != null
              ? _buildWithData(context, weightKg, weightDate)
              : _buildEmpty(context),
        ),
      ],
    );
  }

  Widget _buildWithData(
    BuildContext context,
    double weightKg,
    DateTime? weightDate,
  ) {
    // Convert to lbs (default for US-centric user base)
    final weightLbs = weightKg * 2.205;
    final dateStr = weightDate != null
        ? DateFormat('MMM d, yyyy \'at\' h:mm a').format(weightDate)
        : '';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${weightLbs.toStringAsFixed(1)} lbs',
                    style: const TextStyle(
                      color: AppTheme.foreground,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.trending_flat,
                    color: AppTheme.zinc500,
                    size: 20,
                  ),
                ],
              ),
              if (dateStr.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: AppTheme.mutedForeground,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        _WeightInButton(),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No weight logged yet',
                style: TextStyle(
                  color: AppTheme.mutedForeground,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Track your progress',
                style: TextStyle(
                  color: AppTheme.zinc500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        _WeightInButton(),
      ],
    );
  }
}

class _WeightInButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => context.push('/weight-checkin'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text(
        'Weight In',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}

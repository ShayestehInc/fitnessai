import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/progression_models.dart';

class DeloadRecommendationCard extends StatelessWidget {
  final DeloadRecommendationModel recommendation;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;
  final bool isLoading;

  const DeloadRecommendationCard({
    super.key,
    required this.recommendation,
    required this.onAccept,
    required this.onDismiss,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: recommendation.needsDeload
              ? const Color(0xFFF59E0B).withOpacity(0.5)
              : AppTheme.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 16),
            _buildConfidenceIndicator(theme),
            const SizedBox(height: 16),
            _buildModifiers(theme),
            if (recommendation.rationale.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildRationale(theme),
            ],
            if (recommendation.needsDeload) ...[
              const SizedBox(height: 16),
              _buildActions(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: recommendation.needsDeload
                ? const Color(0xFFF59E0B).withOpacity(0.15)
                : const Color(0xFF22C55E).withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            recommendation.needsDeload
                ? Icons.trending_down
                : Icons.check_circle_outline,
            color: recommendation.needsDeload
                ? const Color(0xFFF59E0B)
                : const Color(0xFF22C55E),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recommendation.needsDeload
                    ? 'Deload Recommended'
                    : 'No Deload Needed',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 2),
              Text(
                recommendation.needsDeload
                    ? 'Your body may need a recovery period'
                    : 'Keep pushing — recovery looks good',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceIndicator(ThemeData theme) {
    final confidencePercent = (recommendation.confidence * 100).round();
    final Color barColor;
    if (recommendation.confidence >= 0.8) {
      barColor = const Color(0xFFEF4444);
    } else if (recommendation.confidence >= 0.5) {
      barColor = const Color(0xFFF59E0B);
    } else {
      barColor = const Color(0xFF22C55E);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Confidence',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppTheme.mutedForeground,
              ),
            ),
            Text(
              '$confidencePercent%',
              style: theme.textTheme.titleMedium?.copyWith(
                color: barColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: recommendation.confidence,
            backgroundColor: AppTheme.zinc700,
            color: barColor,
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildModifiers(ThemeData theme) {
    final intensityPercent =
        (recommendation.suggestedIntensityModifier * 100).round();
    final volumePercent =
        (recommendation.suggestedVolumeModifier * 100).round();

    return Row(
      children: [
        Expanded(
          child: _buildModifierTile(
            theme,
            label: 'Intensity',
            value: '$intensityPercent%',
            icon: Icons.speed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildModifierTile(
            theme,
            label: 'Volume',
            value: '$volumePercent%',
            icon: Icons.bar_chart,
          ),
        ),
      ],
    );
  }

  Widget _buildModifierTile(
    ThemeData theme, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.zinc900,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.mutedForeground, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRationale(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: AppTheme.primary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              recommendation.rationale,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.zinc300,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isLoading ? null : onDismiss,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.mutedForeground,
              side: const BorderSide(color: AppTheme.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Dismiss'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : onAccept,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Accept Deload'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

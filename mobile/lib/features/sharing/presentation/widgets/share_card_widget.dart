import 'package:flutter/material.dart';
import '../../data/models/share_card_model.dart';

/// A beautiful branded workout summary card designed for social sharing.
///
/// Wrapped in a [RepaintBoundary] so that the parent can capture it
/// as an image via [RenderRepaintBoundary.toImage].
class ShareCardWidget extends StatelessWidget {
  final ShareCardModel shareCard;
  final GlobalKey repaintKey;

  const ShareCardWidget({
    super.key,
    required this.shareCard,
    required this.repaintKey,
  });

  Color _parseBrandColor(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    final cleaned = hex.replaceFirst('#', '');
    if (cleaned.length != 6) return fallback;
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return fallback;
    return Color(0xFF000000 | value);
  }

  @override
  Widget build(BuildContext context) {
    final branding = shareCard.trainerBranding;
    final brandPrimary = _parseBrandColor(
      branding.primaryColor,
      Theme.of(context).colorScheme.primary,
    );
    final brandSecondary = _parseBrandColor(
      branding.secondaryColor,
      brandPrimary.withValues(alpha: 0.7),
    );

    return RepaintBoundary(
      key: repaintKey,
      child: Container(
        width: 380,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [brandPrimary, brandSecondary],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: brandPrimary.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(branding),
              const SizedBox(height: 20),
              _buildWorkoutTitle(),
              const SizedBox(height: 16),
              _buildStatsRow(),
              const SizedBox(height: 20),
              _buildExerciseList(),
              const SizedBox(height: 20),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(TrainerBranding branding) {
    return Row(
      children: [
        if (branding.logoUrl != null && branding.logoUrl!.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              branding.logoUrl!,
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(width: 10),
        ],
        if (branding.businessName != null &&
            branding.businessName!.isNotEmpty)
          Expanded(
            child: Text(
              branding.businessName!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        const Spacer(),
        Text(
          shareCard.date,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          shareCard.workoutName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          shareCard.traineeName,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.fitness_center,
            value: '${shareCard.exerciseCount}',
            label: 'Exercises',
          ),
          _StatDivider(),
          _StatItem(
            icon: Icons.layers,
            value: '${shareCard.totalSets}',
            label: 'Sets',
          ),
          _StatDivider(),
          _StatItem(
            icon: Icons.monitor_weight_outlined,
            value: shareCard.volumeDisplay,
            label: 'Volume',
          ),
          if (shareCard.duration.isNotEmpty) ...[
            _StatDivider(),
            _StatItem(
              icon: Icons.timer_outlined,
              value: shareCard.duration,
              label: 'Duration',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExerciseList() {
    final exercisesToShow = shareCard.exercises.take(6).toList();
    final remaining = shareCard.exercises.length - exercisesToShow.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...exercisesToShow.map((exercise) => _ExerciseRow(exercise: exercise)),
        if (remaining > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '+$remaining more exercises',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.bolt,
          color: Colors.white.withValues(alpha: 0.5),
          size: 14,
        ),
        const SizedBox(width: 4),
        Text(
          'Powered by FitnessAI',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final ShareCardExercise exercise;

  const _ExerciseRow({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final weightText = exercise.weight != null && exercise.weight! > 0
        ? ' @ ${exercise.weight!.toStringAsFixed(0)}${exercise.weightUnit ?? 'lbs'}'
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.white54,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              exercise.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${exercise.sets}x${exercise.reps}$weightText',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

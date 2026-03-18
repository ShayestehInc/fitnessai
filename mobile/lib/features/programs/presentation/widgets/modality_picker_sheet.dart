import 'package:flutter/material.dart';

/// Bottom sheet for selecting a set structure modality per exercise.
/// Grouped by category with icons, descriptions, and use-case hints.
class ModalityPickerSheet extends StatelessWidget {
  final String? currentModality;
  final ValueChanged<String> onSelected;

  const ModalityPickerSheet({
    super.key,
    this.currentModality,
    required this.onSelected,
  });

  static Future<String?> show(BuildContext context, {String? current}) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => ModalityPickerSheet(
          currentModality: current,
          onSelected: (modality) => Navigator.pop(ctx, modality),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Handle
        Center(
          child: Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Set Structure', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Choose how sets are structured for this exercise',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildCategory(theme, 'Standard', [
                _ModalityOption('straight_sets', 'Straight Sets', 'Same weight & reps each set', Icons.horizontal_rule, Colors.blueGrey),
              ]),
              _buildCategory(theme, 'Intensity Techniques', [
                _ModalityOption('drop_sets', 'Drop Sets', 'Reduce weight after each drop, no rest', Icons.trending_down, Colors.orange),
                _ModalityOption('rest_pause', 'Rest-Pause', 'Near failure, 10-15s rest, repeat', Icons.pause_circle_outline, Colors.red),
                _ModalityOption('myo_reps', 'Myo-Reps', 'Activation set + quick mini-sets', Icons.flash_on, Colors.amber),
                _ModalityOption('cluster_sets', 'Cluster Sets', 'Intra-set rest (10-20s) between clusters', Icons.grain, Colors.deepPurple),
              ]),
              _buildCategory(theme, 'Compound Sets', [
                _ModalityOption('supersets', 'Supersets', 'Alternate 2 exercises, rest after pair', Icons.swap_vert, Colors.blue),
                _ModalityOption('giant_sets', 'Giant Sets', '3-4 exercises in sequence', Icons.view_stream, Colors.purple),
                _ModalityOption('circuit', 'Circuit', 'Multiple exercises, minimal rest between', Icons.loop, Colors.cyan),
              ]),
              _buildCategory(theme, 'Tempo & Control', [
                _ModalityOption('controlled_eccentrics', 'Controlled Eccentrics', 'Slow negatives with tempo cues', Icons.speed, Colors.teal),
              ]),
              _buildCategory(theme, 'Progression Structures', [
                _ModalityOption('pyramid_ascending', 'Pyramid Up', 'Increase weight, decrease reps each set', Icons.signal_cellular_alt, Colors.green),
                _ModalityOption('pyramid_descending', 'Pyramid Down', 'Decrease weight, increase reps each set', Icons.signal_cellular_alt, Colors.lightGreen),
                _ModalityOption('down_sets', 'Down Sets', 'Heavy top sets, then lighter back-off sets', Icons.arrow_downward, Colors.indigo),
              ]),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategory(ThemeData theme, String title, List<_ModalityOption> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: theme.textTheme.bodySmall?.color,
              letterSpacing: 1,
            ),
          ),
        ),
        ...options.map((opt) => _buildOption(theme, opt)),
      ],
    );
  }

  Widget _buildOption(ThemeData theme, _ModalityOption option) {
    final isSelected = currentModality == option.key;

    return GestureDetector(
      onTap: () => onSelected(option.key),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? option.color.withValues(alpha: 0.1)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? option.color : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(option.icon, size: 22, color: option.color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isSelected ? option.color : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: option.color, size: 22),
          ],
        ),
      ),
    );
  }
}

class _ModalityOption {
  final String key;
  final String label;
  final String description;
  final IconData icon;
  final Color color;

  const _ModalityOption(this.key, this.label, this.description, this.icon, this.color);
}

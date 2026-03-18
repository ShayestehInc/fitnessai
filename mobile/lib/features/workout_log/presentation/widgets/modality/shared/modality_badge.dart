import 'package:flutter/material.dart';

/// Small colored chip showing the modality name and icon.
class ModalityBadge extends StatelessWidget {
  final String setStructure;
  final bool compact;

  const ModalityBadge({
    super.key,
    required this.setStructure,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = _modalityInfo(setStructure);

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: info.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          info.shortLabel,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: info.color,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: info.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(info.icon, size: 14, color: info.color),
          const SizedBox(width: 4),
          Text(
            info.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: info.color,
            ),
          ),
        ],
      ),
    );
  }

  static _ModalityInfo _modalityInfo(String setStructure) {
    switch (setStructure) {
      case 'straight_sets':
        return _ModalityInfo('Straight Sets', 'STR', Icons.horizontal_rule, Colors.blueGrey);
      case 'drop_sets':
        return _ModalityInfo('Drop Sets', 'DROP', Icons.trending_down, Colors.orange);
      case 'supersets':
        return _ModalityInfo('Superset', 'SS', Icons.swap_vert, Colors.blue);
      case 'giant_sets':
        return _ModalityInfo('Giant Set', 'GS', Icons.view_stream, Colors.purple);
      case 'myo_reps':
        return _ModalityInfo('Myo-Reps', 'MYO', Icons.flash_on, Colors.amber);
      case 'rest_pause':
        return _ModalityInfo('Rest-Pause', 'RP', Icons.pause_circle_outline, Colors.red);
      case 'controlled_eccentrics':
        return _ModalityInfo('Eccentrics', 'ECC', Icons.speed, Colors.teal);
      case 'pyramid_ascending':
        return _ModalityInfo('Pyramid Up', 'PYR+', Icons.signal_cellular_alt, Colors.green);
      case 'pyramid_descending':
        return _ModalityInfo('Pyramid Down', 'PYR-', Icons.signal_cellular_alt, Colors.lightGreen);
      case 'down_sets':
        return _ModalityInfo('Down Sets', 'DOWN', Icons.arrow_downward, Colors.indigo);
      case 'cluster_sets':
        return _ModalityInfo('Cluster Sets', 'CLU', Icons.grain, Colors.deepPurple);
      case 'circuit':
        return _ModalityInfo('Circuit', 'CIR', Icons.loop, Colors.cyan);
      case 'occlusion':
        return _ModalityInfo('Occlusion', 'BFR', Icons.compress, Colors.pink);
      default:
        return _ModalityInfo(setStructure.replaceAll('_', ' '), setStructure.substring(0, 3).toUpperCase(), Icons.fitness_center, Colors.grey);
    }
  }
}

class _ModalityInfo {
  final String label;
  final String shortLabel;
  final IconData icon;
  final Color color;

  const _ModalityInfo(this.label, this.shortLabel, this.icon, this.color);
}

/// Determines rest duration based on modality context.
///
/// Different modalities have different rest rules:
/// - Drop sets: no rest between drops, full rest after final drop
/// - Myo-reps: 3-5s micro-rest between mini-sets
/// - Rest-pause: 10-15s micro-rest
/// - Cluster sets: 10-20s intra-set rest
/// - Supersets/Giant sets: no rest between exercises, rest after round
/// - Circuit: minimal rest between exercises, full rest after round

class RestTimerStrategy {
  const RestTimerStrategy._();

  /// Get rest duration in seconds after completing a set.
  ///
  /// Returns 0 for no rest (continue immediately).
  /// Returns null to use the default rest timer from the program.
  static int? getRestDuration({
    required String? setStructure,
    required String setType,
    required int defaultRestSeconds,
    required bool isLastSetInGroup,
    int? perSetRestOverride,
    Map<String, dynamic>? modalityDetails,
  }) {
    // Per-set override takes priority (from ModalitySetGenerator)
    if (perSetRestOverride != null) {
      return perSetRestOverride;
    }

    switch (setStructure) {
      case 'drop_sets':
        // No rest between drops, full rest after final drop
        return setType == 'drop' && !isLastSetInGroup ? 0 : defaultRestSeconds;

      case 'myo_reps':
        if (setType == 'mini') {
          return (modalityDetails?['micro_rest_seconds'] as int?) ?? 5;
        }
        return defaultRestSeconds;

      case 'rest_pause':
        if (!isLastSetInGroup) {
          return (modalityDetails?['micro_rest_seconds'] as int?) ?? 15;
        }
        return defaultRestSeconds;

      case 'cluster_sets':
        if (setType == 'cluster' && !isLastSetInGroup) {
          return (modalityDetails?['intra_rest_seconds'] as int?) ?? 15;
        }
        return defaultRestSeconds;

      case 'supersets':
      case 'giant_sets':
        // No rest between exercises in the group, rest after round
        return isLastSetInGroup ? defaultRestSeconds : 0;

      case 'circuit':
        // Minimal rest between exercises, full rest after round
        if (!isLastSetInGroup) {
          return (modalityDetails?['inter_exercise_rest'] as int?) ?? 10;
        }
        return defaultRestSeconds;

      case 'controlled_eccentrics':
      case 'pyramid_ascending':
      case 'pyramid_descending':
      case 'down_sets':
      case 'straight_sets':
      default:
        return defaultRestSeconds;
    }
  }

  /// Whether this modality uses micro-rest (inline timer) vs the main rest timer.
  static bool usesMicroRest(String? setStructure) {
    return const {
      'myo_reps',
      'rest_pause',
      'cluster_sets',
      'drop_sets',
    }.contains(setStructure);
  }

  /// Whether exercises should be grouped and alternated (superset-style).
  static bool isGroupedModality(String? setStructure) {
    return const {
      'supersets',
      'giant_sets',
      'circuit',
    }.contains(setStructure);
  }
}

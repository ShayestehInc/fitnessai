/// Generates initial SetLogState lists for each set structure modality.
///
/// Each modality has different set initialization logic:
/// - Drop sets: progressive weight reduction
/// - Pyramids: ascending/descending weight
/// - Down sets: top sets + back-off sets
/// - Myo-reps: activation set + mini-sets
/// - Cluster sets: clusters within sets
/// - Rest-pause: primary set + continuation sets
/// - Others: standard uniform sets

class ModalitySetConfig {
  final int setIndex;
  final String setType; // working, drop, activation, mini, cluster, back_off, top
  final double? targetWeightMultiplier; // e.g. 1.0, 0.8, 0.6 for drops
  final int? targetReps;
  final int? restAfterSet; // micro-rest override in seconds
  final String? tempoDisplay;

  const ModalitySetConfig({
    required this.setIndex,
    this.setType = 'working',
    this.targetWeightMultiplier,
    this.targetReps,
    this.restAfterSet,
    this.tempoDisplay,
  });
}

class ModalitySetGenerator {
  const ModalitySetGenerator._();

  /// Generate set configurations for a given modality.
  ///
  /// [setStructure] — modality slug (e.g. 'drop_sets', 'pyramid_ascending')
  /// [totalSets] — prescribed set count from the program
  /// [targetReps] — prescribed rep count (first number from range like "8-10")
  /// [restSeconds] — default rest between sets
  /// [tempo] — tempo prescription (E-P-C-P)
  /// [modalityDetails] — extra config from program builder (drop %, cluster reps, etc.)
  /// [lastWeight] — last logged weight for weight suggestions
  static List<ModalitySetConfig> generate({
    required String? setStructure,
    required int totalSets,
    required int targetReps,
    required int restSeconds,
    String? tempo,
    Map<String, dynamic>? modalityDetails,
    double? lastWeight,
  }) {
    switch (setStructure) {
      case 'drop_sets':
        return _generateDropSets(totalSets, targetReps, modalityDetails, lastWeight);
      case 'pyramid_ascending':
        return _generatePyramidAscending(totalSets, targetReps, modalityDetails);
      case 'pyramid_descending':
        return _generatePyramidDescending(totalSets, targetReps, modalityDetails);
      case 'down_sets':
        return _generateDownSets(totalSets, targetReps, modalityDetails);
      case 'myo_reps':
        return _generateMyoReps(targetReps, modalityDetails);
      case 'rest_pause':
        return _generateRestPause(targetReps, modalityDetails);
      case 'cluster_sets':
        return _generateClusterSets(totalSets, targetReps, modalityDetails);
      case 'controlled_eccentrics':
        return _generateControlledEccentrics(totalSets, targetReps, tempo);
      case 'supersets':
      case 'giant_sets':
      case 'circuit':
        // These are handled at the exercise-group level, not per-set
        return _generateStandardSets(totalSets, targetReps);
      case 'straight_sets':
      default:
        return _generateStandardSets(totalSets, targetReps);
    }
  }

  static List<ModalitySetConfig> _generateStandardSets(int totalSets, int targetReps) {
    return List.generate(totalSets, (i) => ModalitySetConfig(
      setIndex: i,
      setType: 'working',
      targetReps: targetReps,
      targetWeightMultiplier: 1.0,
    ));
  }

  static List<ModalitySetConfig> _generateDropSets(
    int totalSets,
    int targetReps,
    Map<String, dynamic>? details,
    double? lastWeight,
  ) {
    final dropCount = (details?['drop_count'] as int?) ?? 3;
    final dropPercent = (details?['drop_percent'] as num?)?.toDouble() ?? 20.0;

    final sets = <ModalitySetConfig>[];
    for (int s = 0; s < totalSets; s++) {
      // Top set
      sets.add(ModalitySetConfig(
        setIndex: sets.length,
        setType: 'top',
        targetReps: targetReps,
        targetWeightMultiplier: 1.0,
        restAfterSet: 0, // No rest between drops
      ));
      // Drop sets
      for (int d = 1; d <= dropCount; d++) {
        final multiplier = 1.0 - (dropPercent / 100.0 * d);
        sets.add(ModalitySetConfig(
          setIndex: sets.length,
          setType: 'drop',
          targetReps: targetReps + (d * 2), // More reps at lighter weight
          targetWeightMultiplier: multiplier.clamp(0.3, 1.0),
          restAfterSet: d == dropCount ? null : 0, // Rest only after final drop
        ));
      }
    }
    return sets;
  }

  static List<ModalitySetConfig> _generatePyramidAscending(
    int totalSets,
    int targetReps,
    Map<String, dynamic>? details,
  ) {
    final stepPercent = (details?['step_percent'] as num?)?.toDouble() ?? 5.0;
    return List.generate(totalSets, (i) {
      final multiplier = 1.0 + (stepPercent / 100.0 * i);
      final reps = (targetReps - i).clamp(1, 30);
      return ModalitySetConfig(
        setIndex: i,
        setType: 'working',
        targetReps: reps,
        targetWeightMultiplier: multiplier,
      );
    });
  }

  static List<ModalitySetConfig> _generatePyramidDescending(
    int totalSets,
    int targetReps,
    Map<String, dynamic>? details,
  ) {
    final stepPercent = (details?['step_percent'] as num?)?.toDouble() ?? 5.0;
    return List.generate(totalSets, (i) {
      final multiplier = 1.0 - (stepPercent / 100.0 * i);
      final reps = targetReps + (i * 2);
      return ModalitySetConfig(
        setIndex: i,
        setType: 'working',
        targetReps: reps,
        targetWeightMultiplier: multiplier.clamp(0.5, 1.0),
      );
    });
  }

  static List<ModalitySetConfig> _generateDownSets(
    int totalSets,
    int targetReps,
    Map<String, dynamic>? details,
  ) {
    final topSetCount = (details?['top_set_count'] as int?) ?? 2;
    final backOffPercent = (details?['back_off_percent'] as num?)?.toDouble() ?? 15.0;

    return List.generate(totalSets, (i) {
      final isTop = i < topSetCount;
      return ModalitySetConfig(
        setIndex: i,
        setType: isTop ? 'top' : 'back_off',
        targetReps: isTop ? targetReps : targetReps + 3,
        targetWeightMultiplier: isTop ? 1.0 : (1.0 - backOffPercent / 100.0),
      );
    });
  }

  static List<ModalitySetConfig> _generateMyoReps(
    int targetReps,
    Map<String, dynamic>? details,
  ) {
    final activationReps = (details?['activation_reps'] as int?) ?? (targetReps + 5).clamp(12, 25);
    final miniSetReps = (details?['mini_set_reps'] as int?) ?? 5;
    final maxMiniSets = (details?['max_mini_sets'] as int?) ?? 4;
    final microRest = (details?['micro_rest_seconds'] as int?) ?? 5;

    final sets = <ModalitySetConfig>[
      ModalitySetConfig(
        setIndex: 0,
        setType: 'activation',
        targetReps: activationReps,
        targetWeightMultiplier: 1.0,
        restAfterSet: microRest,
      ),
    ];
    for (int i = 0; i < maxMiniSets; i++) {
      sets.add(ModalitySetConfig(
        setIndex: sets.length,
        setType: 'mini',
        targetReps: miniSetReps,
        targetWeightMultiplier: 1.0,
        restAfterSet: microRest,
      ));
    }
    return sets;
  }

  static List<ModalitySetConfig> _generateRestPause(
    int targetReps,
    Map<String, dynamic>? details,
  ) {
    final pauseCount = (details?['pause_count'] as int?) ?? 2;
    final microRest = (details?['micro_rest_seconds'] as int?) ?? 15;

    final sets = <ModalitySetConfig>[
      ModalitySetConfig(
        setIndex: 0,
        setType: 'working',
        targetReps: targetReps,
        targetWeightMultiplier: 1.0,
        restAfterSet: microRest,
      ),
    ];
    for (int i = 0; i < pauseCount; i++) {
      sets.add(ModalitySetConfig(
        setIndex: sets.length,
        setType: 'working',
        targetReps: (targetReps * 0.5).ceil(),
        targetWeightMultiplier: 1.0,
        restAfterSet: microRest,
      ));
    }
    return sets;
  }

  static List<ModalitySetConfig> _generateClusterSets(
    int totalSets,
    int targetReps,
    Map<String, dynamic>? details,
  ) {
    final repsPerCluster = (details?['reps_per_cluster'] as int?) ?? 2;
    final intraRest = (details?['intra_rest_seconds'] as int?) ?? 15;
    final clustersPerSet = (details?['clusters_per_set'] as int?) ?? (targetReps / repsPerCluster).ceil();

    final sets = <ModalitySetConfig>[];
    for (int s = 0; s < totalSets; s++) {
      for (int c = 0; c < clustersPerSet; c++) {
        sets.add(ModalitySetConfig(
          setIndex: sets.length,
          setType: 'cluster',
          targetReps: repsPerCluster,
          targetWeightMultiplier: 1.0,
          restAfterSet: c < clustersPerSet - 1 ? intraRest : null,
        ));
      }
    }
    return sets;
  }

  static List<ModalitySetConfig> _generateControlledEccentrics(
    int totalSets,
    int targetReps,
    String? tempo,
  ) {
    return List.generate(totalSets, (i) => ModalitySetConfig(
      setIndex: i,
      setType: 'working',
      targetReps: targetReps,
      targetWeightMultiplier: 1.0,
      tempoDisplay: tempo ?? '4-1-1-1',
    ));
  }
}

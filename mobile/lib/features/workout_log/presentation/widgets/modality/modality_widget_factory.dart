import 'package:flutter/material.dart';
import 'straight_sets_log.dart';
import 'drop_set_log.dart';
import 'superset_log.dart';
import 'myo_rep_log.dart';
import 'controlled_eccentrics_log.dart';
import 'rest_pause_log.dart';
import 'pyramid_ascending_log.dart';
import 'pyramid_descending_log.dart';
import 'down_sets_log.dart';
import 'cluster_set_log.dart';
import 'giant_set_log.dart';
import 'circuit_log.dart';

/// Factory that routes a modality slug to the correct logging widget.
///
/// Falls back to StraightSetsLog for null/unknown modalities.
class ModalityWidgetFactory {
  const ModalityWidgetFactory._();

  /// Build the appropriate logging widget for the given modality.
  static Widget build({
    required String? setStructure,
    required int totalSets,
    required int targetReps,
    required int restSeconds,
    required void Function(int setIndex, double weight, int reps, String setType) onSetCompleted,
    double? lastWeight,
    String? tempo,
    Map<String, dynamic>? modalityDetails,
    // Extra params for grouped modalities (supersets, giant sets, circuit)
    String? exerciseAName,
    String? exerciseBName,
  }) {
    switch (setStructure) {
      case 'drop_sets':
        return DropSetLog(
          totalSets: totalSets,
          targetReps: targetReps,
          restSeconds: restSeconds,
          onSetCompleted: onSetCompleted,
          lastWeight: lastWeight,
          modalityDetails: modalityDetails,
        );
      case 'myo_reps':
        return MyoRepLog(
          totalSets: totalSets,
          targetReps: targetReps,
          restSeconds: restSeconds,
          onSetCompleted: onSetCompleted,
          lastWeight: lastWeight,
          modalityDetails: modalityDetails,
        );
      case 'rest_pause':
        return RestPauseLog(
          totalSets: totalSets,
          targetReps: targetReps,
          restSeconds: restSeconds,
          onSetCompleted: onSetCompleted,
          lastWeight: lastWeight,
          modalityDetails: modalityDetails,
        );
      case 'controlled_eccentrics':
        return ControlledEccentricsLog(
          totalSets: totalSets,
          targetReps: targetReps,
          restSeconds: restSeconds,
          onSetCompleted: onSetCompleted,
          lastWeight: lastWeight,
          tempo: tempo ?? '4-1-1-1',
        );
      case 'pyramid_ascending':
        return PyramidAscendingLog(
          totalSets: totalSets,
          targetReps: targetReps,
          restSeconds: restSeconds,
          onSetCompleted: onSetCompleted,
          lastWeight: lastWeight,
          modalityDetails: modalityDetails,
        );
      case 'pyramid_descending':
        return PyramidDescendingLog(
          totalSets: totalSets,
          targetReps: targetReps,
          restSeconds: restSeconds,
          onSetCompleted: onSetCompleted,
          lastWeight: lastWeight,
          modalityDetails: modalityDetails,
        );
      case 'down_sets':
        return DownSetsLog(
          totalSets: totalSets,
          targetReps: targetReps,
          restSeconds: restSeconds,
          onSetCompleted: onSetCompleted,
          lastWeight: lastWeight,
          modalityDetails: modalityDetails,
        );
      case 'cluster_sets':
        return ClusterSetLog(
          totalSets: totalSets,
          targetReps: targetReps,
          restSeconds: restSeconds,
          onSetCompleted: onSetCompleted,
          lastWeight: lastWeight,
          modalityDetails: modalityDetails,
        );
      case 'supersets':
        return SupersetLog(
          totalSets: totalSets,
          targetReps: targetReps,
          restSeconds: restSeconds,
          onSetCompleted: onSetCompleted,
          lastWeight: lastWeight,
          exerciseAName: exerciseAName ?? 'Exercise A',
          exerciseBName: exerciseBName ?? 'Exercise B',
          modalityDetails: modalityDetails,
        );
      case 'giant_sets':
        return GiantSetLog(
          totalSets: totalSets,
          targetReps: targetReps,
          restSeconds: restSeconds,
          onSetCompleted: onSetCompleted,
          lastWeight: lastWeight,
          modalityDetails: modalityDetails,
        );
      case 'circuit':
        return CircuitLog(
          totalSets: totalSets,
          targetReps: targetReps,
          restSeconds: restSeconds,
          onSetCompleted: onSetCompleted,
          lastWeight: lastWeight,
          modalityDetails: modalityDetails,
        );
      case 'straight_sets':
      default:
        return StraightSetsLog(
          totalSets: totalSets,
          targetReps: targetReps,
          restSeconds: restSeconds,
          onSetCompleted: onSetCompleted,
          lastWeight: lastWeight,
        );
    }
  }
}

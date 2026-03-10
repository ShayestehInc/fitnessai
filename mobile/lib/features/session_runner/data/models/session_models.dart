import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_models.freezed.dart';
part 'session_models.g.dart';

@freezed
class SessionSetModel with _$SessionSetModel {
  const SessionSetModel._();

  const factory SessionSetModel({
    @JsonKey(name: 'set_log_id') required String setLogId,
    @JsonKey(name: 'set_number') required int setNumber,
    required String status,
    @JsonKey(name: 'prescribed_reps_min') int? prescribedRepsMin,
    @JsonKey(name: 'prescribed_reps_max') int? prescribedRepsMax,
    @JsonKey(name: 'prescribed_load') String? prescribedLoad,
    @JsonKey(name: 'prescribed_load_unit') String? prescribedLoadUnit,
    @JsonKey(name: 'completed_reps') int? completedReps,
    @JsonKey(name: 'completed_load_value') String? completedLoadValue,
    @JsonKey(name: 'completed_load_unit') String? completedLoadUnit,
    double? rpe,
    @JsonKey(name: 'rest_prescribed_seconds') int? restPrescribedSeconds,
    @JsonKey(name: 'rest_actual_seconds') int? restActualSeconds,
    @Default('') String notes,
  }) = _SessionSetModel;

  factory SessionSetModel.fromJson(Map<String, dynamic> json) =>
      _$SessionSetModelFromJson(json);

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isSkipped => status == 'skipped';

  String get prescribedRepsDisplay {
    if (prescribedRepsMin == null && prescribedRepsMax == null) return '-';
    if (prescribedRepsMin == prescribedRepsMax) {
      return '${prescribedRepsMin ?? '-'}';
    }
    return '${prescribedRepsMin ?? '?'}-${prescribedRepsMax ?? '?'}';
  }

  String get prescribedLoadDisplay {
    if (prescribedLoad == null) return '-';
    final unit = prescribedLoadUnit ?? 'lb';
    return '$prescribedLoad $unit';
  }
}

@freezed
class SessionSlotModel with _$SessionSlotModel {
  const SessionSlotModel._();

  const factory SessionSlotModel({
    @JsonKey(name: 'slot_id') required String slotId,
    @JsonKey(name: 'exercise_name') required String exerciseName,
    @JsonKey(name: 'exercise_id') required int exerciseId,
    required int order,
    @JsonKey(name: 'slot_role') required String slotRole,
    @JsonKey(name: 'is_current') @Default(false) bool isCurrent,
    @Default([]) List<SessionSetModel> sets,
  }) = _SessionSlotModel;

  factory SessionSlotModel.fromJson(Map<String, dynamic> json) =>
      _$SessionSlotModelFromJson(json);

  int get totalSets => sets.length;
  int get completedSets => sets.where((s) => s.isCompleted).length;
  int get skippedSets => sets.where((s) => s.isSkipped).length;
  int get pendingSets => sets.where((s) => s.isPending).length;
  bool get isFullyDone => pendingSets == 0;

  SessionSetModel? get nextPendingSet {
    final pending = sets.where((s) => s.isPending).toList();
    return pending.isEmpty ? null : pending.first;
  }

  String get slotRoleDisplay {
    switch (slotRole) {
      case 'compound':
        return 'Compound';
      case 'accessory':
        return 'Accessory';
      case 'mobility':
        return 'Mobility';
      default:
        return slotRole;
    }
  }
}

@freezed
class ActiveSessionModel with _$ActiveSessionModel {
  const ActiveSessionModel._();

  const factory ActiveSessionModel({
    @JsonKey(name: 'active_session_id') required String activeSessionId,
    required String status,
    @JsonKey(name: 'trainee_id') required int traineeId,
    @JsonKey(name: 'plan_session_id') String? planSessionId,
    @JsonKey(name: 'plan_session_label') String? planSessionLabel,
    @JsonKey(name: 'current_slot_index') @Default(0) int currentSlotIndex,
    @JsonKey(name: 'total_slots') @Default(0) int totalSlots,
    @Default([]) List<SessionSlotModel> slots,
    @JsonKey(name: 'started_at') String? startedAt,
    @JsonKey(name: 'completed_at') String? completedAt,
    @JsonKey(name: 'progress_pct') @Default(0.0) double progressPct,
    @JsonKey(name: 'total_sets') @Default(0) int totalSets,
    @JsonKey(name: 'completed_sets') @Default(0) int completedSets,
    @JsonKey(name: 'skipped_sets') @Default(0) int skippedSets,
    @JsonKey(name: 'pending_sets') @Default(0) int pendingSets,
    @JsonKey(name: 'elapsed_seconds') @Default(0) int elapsedSeconds,
  }) = _ActiveSessionModel;

  factory ActiveSessionModel.fromJson(Map<String, dynamic> json) =>
      _$ActiveSessionModelFromJson(json);

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isAbandoned => status == 'abandoned';

  SessionSlotModel? get currentSlot {
    if (currentSlotIndex < 0 || currentSlotIndex >= slots.length) return null;
    return slots[currentSlotIndex];
  }

  String get elapsedDisplay {
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

@freezed
class ProgressionResultModel with _$ProgressionResultModel {
  const factory ProgressionResultModel({
    @JsonKey(name: 'slot_id') required String slotId,
    @JsonKey(name: 'event_type') required String eventType,
    @JsonKey(name: 'old_prescription') @Default({}) Map<String, dynamic> oldPrescription,
    @JsonKey(name: 'new_prescription') @Default({}) Map<String, dynamic> newPrescription,
    @JsonKey(name: 'reason_codes') @Default([]) List<String> reasonCodes,
  }) = _ProgressionResultModel;

  factory ProgressionResultModel.fromJson(Map<String, dynamic> json) =>
      _$ProgressionResultModelFromJson(json);
}

@freezed
class SessionSummaryModel with _$SessionSummaryModel {
  const SessionSummaryModel._();

  const factory SessionSummaryModel({
    @JsonKey(name: 'active_session_id') required String activeSessionId,
    required String status,
    @JsonKey(name: 'total_sets') @Default(0) int totalSets,
    @JsonKey(name: 'completed_sets') @Default(0) int completedSets,
    @JsonKey(name: 'skipped_sets') @Default(0) int skippedSets,
    @JsonKey(name: 'duration_seconds') @Default(0) int durationSeconds,
    @JsonKey(name: 'progression_results') @Default([]) List<ProgressionResultModel> progressionResults,
  }) = _SessionSummaryModel;

  factory SessionSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$SessionSummaryModelFromJson(json);

  String get durationDisplay {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    }
    return '${minutes}m ${seconds}s';
  }

  bool get hasProgressionResults => progressionResults.isNotEmpty;
}

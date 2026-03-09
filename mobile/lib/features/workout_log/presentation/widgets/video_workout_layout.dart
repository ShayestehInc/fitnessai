import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../shared/widgets/adaptive/adaptive_bottom_sheet.dart';
import '../providers/workout_provider.dart';
import '../screens/active_workout_screen.dart';

/// Video-first workout layout: full-screen exercise demo video background
/// with overlay controls and a compact bottom logging card.
/// Inspired by Nike Training Club / Peloton.
class VideoWorkoutLayout extends StatefulWidget {
  final String workoutName;
  final List<ExerciseLogState> exerciseLogs;
  final int currentExerciseIndex;
  final ValueChanged<int> onExerciseChanged;
  final String workoutDuration;
  final bool isResting;
  final int restSecondsRemaining;
  final VoidCallback onSkipRest;
  final void Function(int exerciseIndex, int setIndex, double weight, int reps)
      onSetCompleted;
  final void Function(int exerciseIndex) onAddSet;
  final VoidCallback onFinish;
  final VoidCallback onExit;

  const VideoWorkoutLayout({
    super.key,
    required this.workoutName,
    required this.exerciseLogs,
    required this.currentExerciseIndex,
    required this.onExerciseChanged,
    required this.workoutDuration,
    required this.isResting,
    required this.restSecondsRemaining,
    required this.onSkipRest,
    required this.onSetCompleted,
    required this.onAddSet,
    required this.onFinish,
    required this.onExit,
  });

  @override
  State<VideoWorkoutLayout> createState() => _VideoWorkoutLayoutState();
}

class _VideoWorkoutLayoutState extends State<VideoWorkoutLayout>
    with WidgetsBindingObserver {
  static const _cardBg = Color(0xFF1C1C1E);
  static const _inputBg = Color(0xFF2C2C2E);
  static const _textShadows = [
    Shadow(blurRadius: 8, color: Colors.black54),
    Shadow(blurRadius: 16, color: Colors.black26),
  ];

  VideoPlayerController? _videoController;
  bool _videoInitialized = false;
  bool _videoError = false;
  double _playbackSpeed = 1.0;
  int _videoInitGeneration = 0;

  late List<List<TextEditingController>> _weightControllers;
  late List<List<TextEditingController>> _repsControllers;

  ProgramExercise get _exercise =>
      widget.exerciseLogs[widget.currentExerciseIndex].exercise;

  ExerciseLogState get _currentLog =>
      widget.exerciseLogs[widget.currentExerciseIndex];

  int get _completedSets => widget.exerciseLogs.fold<int>(
      0, (sum, log) => sum + log.sets.where((s) => s.isCompleted).length);

  int get _totalSets =>
      widget.exerciseLogs.fold<int>(0, (sum, log) => sum + log.sets.length);

  // -------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _initAllControllers();
    _initVideo();
  }

  @override
  void didUpdateWidget(covariant VideoWorkoutLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncControllers();
    if (oldWidget.currentExerciseIndex != widget.currentExerciseIndex) {
      _initVideo();
    }
    if (!oldWidget.isResting && widget.isResting) {
      _videoController?.pause();
    } else if (oldWidget.isResting && !widget.isResting) {
      _videoController?.play();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _videoController?.pause();
    } else if (state == AppLifecycleState.resumed && !widget.isResting) {
      _videoController?.play();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Restore system UI overlay style to default
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    _videoController?.dispose();
    for (final list in _weightControllers) {
      for (final c in list) {
        c.dispose();
      }
    }
    for (final list in _repsControllers) {
      for (final c in list) {
        c.dispose();
      }
    }
    super.dispose();
  }

  // -------------------------------------------------------------------
  // Controllers
  // -------------------------------------------------------------------

  void _initAllControllers() {
    _weightControllers = widget.exerciseLogs.map((log) {
      return log.sets
          .map((s) => TextEditingController(text: s.weight?.toString() ?? ''))
          .toList();
    }).toList();
    _repsControllers = widget.exerciseLogs.map((log) {
      return log.sets
          .map((s) => TextEditingController(text: s.reps?.toString() ?? ''))
          .toList();
    }).toList();
  }

  void _syncControllers() {
    while (_weightControllers.length < widget.exerciseLogs.length) {
      _weightControllers.add([]);
      _repsControllers.add([]);
    }
    for (int i = 0; i < widget.exerciseLogs.length; i++) {
      final sets = widget.exerciseLogs[i].sets;
      while (_weightControllers[i].length < sets.length) {
        final s = sets[_weightControllers[i].length];
        _weightControllers[i]
            .add(TextEditingController(text: s.weight?.toString() ?? ''));
        _repsControllers[i]
            .add(TextEditingController(text: s.reps?.toString() ?? ''));
      }
    }
  }

  // -------------------------------------------------------------------
  // Video
  // -------------------------------------------------------------------

  Future<void> _initVideo() async {
    _videoInitGeneration++;
    final generation = _videoInitGeneration;
    final old = _videoController;
    setState(() {
      _videoController = null;
      _videoInitialized = false;
      _videoError = false;
    });
    old?.dispose();

    final url = _exercise.videoUrl;
    if (url == null || url.isEmpty) return;

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await controller.initialize();
      // If a newer init was triggered while we were awaiting, discard this one
      if (generation != _videoInitGeneration || !mounted) {
        controller.dispose();
        return;
      }
      controller.setLooping(true);
      controller.setPlaybackSpeed(_playbackSpeed);
      controller.setVolume(0);
      setState(() {
        _videoController = controller;
        _videoInitialized = true;
      });
      try {
        await controller.play();
      } catch (e) {
        debugPrint('Video play failed: $e');
      }
    } catch (e, st) {
      debugPrint('Video init failed: $e\n$st');
      controller.dispose();
      if (generation == _videoInitGeneration && mounted) {
        setState(() => _videoError = true);
      }
    }
  }

  void _toggleSpeed() {
    setState(() => _playbackSpeed = _playbackSpeed == 1.0 ? 0.5 : 1.0);
    _videoController?.setPlaybackSpeed(_playbackSpeed);
    HapticService.selectionTick();
  }

  void _navigateExercise(int delta) {
    final next = widget.currentExerciseIndex + delta;
    if (next >= 0 && next < widget.exerciseLogs.length) {
      widget.onExerciseChanged(next);
      HapticService.lightTap();
    }
  }

  void _completeSet(int setIndex) {
    final ei = widget.currentExerciseIndex;
    final wt = _weightControllers[ei][setIndex].text;
    final rt = _repsControllers[ei][setIndex].text;
    final s = _currentLog.sets[setIndex];

    final weight = double.tryParse(wt) ?? s.lastWeight ?? 0;
    final reps = int.tryParse(rt) ?? s.lastReps ?? s.targetReps;

    if (wt.isEmpty) _weightControllers[ei][setIndex].text = weight.round().toString();
    if (rt.isEmpty) _repsControllers[ei][setIndex].text = reps.toString();

    widget.onSetCompleted(ei, setIndex, weight, reps);
    HapticService.mediumTap();
  }

  double _maxWeightForExercise() {
    double max = _exercise.lastWeight ?? 0;
    for (final s in _currentLog.sets) {
      if (s.isCompleted && s.weight != null && s.weight! > max) max = s.weight!;
    }
    return max;
  }

  // -------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          Expanded(child: _buildVideoArea()),
          _buildLoggingCard(),
        ],
      ),
    );
  }

  Widget _buildVideoArea() {
    return GestureDetector(
      onHorizontalDragEnd: (d) {
        if (d.velocity.pixelsPerSecond.dx > 400) {
          _navigateExercise(-1);
        } else if (d.velocity.pixelsPerSecond.dx < -400) {
          _navigateExercise(1);
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video / fallback
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _videoInitialized && _videoController != null
                ? SizedBox.expand(
                    key: ValueKey('video-${widget.currentExerciseIndex}'),
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController!.value.size.width,
                        height: _videoController!.value.size.height,
                        child: VideoPlayer(_videoController!),
                      ),
                    ),
                  )
                : _buildFallback(),
          ),
          // Gradients
          _buildTopGradient(),
          _buildBottomGradient(),
          // Top overlay
          _buildTopOverlay(),
          // Navigation chevrons
          _buildChevrons(),
          // Bottom video controls
          _buildVideoControls(),
          // Rest timer
          if (widget.isResting) _buildRestOverlay(),
        ],
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      key: ValueKey('fallback-${widget.currentExerciseIndex}'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _muscleGroupColor(_exercise.muscleGroup).withValues(alpha: 0.8),
            Colors.black87,
          ],
        ),
      ),
      child: Center(
        child: _videoError
            ? const Icon(Icons.videocam_off, color: Colors.white38, size: 64)
            : const CircularProgressIndicator(color: Colors.white54),
      ),
    );
  }

  Widget _buildTopGradient() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 160,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xCC000000), Colors.transparent],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomGradient() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: 160,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xCC000000), Colors.transparent],
          ),
        ),
      ),
    );
  }

  Widget _buildTopOverlay() {
    final progress = _totalSets > 0 ? _completedSets / _totalSets : 0.0;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
          child: Column(
            children: [
              // Close / info row
              Row(
                children: [
                  IconButton(
                    onPressed: widget.onExit,
                    icon: const Icon(Icons.close, color: Colors.white, size: 22),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: widget.onFinish,
                    child: const Text(
                      'Finish',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              // Timer / Exercise / Sets row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Timer
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.workoutDuration,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFeatures: [FontFeature.tabularFigures()],
                            shadows: _textShadows,
                          ),
                        ),
                        const Text(
                          'Total Time',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            shadows: _textShadows,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Exercise name + reps
                    Flexible(
                      child: Column(
                        children: [
                          Text(
                            _exercise.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              shadows: _textShadows,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Text(
                          '${_exercise.targetReps} Reps',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            shadows: _textShadows,
                          ),
                        ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Sets
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$_completedSets/$_totalSets',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFeatures: [FontFeature.tabularFigures()],
                            shadows: _textShadows,
                          ),
                        ),
                        const Text(
                          'Sets',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            shadows: _textShadows,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    backgroundColor: Colors.white24,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChevrons() {
    final canGoPrev = widget.currentExerciseIndex > 0;
    final canGoNext =
        widget.currentExerciseIndex < widget.exerciseLogs.length - 1;

    return Positioned.fill(
      child: Row(
        children: [
          // Left chevron
          GestureDetector(
            onTap: canGoPrev ? () => _navigateExercise(-1) : null,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 56,
              child: Center(
                child: AnimatedOpacity(
                  opacity: canGoPrev ? 0.8 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_double_arrow_left,
                    color: Colors.greenAccent,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          // Right chevron
          GestureDetector(
            onTap: canGoNext ? () => _navigateExercise(1) : null,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 56,
              child: Center(
                child: AnimatedOpacity(
                  opacity: canGoNext ? 0.8 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_double_arrow_right,
                    color: Colors.greenAccent,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoControls() {
    final speedLabel = _playbackSpeed == 1.0 ? '1x' : '.5x';

    return Positioned(
      left: 16,
      right: 16,
      bottom: 12,
      child: Row(
        children: [
          // Info button
          _circleButton(
            icon: Icons.info_outline,
            onTap: () => _showExerciseInfo(context),
          ),
          const Spacer(),
          // Speed toggle
          GestureDetector(
            onTap: _toggleSpeed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$speedLabel Speed',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const Spacer(),
          // Exercise list button
          _circleButton(
            icon: Icons.list,
            onTap: () => _showExerciseList(context),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildRestOverlay() {
    final totalRest = _exercise.restSeconds ?? 90;
    final progress = totalRest > 0
        ? widget.restSecondsRemaining / totalRest
        : 0.0;

    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Rest',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        strokeWidth: 5,
                        color: Colors.white,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                    Text(
                      '${widget.restSecondsRemaining}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: widget.onSkipRest,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: const BorderSide(color: Colors.white38),
                  ),
                ),
                child: const Text('Skip',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // Logging card
  // -------------------------------------------------------------------

  Widget _buildLoggingCard() {
    final maxWeight = _maxWeightForExercise();
    final primary = Theme.of(context).colorScheme.primary;
    final ei = widget.currentExerciseIndex;
    final sets = _currentLog.sets;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.35,
      ),
      decoration: const BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag indicator
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Max weight row
            if (maxWeight > 0)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Text.rich(
                  TextSpan(
                    text: 'Max Weight Logged: ',
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                    children: [
                      TextSpan(
                        text: '${maxWeight.round()}Lb',
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Table header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _tableHeader('Set', 44),
                  Expanded(child: _tableHeader('Reps', null)),
                  Expanded(child: _tableHeader('Weight', null)),
                  _tableHeader('Log It', 56),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            // Set rows
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 4),
                itemCount: sets.length + 1,
                itemBuilder: (context, i) {
                  if (i == sets.length) {
                    return Center(
                      child: TextButton.icon(
                        onPressed: () => widget.onAddSet(ei),
                        icon: const Icon(Icons.add, size: 16,
                            color: Colors.white54),
                        label: const Text('Add Set',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 13)),
                      ),
                    );
                  }
                  return _buildSetRow(ei, i, sets[i], primary);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableHeader(String text, double? width) {
    final child = Text(
      text,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
    return width != null ? SizedBox(width: width, child: child) : child;
  }

  Widget _buildSetRow(
      int exerciseIndex, int setIndex, SetLogState set, Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: set.isCompleted ? primary.withValues(alpha: 0.08) : null,
      child: Row(
        children: [
          // Set number
          SizedBox(
            width: 44,
            child: Center(
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: set.isCompleted ? primary : Colors.white12,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${set.setNumber}',
                    style: TextStyle(
                      color: set.isCompleted ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Reps input
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _darkInput(
                controller: _repsControllers[exerciseIndex][setIndex],
                hint: set.lastReps?.toString() ?? set.targetReps.toString(),
                enabled: !set.isCompleted,
                keyboardType: TextInputType.number,
              ),
            ),
          ),
          // Weight input
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _darkInput(
                controller: _weightControllers[exerciseIndex][setIndex],
                hint: set.lastWeight?.round().toString() ?? '0',
                suffix: 'Lb',
                enabled: !set.isCompleted,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ),
          // Log it button
          SizedBox(
            width: 56,
            child: Center(
              child: set.isCompleted
                  ? Icon(Icons.check_circle, color: primary, size: 28)
                  : GestureDetector(
                      onTap: () => _completeSet(setIndex),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 2),
                        ),
                        child: const Icon(Icons.check,
                            color: Colors.white38, size: 16),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _darkInput({
    required TextEditingController controller,
    required String hint,
    String? suffix,
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textAlign: TextAlign.center,
      enabled: enabled,
      style: TextStyle(
        color: enabled ? Colors.white : Colors.white54,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
        suffixText: suffix,
        suffixStyle: const TextStyle(color: Colors.white38, fontSize: 11),
        filled: true,
        fillColor: enabled ? _inputBg : _inputBg.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // Bottom sheets
  // -------------------------------------------------------------------

  void _showExerciseList(BuildContext context) {
    showAdaptiveBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ExerciseListSheet(
        exerciseLogs: widget.exerciseLogs,
        currentIndex: widget.currentExerciseIndex,
        onSelect: (i) {
          Navigator.of(ctx).pop();
          widget.onExerciseChanged(i);
        },
      ),
    );
  }

  void _showExerciseInfo(BuildContext context) {
    showAdaptiveBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _exercise.name,
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatMuscleGroup(_exercise.muscleGroup)} '
              '| ${_exercise.targetSets} sets x ${_exercise.targetReps} reps',
              style: TextStyle(
                color: Theme.of(ctx).textTheme.bodySmall?.color,
                fontSize: 14,
              ),
            ),
            if (_exercise.restSeconds != null) ...[
              const SizedBox(height: 4),
              Text(
                'Rest: ${_exercise.restSeconds}s',
                style: TextStyle(
                  color: Theme.of(ctx).textTheme.bodySmall?.color,
                  fontSize: 14,
                ),
              ),
            ],
            if (_exercise.notes != null && _exercise.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).dividerColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _exercise.notes!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------

  Color _muscleGroupColor(String group) {
    switch (group.toLowerCase()) {
      case 'chest':
        return Colors.red.shade700;
      case 'back':
        return Colors.blue.shade700;
      case 'shoulders':
        return Colors.orange.shade700;
      case 'legs':
        return Colors.green.shade700;
      case 'biceps':
      case 'triceps':
      case 'arms':
        return Colors.purple.shade700;
      case 'core':
      case 'abs':
        return Colors.teal.shade700;
      default:
        return Colors.blueGrey.shade700;
    }
  }

  String _formatMuscleGroup(String group) {
    return group
        .split('_')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}

// ---------------------------------------------------------------------
// Exercise list bottom sheet
// ---------------------------------------------------------------------

class _ExerciseListSheet extends StatelessWidget {
  final List<ExerciseLogState> exerciseLogs;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  const _ExerciseListSheet({
    required this.exerciseLogs,
    required this.currentIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: exerciseLogs.length,
      itemBuilder: (ctx, i) {
        final log = exerciseLogs[i];
        final exercise = log.exercise;
        final completed = log.sets.where((s) => s.isCompleted).length;
        final total = log.sets.length;
        final isCurrent = i == currentIndex;
        final allDone = completed == total;

        return ListTile(
          selected: isCurrent,
          selectedTileColor: primary.withValues(alpha: 0.08),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: allDone
                  ? primary.withValues(alpha: 0.15)
                  : theme.dividerColor.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: allDone
                  ? Icon(Icons.check, size: 18, color: primary)
                  : Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
          title: Text(
            exercise.name,
            style: TextStyle(
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            '$completed/$total sets',
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 12,
            ),
          ),
          trailing: isCurrent
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Current',
                    style: TextStyle(
                      color: primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null,
          onTap: () => onSelect(i),
        );
      },
    );
  }
}

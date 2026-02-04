import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/workout_provider.dart';

class ReadinessSurveyScreen extends ConsumerStatefulWidget {
  final ProgramWorkoutDay workout;
  final VoidCallback? onSkip;
  final Function(ReadinessSurveyData)? onComplete;

  const ReadinessSurveyScreen({
    super.key,
    required this.workout,
    this.onSkip,
    this.onComplete,
  });

  @override
  ConsumerState<ReadinessSurveyScreen> createState() => _ReadinessSurveyScreenState();
}

class _ReadinessSurveyScreenState extends ConsumerState<ReadinessSurveyScreen> {
  int? _sleepRating;
  int? _moodRating;
  int? _energyRating;
  int? _stressRating;
  int? _sorenessRating;

  int get _completedCount {
    int count = 0;
    if (_sleepRating != null) count++;
    if (_moodRating != null) count++;
    if (_energyRating != null) count++;
    if (_stressRating != null) count++;
    if (_sorenessRating != null) count++;
    return count;
  }

  bool get _canProceed => _completedCount >= 4; // At least 4 out of 5 answered

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with close and progress
            _buildHeader(theme),

            // Survey content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Readiness Survey',
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'TELL US HOW YOU FEEL',
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Sleep
                    _buildRatingSection(
                      theme: theme,
                      title: 'SLEEP',
                      icon: Icons.bedtime,
                      iconColor: Colors.green,
                      labels: ['Awful', 'Poor', 'Ok', 'Good', 'Excellent'],
                      selectedValue: _sleepRating,
                      onChanged: (v) => setState(() => _sleepRating = v),
                    ),
                    const SizedBox(height: 28),

                    // Mood
                    _buildRatingSection(
                      theme: theme,
                      title: 'MOOD',
                      icon: Icons.wb_sunny_outlined,
                      iconColor: Colors.green,
                      labels: ['Very Poor', 'A little off', 'Ok', 'Good', 'Great!'],
                      selectedValue: _moodRating,
                      onChanged: (v) => setState(() => _moodRating = v),
                    ),
                    const SizedBox(height: 28),

                    // Energy
                    _buildRatingSection(
                      theme: theme,
                      title: 'ENERGY',
                      icon: Icons.bolt,
                      iconColor: Colors.orange,
                      labels: ['Wiped out', 'Tired', 'Ok', 'Good', 'Amped up'],
                      selectedValue: _energyRating,
                      onChanged: (v) => setState(() => _energyRating = v),
                    ),
                    const SizedBox(height: 28),

                    // Stress
                    _buildRatingSection(
                      theme: theme,
                      title: 'STRESS',
                      icon: Icons.psychology,
                      iconColor: Colors.orange,
                      labels: ['Overwhelmed', 'High', 'Moderate', 'Low', 'None'],
                      selectedValue: _stressRating,
                      onChanged: (v) => setState(() => _stressRating = v),
                    ),
                    const SizedBox(height: 28),

                    // Soreness
                    _buildRatingSection(
                      theme: theme,
                      title: 'SORENESS',
                      icon: Icons.accessibility_new,
                      iconColor: Colors.blue,
                      labels: ['Very sore', 'Sore', 'Slight', 'Minimal', 'None'],
                      selectedValue: _sorenessRating,
                      onChanged: (v) => setState(() => _sorenessRating = v),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Bottom navigation
            _buildBottomNav(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _showSkipDialog(context),
            icon: const Icon(Icons.keyboard_arrow_down),
            iconSize: 28,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final isCompleted = index < _completedCount;
                return Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? theme.colorScheme.primary
                        : theme.dividerColor,
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 48), // Balance the close button
        ],
      ),
    );
  }

  Widget _buildRatingSection({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<String> labels,
    required int? selectedValue,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Icon(icon, color: iconColor, size: 28),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(5, (index) {
            final value = index + 1;
            final isSelected = selectedValue == value;
            final color = _getRatingColor(value, isSelected);

            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(value),
                child: Container(
                  margin: EdgeInsets.only(right: index < 4 ? 8 : 0),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 56,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? color : theme.dividerColor,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$value',
                            style: TextStyle(
                              color: isSelected ? color : theme.textTheme.bodyLarge?.color,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        labels[index],
                        style: TextStyle(
                          color: isSelected ? color : theme.textTheme.bodySmall?.color,
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Color _getRatingColor(int value, bool isSelected) {
    if (!isSelected) return Colors.grey;
    switch (value) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.red.shade400;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.green.shade400;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildBottomNav(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () => _showSkipDialog(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Skip'),
            ),
            Text(
              'Completed $_completedCount / 5',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 14,
              ),
            ),
            TextButton.icon(
              onPressed: _canProceed ? _submitAndStart : null,
              icon: Icon(
                Icons.arrow_forward,
                color: _canProceed ? theme.colorScheme.primary : theme.dividerColor,
              ),
              label: Text(
                'Start',
                style: TextStyle(
                  color: _canProceed ? theme.colorScheme.primary : theme.dividerColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSkipDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Survey?'),
        content: const Text('You can still start your workout without completing the survey.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Continue Survey'),
          ),
          TextButton(
            onPressed: () {
              context.pop();
              widget.onSkip?.call();
            },
            child: const Text('Skip & Start'),
          ),
        ],
      ),
    );
  }

  void _submitAndStart() {
    final surveyData = ReadinessSurveyData(
      sleep: _sleepRating ?? 0,
      mood: _moodRating ?? 0,
      energy: _energyRating ?? 0,
      stress: _stressRating ?? 0,
      soreness: _sorenessRating ?? 0,
      timestamp: DateTime.now(),
    );
    widget.onComplete?.call(surveyData);
  }
}

class ReadinessSurveyData {
  final int sleep;
  final int mood;
  final int energy;
  final int stress;
  final int soreness;
  final DateTime timestamp;

  const ReadinessSurveyData({
    required this.sleep,
    required this.mood,
    required this.energy,
    required this.stress,
    required this.soreness,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'sleep': sleep,
    'mood': mood,
    'energy': energy,
    'stress': stress,
    'soreness': soreness,
    'timestamp': timestamp.toIso8601String(),
  };

  double get averageScore {
    int count = 0;
    int total = 0;
    if (sleep > 0) { total += sleep; count++; }
    if (mood > 0) { total += mood; count++; }
    if (energy > 0) { total += energy; count++; }
    if (stress > 0) { total += stress; count++; }
    if (soreness > 0) { total += soreness; count++; }
    return count > 0 ? total / count : 0;
  }
}

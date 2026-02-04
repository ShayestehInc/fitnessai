import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/workout_provider.dart';

class PostWorkoutSurveyScreen extends ConsumerStatefulWidget {
  final ProgramWorkoutDay workout;
  final String workoutDuration;
  final int setsCompleted;
  final int totalSets;
  final Function(PostWorkoutSurveyData)? onComplete;

  const PostWorkoutSurveyScreen({
    super.key,
    required this.workout,
    required this.workoutDuration,
    required this.setsCompleted,
    required this.totalSets,
    this.onComplete,
  });

  @override
  ConsumerState<PostWorkoutSurveyScreen> createState() => _PostWorkoutSurveyScreenState();
}

class _PostWorkoutSurveyScreenState extends ConsumerState<PostWorkoutSurveyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late PageController _pageController;

  int _currentPage = 0;
  int? _performanceRating;
  int? _intensityRating;
  int? _energyAfterRating;
  int? _satisfactionRating;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _pageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Progress dots
            _buildProgressDots(theme),

            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildCelebrationPage(theme),
                  _buildPerformancePage(theme),
                  _buildIntensityPage(theme),
                  _buildEnergyPage(theme),
                  _buildSatisfactionPage(theme),
                  _buildNotesPage(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressDots(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(6, (index) {
          final isActive = index == _currentPage;
          final isCompleted = index < _currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isActive ? 24 : 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: isActive || isCompleted
                  ? theme.colorScheme.primary
                  : theme.dividerColor,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCelebrationPage(ThemeData theme) {
    final completionRate = widget.totalSets > 0
        ? (widget.setsCompleted / widget.totalSets * 100).round()
        : 100;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events,
                size: 60,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Workout Complete!',
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.workout.name,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard(theme, widget.workoutDuration, 'Duration', Icons.timer),
              _buildStatCard(theme, '${widget.setsCompleted}', 'Sets', Icons.fitness_center),
              _buildStatCard(theme, '$completionRate%', 'Complete', Icons.check_circle),
            ],
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _goToPage(1),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Let's Rate It!", style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _skipSurvey,
            child: Text(
              'Skip Survey',
              style: TextStyle(color: theme.textTheme.bodySmall?.color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(ThemeData theme, String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformancePage(ThemeData theme) {
    return _buildRatingPage(
      theme: theme,
      title: 'How was your performance?',
      subtitle: 'Rate how well you executed your exercises',
      icon: Icons.stars,
      iconColor: Colors.amber,
      emojis: ['😞', '😕', '😐', '😊', '🔥'],
      labels: ['Struggled', 'Below par', 'Average', 'Good', 'Crushed it!'],
      selectedValue: _performanceRating,
      onChanged: (v) {
        setState(() => _performanceRating = v);
        Future.delayed(const Duration(milliseconds: 300), () => _goToPage(2));
      },
    );
  }

  Widget _buildIntensityPage(ThemeData theme) {
    return _buildRatingPage(
      theme: theme,
      title: 'How intense was it?',
      subtitle: 'Compared to your usual workouts',
      icon: Icons.local_fire_department,
      iconColor: Colors.deepOrange,
      emojis: ['😴', '🚶', '🏃', '💪', '🏋️'],
      labels: ['Too easy', 'Light', 'Moderate', 'Hard', 'Brutal'],
      selectedValue: _intensityRating,
      onChanged: (v) {
        setState(() => _intensityRating = v);
        Future.delayed(const Duration(milliseconds: 300), () => _goToPage(3));
      },
    );
  }

  Widget _buildEnergyPage(ThemeData theme) {
    return _buildRatingPage(
      theme: theme,
      title: 'How do you feel now?',
      subtitle: 'Your energy level after the workout',
      icon: Icons.bolt,
      iconColor: Colors.amber,
      emojis: ['😩', '😮‍💨', '😌', '😄', '⚡'],
      labels: ['Drained', 'Tired', 'Good', 'Energized', 'Amazing'],
      selectedValue: _energyAfterRating,
      onChanged: (v) {
        setState(() => _energyAfterRating = v);
        Future.delayed(const Duration(milliseconds: 300), () => _goToPage(4));
      },
    );
  }

  Widget _buildSatisfactionPage(ThemeData theme) {
    return _buildRatingPage(
      theme: theme,
      title: 'Overall satisfaction?',
      subtitle: 'How happy are you with this session',
      icon: Icons.thumb_up,
      iconColor: theme.colorScheme.primary,
      emojis: ['👎', '😒', '👌', '👍', '🙌'],
      labels: ['Poor', 'Meh', 'OK', 'Good', 'Loved it!'],
      selectedValue: _satisfactionRating,
      onChanged: (v) {
        setState(() => _satisfactionRating = v);
        Future.delayed(const Duration(milliseconds: 300), () => _goToPage(5));
      },
    );
  }

  Widget _buildRatingPage({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required List<String> emojis,
    required List<String> labels,
    required int? selectedValue,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: iconColor),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final value = index + 1;
              final isSelected = selectedValue == value;
              return GestureDetector(
                onTap: () => onChanged(value),
                child: AnimatedScale(
                  scale: isSelected ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _getRatingColor(value).withValues(alpha: 0.2)
                              : theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? _getRatingColor(value)
                                : theme.dividerColor,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            emojis[index],
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        labels[index],
                        style: TextStyle(
                          color: isSelected
                              ? _getRatingColor(value)
                              : theme.textTheme.bodySmall?.color,
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 48),
          TextButton(
            onPressed: _submitSurvey,
            child: const Text('Skip & Finish'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesPage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Icon(Icons.edit_note, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            'Any notes for your trainer?',
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Optional feedback or observations',
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _notesController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'e.g., "Shoulder felt tight during overhead press"',
              hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
              filled: true,
              fillColor: theme.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitSurvey,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Complete', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _submitSurvey,
            child: Text(
              'Skip',
              style: TextStyle(color: theme.textTheme.bodySmall?.color),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Color _getRatingColor(int value) {
    switch (value) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.amber;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _skipSurvey() {
    final surveyData = PostWorkoutSurveyData(
      performance: 0,
      intensity: 0,
      energyAfter: 0,
      satisfaction: 0,
      notes: '',
      timestamp: DateTime.now(),
      skipped: true,
    );
    widget.onComplete?.call(surveyData);
  }

  void _submitSurvey() {
    final surveyData = PostWorkoutSurveyData(
      performance: _performanceRating ?? 0,
      intensity: _intensityRating ?? 0,
      energyAfter: _energyAfterRating ?? 0,
      satisfaction: _satisfactionRating ?? 0,
      notes: _notesController.text.trim(),
      timestamp: DateTime.now(),
      skipped: false,
    );
    widget.onComplete?.call(surveyData);
  }
}

class PostWorkoutSurveyData {
  final int performance;
  final int intensity;
  final int energyAfter;
  final int satisfaction;
  final String notes;
  final DateTime timestamp;
  final bool skipped;

  const PostWorkoutSurveyData({
    required this.performance,
    required this.intensity,
    required this.energyAfter,
    required this.satisfaction,
    required this.notes,
    required this.timestamp,
    required this.skipped,
  });

  Map<String, dynamic> toJson() => {
    'performance': performance,
    'intensity': intensity,
    'energy_after': energyAfter,
    'satisfaction': satisfaction,
    'notes': notes,
    'timestamp': timestamp.toIso8601String(),
    'skipped': skipped,
  };

  double get averageScore {
    if (skipped) return 0;
    int count = 0;
    int total = 0;
    if (performance > 0) { total += performance; count++; }
    if (intensity > 0) { total += intensity; count++; }
    if (energyAfter > 0) { total += energyAfter; count++; }
    if (satisfaction > 0) { total += satisfaction; count++; }
    return count > 0 ? total / count : 0;
  }
}

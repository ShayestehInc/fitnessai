import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../programs/data/models/program_model.dart';
import '../../../programs/presentation/providers/program_provider.dart';
import '../../../programs/presentation/screens/program_builder_screen.dart';
import '../providers/trainer_provider.dart';

class AssignProgramScreen extends ConsumerStatefulWidget {
  final int traineeId;

  const AssignProgramScreen({
    super.key,
    required this.traineeId,
  });

  @override
  ConsumerState<AssignProgramScreen> createState() => _AssignProgramScreenState();
}

class _AssignProgramScreenState extends ConsumerState<AssignProgramScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final traineeAsync = ref.watch(traineeDetailProvider(widget.traineeId));

    // Check if trainee has an active program
    final activeProgram = traineeAsync.whenOrNull(
      data: (trainee) => trainee?.programs.isNotEmpty == true ? trainee!.programs.first : null,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Program'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning banner if there's an active program
            if (activeProgram != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Active Program Will Be Replaced',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Current: ${activeProgram.name}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeProgram != null ? 'Replace Current Program' : 'Create or Assign a Program',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Build a multi-week training program for your trainee',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Options
            Text(
              'Choose an Option',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Create new program
            _buildOptionCard(
              context,
              icon: Icons.add_circle_outline,
              title: 'Create New Program',
              subtitle: 'Build a custom program from scratch',
              onTap: () => _showCreateNewProgramDialog(context),
            ),

            const SizedBox(height: 12),

            // Use template
            _buildOptionCard(
              context,
              icon: Icons.copy_all,
              title: 'Use a Template',
              subtitle: 'Start with a pre-built program template',
              onTap: () => _showTemplatesSheet(context),
            ),

            const SizedBox(height: 12),

            // Assign existing
            _buildOptionCard(
              context,
              icon: Icons.folder_open,
              title: 'Assign Existing Program',
              subtitle: 'Copy a program from another trainee',
              onTap: () => _showExistingProgramsSheet(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateNewProgramDialog(BuildContext context) {
    final theme = Theme.of(context);
    String programName = '';
    int durationWeeks = 4;
    String difficulty = 'intermediate';
    String goal = 'build_muscle';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Create New Program',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Program name
              TextField(
                decoration: InputDecoration(
                  labelText: 'Program Name',
                  hintText: 'e.g., Strength Building Phase 1',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) => programName = value,
              ),
              const SizedBox(height: 16),

              // Duration slider
              Text('Duration: $durationWeeks weeks'),
              Slider(
                value: durationWeeks.toDouble(),
                min: 1,
                max: 16,
                divisions: 15,
                label: '$durationWeeks weeks',
                onChanged: (value) {
                  setModalState(() => durationWeeks = value.round());
                },
              ),
              const SizedBox(height: 16),

              // Difficulty
              const Text('Difficulty', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Beginner'),
                    selected: difficulty == 'beginner',
                    onSelected: (selected) {
                      setModalState(() => difficulty = 'beginner');
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Intermediate'),
                    selected: difficulty == 'intermediate',
                    onSelected: (selected) {
                      setModalState(() => difficulty = 'intermediate');
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Advanced'),
                    selected: difficulty == 'advanced',
                    onSelected: (selected) {
                      setModalState(() => difficulty = 'advanced');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Goal
              const Text('Goal', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ProgramGoals.all.map((g) => ChoiceChip(
                  label: Text(ProgramGoals.displayName(g)),
                  selected: goal == g,
                  onSelected: (selected) {
                    setModalState(() => goal = g);
                  },
                )).toList(),
              ),
              const SizedBox(height: 24),

              // Create button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: programName.isEmpty ? null : () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProgramBuilderScreen(
                          traineeId: widget.traineeId,
                          templateName: programName,
                          durationWeeks: durationWeeks,
                          difficulty: difficulty,
                          goal: goal,
                        ),
                      ),
                    ).then((result) {
                      if (result == true && mounted) {
                        // Program was saved, go back
                        context.pop();
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Create Program'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTemplatesSheet(BuildContext context) {
    final theme = Theme.of(context);
    // Default templates list
    final templates = [
      _ProgramTemplate(
        name: 'Push Pull Legs (PPL)',
        description: '6-day split focusing on pushing, pulling, and leg movements.',
        durationWeeks: 8,
        difficulty: 'intermediate',
        goal: 'build_muscle',
        daysPerWeek: 6,
        schedule: ['Push', 'Pull', 'Legs', 'Push', 'Pull', 'Legs', 'Rest'],
        icon: '💪',
      ),
      _ProgramTemplate(
        name: 'Upper Lower Split',
        description: '4-day split alternating between upper and lower body.',
        durationWeeks: 6,
        difficulty: 'intermediate',
        goal: 'build_muscle',
        daysPerWeek: 4,
        schedule: ['Upper', 'Lower', 'Rest', 'Upper', 'Lower', 'Rest', 'Rest'],
        icon: '🏋️',
      ),
      _ProgramTemplate(
        name: 'Full Body 3x/Week',
        description: 'Train your entire body 3 times per week. Ideal for beginners.',
        durationWeeks: 4,
        difficulty: 'beginner',
        goal: 'build_muscle',
        daysPerWeek: 3,
        schedule: ['Full Body', 'Rest', 'Full Body', 'Rest', 'Full Body', 'Rest', 'Rest'],
        icon: '🎯',
      ),
      _ProgramTemplate(
        name: 'Strength Focus 5x5',
        description: 'Classic 5x5 strength program focusing on compound lifts.',
        durationWeeks: 12,
        difficulty: 'intermediate',
        goal: 'strength',
        daysPerWeek: 3,
        schedule: ['Squat/Bench', 'Rest', 'Deadlift/OHP', 'Rest', 'Squat/Bench', 'Rest', 'Rest'],
        icon: '🏆',
      ),
      _ProgramTemplate(
        name: 'Fat Loss Circuit',
        description: 'High-intensity circuit training for maximum calorie burn.',
        durationWeeks: 6,
        difficulty: 'intermediate',
        goal: 'fat_loss',
        daysPerWeek: 4,
        schedule: ['Circuit A', 'Rest', 'Circuit B', 'HIIT', 'Circuit A', 'Rest', 'Rest'],
        icon: '🔥',
      ),
      _ProgramTemplate(
        name: 'Beginner Full Body',
        description: 'Perfect starting point for new lifters.',
        durationWeeks: 4,
        difficulty: 'beginner',
        goal: 'build_muscle',
        daysPerWeek: 3,
        schedule: ['Workout A', 'Rest', 'Workout B', 'Rest', 'Workout A', 'Rest', 'Rest'],
        icon: '🌱',
      ),
      _ProgramTemplate(
        name: 'Bro Split',
        description: 'Classic 5-day bodybuilding split. One muscle group per day.',
        durationWeeks: 8,
        difficulty: 'intermediate',
        goal: 'build_muscle',
        daysPerWeek: 5,
        schedule: ['Chest', 'Back', 'Shoulders', 'Legs', 'Arms', 'Rest', 'Rest'],
        icon: '💥',
      ),
      _ProgramTemplate(
        name: 'Powerbuilding',
        description: 'Combines powerlifting and bodybuilding for strength and size.',
        durationWeeks: 10,
        difficulty: 'advanced',
        goal: 'strength',
        daysPerWeek: 4,
        schedule: ['Squat Day', 'Bench Day', 'Rest', 'Deadlift Day', 'Upper Acc', 'Rest', 'Rest'],
        icon: '⚡',
      ),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Choose a Template',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Select a template to customize for your trainee',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final template = templates[index];
                  return _buildTemplateCard(context, template);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, _ProgramTemplate template) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          _showTemplatePreview(context, template);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    template.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      template.description,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildMiniTag('${template.durationWeeks}w', Colors.blue),
                        const SizedBox(width: 6),
                        _buildMiniTag('${template.daysPerWeek}x/wk', Colors.green),
                        const SizedBox(width: 6),
                        _buildMiniTag(template.difficulty, _getDifficultyColor(template.difficulty)),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showTemplatePreview(BuildContext context, _ProgramTemplate template) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    template.icon,
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildMiniTag(template.difficulty, _getDifficultyColor(template.difficulty)),
                            const SizedBox(width: 8),
                            _buildMiniTag(ProgramGoals.displayName(template.goal), Colors.purple),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(template.description, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 24),

              // Stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(context, 'Duration', '${template.durationWeeks} weeks', Icons.calendar_today),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(context, 'Frequency', '${template.daysPerWeek}x/week', Icons.repeat),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Weekly Schedule
              const Text(
                'Weekly Schedule',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ...template.schedule.asMap().entries.map((entry) {
                final dayLabel = 'Day ${entry.key + 1}';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: entry.value == 'Rest' ? Colors.grey.withValues(alpha: 0.1) : theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Text(
                          dayLabel,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Icon(
                        entry.value == 'Rest' ? Icons.bed : Icons.fitness_center,
                        size: 18,
                        color: entry.value == 'Rest' ? Colors.grey : theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(entry.value),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showTemplatesSheet(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProgramBuilderScreen(
                              traineeId: widget.traineeId,
                              templateName: template.name,
                              durationWeeks: template.durationWeeks,
                              difficulty: template.difficulty,
                              goal: template.goal,
                              weeklySchedule: template.schedule,
                            ),
                          ),
                        ).then((result) {
                          if (result == true && mounted) {
                            context.pop();
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Use This Template'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  void _showExistingProgramsSheet(BuildContext context) {
    final theme = Theme.of(context);
    final existingPrograms = ref.read(programTemplatesProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Existing Programs',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Copy a program you\'ve already created',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: existingPrograms.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('Could not load programs', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
                data: (programs) {
                  if (programs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            'No Existing Programs',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create a program first, then you can reuse it',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showCreateNewProgramDialog(context);
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Create New Program'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: programs.length,
                    itemBuilder: (context, index) {
                      final program = programs[index];
                      return _buildExistingProgramCard(context, program);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingProgramCard(BuildContext context, ProgramTemplateModel program) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: InkWell(
        onTap: () => _assignExistingProgram(context, program),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.calendar_month, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      program.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildMiniTag('${program.durationWeeks}w', Colors.blue),
                        const SizedBox(width: 6),
                        _buildMiniTag(program.difficultyDisplay, _getDifficultyColor(program.difficultyLevel)),
                        const SizedBox(width: 6),
                        _buildMiniTag(program.goalTypeDisplay, Colors.purple),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _assignExistingProgram(context, program),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Assign'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _assignExistingProgram(BuildContext context, ProgramTemplateModel program) {
    DateTime selectedStartDate = DateTime.now();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final endDate = selectedStartDate.add(Duration(days: program.durationWeeks * 7));

          return AlertDialog(
            title: const Text('Assign Program'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Assign "${program.name}" to this trainee?'),
                const SizedBox(height: 20),
                // Start date picker
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start Date',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(selectedStartDate),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: dialogContext,
                                initialDate: selectedStartDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setDialogState(() => selectedStartDate = picked);
                              }
                            },
                            child: const Text('Change'),
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'End Date',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                          Text(
                            _formatDate(endDate),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext); // Close dialog
                  Navigator.pop(context); // Close sheet

                  try {
                    final apiClient = ref.read(apiClientProvider);

                    // End current program if one exists
                    final trainee = ref.read(traineeDetailProvider(widget.traineeId)).valueOrNull;
                    if (trainee != null && trainee.programs.isNotEmpty) {
                      final currentProgram = trainee.programs.first;
                      await apiClient.dio.delete(ApiConstants.programDetail(currentProgram.id));
                    }

                    // Assign the new program
                    await apiClient.dio.post(
                      ApiConstants.assignProgramTemplate(program.id),
                      data: {
                        'trainee_id': widget.traineeId,
                        'start_date': '${selectedStartDate.year}-${selectedStartDate.month.toString().padLeft(2, '0')}-${selectedStartDate.day.toString().padLeft(2, '0')}',
                      },
                    );

                    if (mounted) {
                      // Invalidate the trainee detail provider to refresh the data
                      ref.invalidate(traineeDetailProvider(widget.traineeId));

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('"${program.name}" assigned successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      context.pop(); // Go back to trainee detail
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to assign program: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Assign'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _ProgramTemplate {
  final String name;
  final String description;
  final int durationWeeks;
  final String difficulty;
  final String goal;
  final int daysPerWeek;
  final List<String> schedule;
  final String icon;

  const _ProgramTemplate({
    required this.name,
    required this.description,
    required this.durationWeeks,
    required this.difficulty,
    required this.goal,
    required this.daysPerWeek,
    required this.schedule,
    required this.icon,
  });
}

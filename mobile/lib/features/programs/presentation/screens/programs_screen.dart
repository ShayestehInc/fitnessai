import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/program_model.dart';
import '../providers/program_provider.dart';
import 'program_builder_screen.dart';

class ProgramsScreen extends ConsumerStatefulWidget {
  const ProgramsScreen({super.key});

  @override
  ConsumerState<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends ConsumerState<ProgramsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedGoal; // null means "All"

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Default program templates (hardcoded for now)
  final List<_DefaultTemplate> _defaultTemplates = [
    _DefaultTemplate(
      name: 'Push Pull Legs (PPL)',
      description: '6-day split focusing on pushing, pulling, and leg movements. Great for intermediate to advanced lifters.',
      durationWeeks: 8,
      difficulty: 'intermediate',
      goal: 'build_muscle',
      daysPerWeek: 6,
      schedule: ['Push', 'Pull', 'Legs', 'Push', 'Pull', 'Legs', 'Rest'],
    ),
    _DefaultTemplate(
      name: 'Upper Lower Split',
      description: '4-day split alternating between upper and lower body. Perfect balance of volume and recovery.',
      durationWeeks: 6,
      difficulty: 'intermediate',
      goal: 'build_muscle',
      daysPerWeek: 4,
      schedule: ['Upper', 'Lower', 'Rest', 'Upper', 'Lower', 'Rest', 'Rest'],
    ),
    _DefaultTemplate(
      name: 'Full Body 3x/Week',
      description: 'Train your entire body 3 times per week. Ideal for beginners or those short on time.',
      durationWeeks: 4,
      difficulty: 'beginner',
      goal: 'build_muscle',
      daysPerWeek: 3,
      schedule: ['Full Body', 'Rest', 'Full Body', 'Rest', 'Full Body', 'Rest', 'Rest'],
    ),
    _DefaultTemplate(
      name: 'Bro Split',
      description: 'Classic 5-day bodybuilding split. One muscle group per day for maximum focus.',
      durationWeeks: 8,
      difficulty: 'intermediate',
      goal: 'build_muscle',
      daysPerWeek: 5,
      schedule: ['Chest', 'Back', 'Shoulders', 'Legs', 'Arms', 'Rest', 'Rest'],
    ),
    _DefaultTemplate(
      name: 'Strength Focus 5x5',
      description: 'Classic 5x5 strength program focusing on compound lifts. Build raw strength and power.',
      durationWeeks: 12,
      difficulty: 'intermediate',
      goal: 'strength',
      daysPerWeek: 3,
      schedule: ['Squat/Bench', 'Rest', 'Deadlift/OHP', 'Rest', 'Squat/Bench', 'Rest', 'Rest'],
    ),
    _DefaultTemplate(
      name: 'Fat Loss Circuit',
      description: 'High-intensity circuit training designed for maximum calorie burn and fat loss.',
      durationWeeks: 6,
      difficulty: 'intermediate',
      goal: 'fat_loss',
      daysPerWeek: 4,
      schedule: ['Circuit A', 'Rest', 'Circuit B', 'HIIT', 'Circuit A', 'Rest', 'Rest'],
    ),
    _DefaultTemplate(
      name: 'Beginner Full Body',
      description: 'Perfect starting point for new lifters. Learn the basics with full body workouts.',
      durationWeeks: 4,
      difficulty: 'beginner',
      goal: 'build_muscle',
      daysPerWeek: 3,
      schedule: ['Workout A', 'Rest', 'Workout B', 'Rest', 'Workout A', 'Rest', 'Rest'],
    ),
    _DefaultTemplate(
      name: 'Advanced PPL (6-Day)',
      description: 'High volume PPL for advanced lifters looking to maximize hypertrophy.',
      durationWeeks: 8,
      difficulty: 'advanced',
      goal: 'build_muscle',
      daysPerWeek: 6,
      schedule: ['Push', 'Pull', 'Legs', 'Push', 'Pull', 'Legs', 'Rest'],
    ),
    _DefaultTemplate(
      name: 'Powerbuilding',
      description: 'Combines powerlifting and bodybuilding. Heavy compounds + hypertrophy accessories.',
      durationWeeks: 10,
      difficulty: 'advanced',
      goal: 'strength',
      daysPerWeek: 4,
      schedule: ['Squat Day', 'Bench Day', 'Rest', 'Deadlift Day', 'Upper Acc', 'Rest', 'Rest'],
    ),
    _DefaultTemplate(
      name: 'Recomp Protocol',
      description: 'Build muscle while losing fat. Strategic combination of lifting and cardio.',
      durationWeeks: 8,
      difficulty: 'intermediate',
      goal: 'recomp',
      daysPerWeek: 5,
      schedule: ['Upper', 'Lower', 'HIIT', 'Upper', 'Lower', 'LISS', 'Rest'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(programTemplatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Programs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateProgramDialog(context),
            tooltip: 'Create Program',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Templates'),
            Tab(text: 'My Programs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTemplatesTab(context, templatesAsync),
          _buildMyProgramsTab(context),
        ],
      ),
    );
  }

  Widget _buildTemplatesTab(BuildContext context, AsyncValue<List<ProgramTemplateModel>> templatesAsync) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(programTemplatesProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.1),
                  theme.colorScheme.primary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.calendar_month, color: theme.colorScheme.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Program Templates',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Choose a template or create your own',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Goal Filter
          Text(
            'Filter by Goal',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildGoalChip(context, 'All', null, _selectedGoal == null),
                ...ProgramGoals.all.map((goal) => _buildGoalChip(
                  context,
                  ProgramGoals.displayName(goal),
                  goal,
                  _selectedGoal == goal,
                )),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Default Templates
          Text(
            'Popular Templates',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          ..._filteredTemplates.map((template) => _buildTemplateCard(context, template)),

          // Custom Templates from API
          templatesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => const SizedBox(),
            data: (templates) {
              if (templates.isEmpty) return const SizedBox();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'Custom Templates',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...templates.map((t) => _buildApiTemplateCard(context, t)),
                ],
              );
            },
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  List<_DefaultTemplate> get _filteredTemplates {
    if (_selectedGoal == null) {
      return _defaultTemplates;
    }
    return _defaultTemplates.where((t) => t.goal == _selectedGoal).toList();
  }

  Widget _buildGoalChip(BuildContext context, String label, String? goal, bool isSelected) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedGoal = selected ? goal : null;
          });
        },
        selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, _DefaultTemplate template) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showTemplateDetail(context, template),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getGoalColor(template.goal).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      ProgramGoals.icon(template.goal),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildTag(context, template.difficulty, _getDifficultyColor(template.difficulty)),
                            const SizedBox(width: 8),
                            _buildTag(context, '${template.durationWeeks} weeks', Colors.blue),
                            const SizedBox(width: 8),
                            _buildTag(context, '${template.daysPerWeek}x/week', Colors.green),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: theme.textTheme.bodySmall?.color),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                template.description,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Weekly schedule preview
              Row(
                children: template.schedule.asMap().entries.map((entry) {
                  final dayNumber = '${entry.key + 1}';
                  final isRest = entry.value == 'Rest';
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isRest
                            ? theme.dividerColor.withValues(alpha: 0.3)
                            : theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        children: [
                          Text(
                            dayNumber,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isRest ? theme.textTheme.bodySmall?.color : theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Icon(
                            isRest ? Icons.bed : Icons.fitness_center,
                            size: 12,
                            color: isRest ? theme.textTheme.bodySmall?.color : theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApiTemplateCard(BuildContext context, ProgramTemplateModel template) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.calendar_month, color: theme.colorScheme.primary),
        ),
        title: Text(template.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text('${template.durationWeeks} weeks • ${template.difficultyDisplay}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // TODO: Show template detail
        },
      ),
    );
  }

  Widget _buildTag(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getGoalColor(String goal) {
    switch (goal) {
      case 'build_muscle': return Colors.purple;
      case 'fat_loss': return Colors.orange;
      case 'strength': return Colors.red;
      case 'endurance': return Colors.blue;
      case 'recomp': return Colors.teal;
      default: return Theme.of(context).colorScheme.primary;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'beginner': return Colors.green;
      case 'intermediate': return Colors.orange;
      case 'advanced': return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildMyProgramsTab(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: theme.textTheme.bodySmall?.color),
          const SizedBox(height: 16),
          Text(
            'No Custom Programs Yet',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Create your own program templates',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateProgramDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Program'),
          ),
        ],
      ),
    );
  }

  void _showTemplateDetail(BuildContext context, _DefaultTemplate template) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
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
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    ProgramGoals.icon(template.goal),
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildTag(context, template.difficulty, _getDifficultyColor(template.difficulty)),
                            const SizedBox(width: 8),
                            _buildTag(context, ProgramGoals.displayName(template.goal), _getGoalColor(template.goal)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(template.description),
              const SizedBox(height: 24),

              // Stats
              Row(
                children: [
                  Expanded(child: _buildStatCard(context, 'Duration', '${template.durationWeeks} weeks', Icons.calendar_today)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard(context, 'Frequency', '${template.daysPerWeek}x/week', Icons.repeat)),
                ],
              ),

              const SizedBox(height: 24),

              // Weekly Schedule
              Text(
                'Weekly Schedule',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...template.schedule.asMap().entries.map((entry) {
                final dayLabel = 'Day ${entry.key + 1}';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: entry.value == 'Rest'
                        ? theme.dividerColor.withValues(alpha: 0.3)
                        : theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          dayLabel,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Icon(
                        entry.value == 'Rest' ? Icons.bed : Icons.fitness_center,
                        size: 18,
                        color: entry.value == 'Rest' ? theme.textTheme.bodySmall?.color : theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(entry.value),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 32),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProgramBuilderScreen(
                              templateName: template.name,
                              durationWeeks: template.durationWeeks,
                              difficulty: template.difficulty,
                              goal: template.goal,
                              weeklySchedule: template.schedule,
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Customize'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProgramBuilderScreen(
                              templateName: template.name,
                              durationWeeks: template.durationWeeks,
                              difficulty: template.difficulty,
                              goal: template.goal,
                              weeklySchedule: template.schedule,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Use Template'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
        color: theme.dividerColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  void _showCreateProgramDialog(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Create New Program',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'How would you like to start?',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),

            // Use Template option
            _buildCreateOption(
              context: context,
              icon: Icons.content_copy,
              title: 'Use a Template',
              subtitle: 'Start with a proven program structure and customize it',
              color: theme.colorScheme.primary,
              onTap: () {
                Navigator.pop(context);
                _showTemplatePickerDialog(context);
              },
            ),
            const SizedBox(height: 12),

            // Start from Scratch option
            _buildCreateOption(
              context: context,
              icon: Icons.add_circle_outline,
              title: 'Start from Scratch',
              subtitle: 'Build a completely custom program from the ground up',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                _showNewProgramSetupDialog(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }

  void _showTemplatePickerDialog(BuildContext context) {
    final theme = Theme.of(context);

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
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Choose a Template',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select a template to customize',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _defaultTemplates.length,
                itemBuilder: (context, index) {
                  final template = _defaultTemplates[index];
                  return _buildTemplatePickerCard(context, template);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatePickerCard(BuildContext context, _DefaultTemplate template) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          // Navigate to builder with template pre-filled
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProgramBuilderScreen(
                templateName: template.name,
                durationWeeks: template.durationWeeks,
                difficulty: template.difficulty,
                goal: template.goal,
                weeklySchedule: template.schedule,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getGoalColor(template.goal).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  ProgramGoals.icon(template.goal),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildTag(context, template.difficulty, _getDifficultyColor(template.difficulty)),
                        const SizedBox(width: 8),
                        _buildTag(context, '${template.durationWeeks} weeks', Colors.blue),
                        const SizedBox(width: 8),
                        _buildTag(context, '${template.daysPerWeek}x/week', Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.textTheme.bodySmall?.color),
            ],
          ),
        ),
      ),
    );
  }

  void _showNewProgramSetupDialog(BuildContext context) {
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
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Create New Program',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Program name
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Program Name',
                  hintText: 'e.g., My Custom PPL',
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
              const Text('Difficulty'),
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
              const Text('Goal'),
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
                          templateName: programName,
                          durationWeeks: durationWeeks,
                          difficulty: difficulty,
                          goal: goal,
                        ),
                      ),
                    );
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
}

class _DefaultTemplate {
  final String name;
  final String description;
  final int durationWeeks;
  final String difficulty;
  final String goal;
  final int daysPerWeek;
  final List<String> schedule;

  const _DefaultTemplate({
    required this.name,
    required this.description,
    required this.durationWeeks,
    required this.difficulty,
    required this.goal,
    required this.daysPerWeek,
    required this.schedule,
  });
}

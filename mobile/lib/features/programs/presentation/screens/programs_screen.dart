import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/program_model.dart';
import '../../data/models/program_week_model.dart';
import '../providers/program_provider.dart';
import 'program_builder_screen.dart';
import '../../../workout_log/presentation/screens/workout_calendar_screen.dart';
import '../../../trainer/presentation/providers/trainer_provider.dart';

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
            Tab(text: 'My Programs'),
            Tab(text: 'Templates'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyProgramsTab(context),
          _buildTemplatesTab(context),
        ],
      ),
    );
  }

  Widget _buildTemplatesTab(BuildContext context) {
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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showTemplateDetail(context, template),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail image
            SizedBox(
              height: 120,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    ProgramGoals.imageUrl(template.goal),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: _getGoalColor(template.goal).withValues(alpha: 0.2),
                      child: Icon(Icons.fitness_center, size: 40, color: _getGoalColor(template.goal)),
                    ),
                  ),
                  // Gradient overlay for text readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  // Title and tags on image
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
          ],
        ),
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
    final programsAsync = ref.watch(trainerProgramsProvider);
    final draftsAsync = ref.watch(myTemplatesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(trainerProgramsProvider);
        ref.invalidate(myTemplatesProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Draft Programs Section (unassigned)
          Text(
            'Draft Programs',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Programs you\'ve created but not yet assigned',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),

          draftsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: $error'),
            ),
            data: (drafts) {
              if (drafts.isEmpty) {
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.drafts_outlined, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        const Text(
                          'No draft programs',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Create a program and save it as a template',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: drafts.map((draft) => _buildDraftProgramCard(context, draft, ref)).toList(),
              );
            },
          ),

          const SizedBox(height: 24),

          // Active Programs Section
          Text(
            'Active Trainee Programs',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Programs currently assigned to your trainees',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),

          programsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Error loading programs: $error'),
              ),
            ),
            data: (programs) {
              // Filter active programs and ensure one per trainee (most recent)
              final activePrograms = programs.where((p) => p.isActive).toList();
              final seenTrainees = <int>{};
              final uniqueActivePrograms = activePrograms.where((p) {
                if (p.traineeId == null) return true;
                if (seenTrainees.contains(p.traineeId)) return false;
                seenTrainees.add(p.traineeId!);
                return true;
              }).toList();

              if (uniqueActivePrograms.isEmpty) {
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        const Text(
                          'No active programs',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Assign programs to your trainees to see them here',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: uniqueActivePrograms.map((program) => _buildProgramCard(context, program)).toList(),
              );
            },
          ),

          const SizedBox(height: 24),

          // Previous Programs Section (ended/inactive)
          Text(
            'Previous Programs',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Programs that have ended or been deactivated',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),

          programsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (error, stack) => const SizedBox.shrink(),
            data: (programs) {
              final previousPrograms = programs.where((p) => !p.isActive).toList();

              if (previousPrograms.isEmpty) {
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.history, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        const Text(
                          'No previous programs',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ended programs will appear here',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: previousPrograms.map((program) => _buildProgramCard(context, program)).toList(),
              );
            },
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildDraftProgramCard(BuildContext context, ProgramTemplateModel draft, WidgetRef ref) {
    final theme = Theme.of(context);

    // Parse schedule to get days per week
    int daysPerWeek = 0;
    List<String> schedule = [];
    if (draft.scheduleTemplate != null) {
      try {
        List<dynamic>? weeksData;
        if (draft.scheduleTemplate is List && (draft.scheduleTemplate as List).isNotEmpty) {
          weeksData = draft.scheduleTemplate as List;
        } else if (draft.scheduleTemplate is Map<String, dynamic>) {
          weeksData = draft.scheduleTemplate['weeks'] as List<dynamic>?;
        }
        if (weeksData != null && weeksData.isNotEmpty) {
          final firstWeek = weeksData.first as Map<String, dynamic>;
          final days = firstWeek['days'] as List<dynamic>?;
          if (days != null) {
            daysPerWeek = days.where((d) => d['is_rest_day'] != true).length;
            schedule = days.map((d) {
              if (d['is_rest_day'] == true) return 'Rest';
              return d['name']?.toString() ?? 'Workout';
            }).toList();
          }
        }
      } catch (e) {
        // Ignore parsing errors
      }
    }

    return Dismissible(
      key: ValueKey('draft_${draft.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Draft?'),
            content: Text('Are you sure you want to delete "${draft.name}"? This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (direction) async {
        final repository = ref.read(programRepositoryProvider);
        final result = await repository.deleteTemplate(draft.id);

        if (context.mounted) {
          if (result['success'] == true) {
            ref.invalidate(myTemplatesProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('"${draft.name}" deleted'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['error'] ?? 'Failed to delete'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _editDraftProgram(context, draft),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail image with overlay
              SizedBox(
                height: 120,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      draft.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: _getGoalColor(draft.goalType).withValues(alpha: 0.2),
                        child: Icon(Icons.fitness_center, size: 40, color: _getGoalColor(draft.goalType)),
                      ),
                    ),
                    // Gradient overlay for text readability
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                    // Title and tags on image
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            draft.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildTag(context, draft.difficultyLevel, _getDifficultyColor(draft.difficultyLevel)),
                              const SizedBox(width: 8),
                              _buildTag(context, '${draft.durationWeeks} weeks', Colors.blue),
                              if (daysPerWeek > 0) ...[
                                const SizedBox(width: 8),
                                _buildTag(context, '${daysPerWeek}x/week', Colors.green),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // DRAFT badge and more options
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'DRAFT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // More options button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                          tooltip: 'More options',
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _editDraftProgram(context, draft);
                                break;
                              case 'rename':
                                _showRenameProgramDialog(context, draft.id, draft.name, isTemplate: true);
                                break;
                              case 'edit_image':
                                _showEditProgramImageDialog(context, draft.id, draft.name, draft.imageUrl, isTemplate: true);
                                break;
                              case 'assign':
                                _showTraineeSelectionForDraft(context, draft);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                leading: Icon(Icons.edit_outlined),
                                title: Text('Edit'),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'rename',
                              child: ListTile(
                                leading: Icon(Icons.drive_file_rename_outline),
                                title: Text('Rename'),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'edit_image',
                              child: ListTile(
                                leading: Icon(Icons.image_outlined),
                                title: Text('Edit Image'),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'assign',
                              child: ListTile(
                                leading: Icon(Icons.person_add_outlined, color: theme.colorScheme.primary),
                                title: const Text('Assign to Trainee'),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (draft.description != null && draft.description!.isNotEmpty) ...[
                      Text(
                        draft.description!,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Weekly schedule preview
                    if (schedule.isNotEmpty)
                      Row(
                        children: schedule.asMap().entries.map((entry) {
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
                      )
                    else
                      Text(
                        'Tap to configure workouts',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editDraftProgram(BuildContext context, ProgramTemplateModel draft) {
    // Parse existing weeks from schedule_template
    List<ProgramWeek>? existingWeeks;
    if (draft.scheduleTemplate != null) {
      try {
        final scheduleData = draft.scheduleTemplate;
        List<dynamic>? weeksData;
        if (scheduleData is List) {
          weeksData = scheduleData;
        } else if (scheduleData is Map<String, dynamic>) {
          weeksData = scheduleData['weeks'] as List<dynamic>?;
        }
        if (weeksData != null && weeksData.isNotEmpty) {
          existingWeeks = weeksData
              .map((w) => ProgramWeek.fromJson(w as Map<String, dynamic>))
              .toList();
        }
      } catch (e) {
        debugPrint('Error parsing schedule template: $e');
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProgramBuilderScreen(
          templateName: draft.name,
          durationWeeks: draft.durationWeeks,
          difficulty: draft.difficultyLevel,
          goal: draft.goalType,
          existingTemplateId: draft.id,
          existingWeeks: existingWeeks,
        ),
      ),
    );
  }

  void _showTraineeSelectionForDraft(BuildContext context, ProgramTemplateModel draft) {
    // Convert to _DefaultTemplate format for the existing dialog
    final template = _DefaultTemplate(
      name: draft.name,
      description: draft.description ?? '',
      durationWeeks: draft.durationWeeks,
      difficulty: draft.difficultyLevel,
      goal: draft.goalType,
      daysPerWeek: 5, // Default
      schedule: [],
    );
    _showTraineeSelectionDialog(context, template);
  }

  Widget _buildProgramCard(BuildContext context, TraineeProgramModel program) {
    final theme = Theme.of(context);
    final isActive = program.isActive;
    final schedule = program.weekSchedule;
    final daysPerWeek = program.daysPerWeek;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkoutCalendarScreen(
                traineeId: program.traineeId,
                programId: program.id,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail image with overlay
            SizedBox(
              height: 120,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    program.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: _getGoalColor(program.goalType ?? 'build_muscle').withValues(alpha: 0.2),
                      child: Icon(Icons.fitness_center, size: 40, color: _getGoalColor(program.goalType ?? 'build_muscle')),
                    ),
                  ),
                  // Gradient overlay for text readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  // Title and tags on image
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          program.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (program.difficultyLevel != null)
                              _buildTag(context, program.difficultyLevel!, _getDifficultyColor(program.difficultyLevel!)),
                            if (program.durationWeeks != null) ...[
                              const SizedBox(width: 8),
                              _buildTag(context, '${program.durationWeeks} weeks', Colors.blue),
                            ],
                            if (daysPerWeek > 0) ...[
                              const SizedBox(width: 8),
                              _buildTag(context, '${daysPerWeek}x/week', Colors.green),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // ACTIVE badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isActive ? 'ACTIVE' : 'INACTIVE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // More options button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                        tooltip: 'More options',
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _editProgram(context, program);
                              break;
                            case 'rename':
                              _showRenameProgramDialog(context, program.id, program.name, isTemplate: false);
                              break;
                            case 'edit_image':
                              _showEditProgramImageDialog(context, program.id, program.name, program.imageUrl, isTemplate: false);
                              break;
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit_outlined),
                              title: Text('Edit'),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'rename',
                            child: ListTile(
                              leading: Icon(Icons.drive_file_rename_outline),
                              title: Text('Rename'),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'edit_image',
                            child: ListTile(
                              leading: Icon(Icons.image_outlined),
                              title: Text('Edit Image'),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trainee name
                  if (program.traineeName != null || program.traineeEmail != null) ...[
                    Row(
                      children: [
                        Icon(Icons.person, size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          program.traineeName ?? program.traineeEmail ?? 'Unknown',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Description
                  if (program.description != null && program.description!.isNotEmpty) ...[
                    Text(
                      program.description!,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Weekly schedule preview
                  if (schedule.isNotEmpty)
                    Row(
                      children: schedule.asMap().entries.map((entry) {
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
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Tap to view workout calendar',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        Icon(Icons.chevron_right, color: theme.textTheme.bodySmall?.color, size: 20),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editProgram(BuildContext context, TraineeProgramModel program) {
    // Navigate to program builder with existing program data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProgramBuilderScreen(
          traineeId: program.traineeId,
          templateName: program.name,
          // Pass schedule data if available
        ),
      ),
    );
  }

  void _showRenameProgramDialog(BuildContext context, int programId, String currentName, {required bool isTemplate}) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Program'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Program Name',
            hintText: 'Enter new name',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Name cannot be empty'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              // Call API to rename
              final repository = ref.read(programRepositoryProvider);
              Map<String, dynamic> result;

              if (isTemplate) {
                result = await repository.renameTemplate(programId, newName);
              } else {
                result = await repository.renameProgram(programId, newName);
              }

              if (context.mounted) {
                if (result['success'] == true) {
                  // Refresh the lists
                  ref.invalidate(myTemplatesProvider);
                  ref.invalidate(trainerProgramsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Renamed to "$newName"'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['error'] ?? 'Failed to rename'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showEditProgramImageDialog(BuildContext context, int programId, String programName, String? currentImageUrl, {required bool isTemplate}) {
    final theme = Theme.of(context);
    final imageUrlController = TextEditingController(text: currentImageUrl ?? '');
    bool isLoading = false;
    bool isUploading = false;
    String? previewUrl = currentImageUrl;
    File? selectedImageFile;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
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
                  'Edit Program Image',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  programName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 24),

                // Current/Preview image
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 200,
                      height: 150,
                      child: selectedImageFile != null
                          ? Image.file(
                              selectedImageFile!,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              previewUrl ?? ProgramGoals.imageUrl(ProgramGoals.generalFitness),
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  child: const Center(child: CircularProgressIndicator()),
                                );
                              },
                              errorBuilder: (_, __, ___) => Container(
                                color: theme.colorScheme.errorContainer,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, color: theme.colorScheme.error, size: 32),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Invalid URL',
                                      style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Upload from Gallery button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isLoading || isUploading
                        ? null
                        : () async {
                            final picker = ImagePicker();
                            final pickedFile = await picker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 1920,
                              maxHeight: 1080,
                              imageQuality: 85,
                            );

                            if (pickedFile != null) {
                              setDialogState(() {
                                selectedImageFile = File(pickedFile.path);
                                previewUrl = null;
                                imageUrlController.clear();
                              });
                            }
                          },
                    icon: const Icon(Icons.photo_library),
                    label: Text(selectedImageFile != null ? 'Change Image' : 'Upload from Gallery'),
                  ),
                ),

                if (selectedImageFile != null) ...[
                  const SizedBox(height: 12),
                  // Upload button when image is selected
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isUploading
                          ? null
                          : () async {
                              setDialogState(() => isUploading = true);

                              final repository = ref.read(programRepositoryProvider);
                              final result = await repository.uploadProgramImage(
                                programId,
                                selectedImageFile!,
                                isTemplate: isTemplate,
                              );

                              if (!context.mounted) return;

                              if (result['success'] == true) {
                                Navigator.pop(context);
                                ref.invalidate(myTemplatesProvider);
                                ref.invalidate(trainerProgramsProvider);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Image uploaded successfully'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                setDialogState(() => isUploading = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result['error'] ?? 'Failed to upload image'),
                                    backgroundColor: theme.colorScheme.error,
                                  ),
                                );
                              }
                            },
                      icon: isUploading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.cloud_upload),
                      label: Text(isUploading ? 'Uploading...' : 'Upload Image'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setDialogState(() {
                          selectedImageFile = null;
                        });
                      },
                      child: const Text('Clear selection'),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Divider with "OR" text
                Row(
                  children: [
                    Expanded(child: Divider(color: theme.dividerColor)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: theme.dividerColor)),
                  ],
                ),
                const SizedBox(height: 16),

                // Image URL input
                TextField(
                  controller: imageUrlController,
                  enabled: selectedImageFile == null,
                  decoration: InputDecoration(
                    labelText: 'Image URL',
                    hintText: 'https://images.unsplash.com/...',
                    prefixIcon: const Icon(Icons.link),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.preview),
                      tooltip: 'Preview',
                      onPressed: selectedImageFile == null
                          ? () {
                              final url = imageUrlController.text.trim();
                              if (url.isNotEmpty) {
                                setDialogState(() => previewUrl = url);
                              }
                            }
                          : null,
                    ),
                  ),
                  keyboardType: TextInputType.url,
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty && selectedImageFile == null) {
                      setDialogState(() => previewUrl = value.trim());
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Tip: Use Unsplash or Pexels for free high-quality images',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: (isLoading || isUploading || selectedImageFile != null)
                            ? null
                            : () async {
                                final newUrl = imageUrlController.text.trim();

                                setDialogState(() => isLoading = true);

                                final repository = ref.read(programRepositoryProvider);
                                Map<String, dynamic> result;

                                if (isTemplate) {
                                  result = await repository.updateTemplateImage(programId, newUrl.isEmpty ? null : newUrl);
                                } else {
                                  result = await repository.updateProgramImage(programId, newUrl.isEmpty ? null : newUrl);
                                }

                                if (!context.mounted) return;

                                if (result['success'] == true) {
                                  Navigator.pop(context);
                                  ref.invalidate(myTemplatesProvider);
                                  ref.invalidate(trainerProgramsProvider);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Image updated'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  setDialogState(() => isLoading = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(result['error'] ?? 'Failed to update image'),
                                      backgroundColor: theme.colorScheme.error,
                                    ),
                                  );
                                }
                              },
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save URL'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTemplateDetail(BuildContext context, _DefaultTemplate template) {
    final theme = Theme.of(context);
    // Capture the parent context before showing the bottom sheet
    final parentContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
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
                            _buildTag(parentContext, template.difficulty, _getDifficultyColor(template.difficulty)),
                            const SizedBox(width: 8),
                            _buildTag(parentContext, ProgramGoals.displayName(template.goal), _getGoalColor(template.goal)),
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
                  Expanded(child: _buildStatCard(parentContext, 'Duration', '${template.durationWeeks} weeks', Icons.calendar_today)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard(parentContext, 'Frequency', '${template.daysPerWeek}x/week', Icons.repeat)),
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
                        Navigator.pop(sheetContext);
                        // Customize without assigning to a trainee (save as template)
                        if (parentContext.mounted) {
                          Navigator.push(
                            parentContext,
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
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Draft to My Programs'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        // Show trainee selection before using template
                        if (parentContext.mounted) {
                          _showTraineeSelectionDialog(parentContext, template);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Assign to Trainee'),
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

  void _showTraineeSelectionDialog(BuildContext context, _DefaultTemplate template) {
    final theme = Theme.of(context);
    // Capture the parent context before showing the bottom sheet
    final parentContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Consumer(
          builder: (consumerContext, ref, child) {
            final traineesAsync = ref.watch(traineesProvider);

            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Text(
                        'Select Trainee',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose a trainee to assign "${template.name}"',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Trainee list
                Expanded(
                  child: traineesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                          const SizedBox(height: 16),
                          Text('Error loading trainees', style: theme.textTheme.bodyLarge),
                        ],
                      ),
                    ),
                    data: (trainees) {
                      if (trainees.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: theme.hintColor),
                              const SizedBox(height: 16),
                              Text(
                                'No Trainees Yet',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Invite trainees first before assigning programs',
                                style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: trainees.length,
                        itemBuilder: (listContext, index) {
                          final trainee = trainees[index];
                          final initial = trainee.displayName.isNotEmpty
                              ? trainee.displayName[0].toUpperCase()
                              : '?';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                child: Text(
                                  initial,
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                trainee.displayName,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(trainee.email),
                              trailing: Icon(Icons.chevron_right, color: theme.hintColor),
                              onTap: () {
                                Navigator.pop(sheetContext);
                                // Navigate to program builder with trainee ID
                                if (parentContext.mounted) {
                                  Navigator.push(
                                    parentContext,
                                    MaterialPageRoute(
                                      builder: (context) => ProgramBuilderScreen(
                                        traineeId: trainee.id,
                                        templateName: template.name,
                                        durationWeeks: template.durationWeeks,
                                        difficulty: template.difficulty,
                                        goal: template.goal,
                                        weeklySchedule: template.schedule,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showCreateProgramDialog(BuildContext context) {
    final theme = Theme.of(context);
    // Capture the parent context before showing the bottom sheet
    final parentContext = context;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
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
              context: parentContext,
              icon: Icons.content_copy,
              title: 'Use a Template',
              subtitle: 'Start with a proven program structure and customize it',
              color: theme.colorScheme.primary,
              onTap: () {
                Navigator.pop(sheetContext);
                if (parentContext.mounted) {
                  _showTemplatePickerDialog(parentContext);
                }
              },
            ),
            const SizedBox(height: 12),

            // Start from Scratch option
            _buildCreateOption(
              context: parentContext,
              icon: Icons.add_circle_outline,
              title: 'Start from Scratch',
              subtitle: 'Build a completely custom program from the ground up',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(sheetContext);
                if (parentContext.mounted) {
                  _showNewProgramSetupDialog(parentContext);
                }
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
    // Capture the parent context before showing the bottom sheet
    final parentContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Column(
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
                itemBuilder: (listContext, index) {
                  final template = _defaultTemplates[index];
                  return _buildTemplatePickerCardWithContext(parentContext, sheetContext, template);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatePickerCardWithContext(BuildContext parentContext, BuildContext sheetContext, _DefaultTemplate template) {
    final theme = Theme.of(parentContext);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.pop(sheetContext);
          // Navigate to builder with template pre-filled
          if (parentContext.mounted) {
            Navigator.push(
              parentContext,
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
          }
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
                        _buildTag(parentContext, template.difficulty, _getDifficultyColor(template.difficulty)),
                        const SizedBox(width: 8),
                        _buildTag(parentContext, '${template.durationWeeks} weeks', Colors.blue),
                        const SizedBox(width: 8),
                        _buildTag(parentContext, '${template.daysPerWeek}x/week', Colors.green),
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
    // Capture the parent context before showing the bottom sheet
    final parentContext = context;
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
      builder: (sheetContext) => StatefulBuilder(
        builder: (stateContext, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(stateContext).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
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
                    Navigator.pop(sheetContext);
                    if (parentContext.mounted) {
                      Navigator.push(
                        parentContext,
                        MaterialPageRoute(
                          builder: (context) => ProgramBuilderScreen(
                            templateName: programName,
                            durationWeeks: durationWeeks,
                            difficulty: difficulty,
                            goal: goal,
                          ),
                        ),
                      );
                    }
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

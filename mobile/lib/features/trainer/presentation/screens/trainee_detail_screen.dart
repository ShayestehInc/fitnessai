import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/trainer_provider.dart';
import '../../data/models/trainee_model.dart';
import 'program_options_screen.dart';
import 'edit_trainee_goals_screen.dart';
import 'remove_trainee_screen.dart';
import 'dart:math' as math;
import '../../data/repositories/trainer_repository.dart';
import '../../../../core/api/api_client.dart';

class TraineeDetailScreen extends ConsumerStatefulWidget {
  final int traineeId;

  const TraineeDetailScreen({super.key, required this.traineeId});

  @override
  ConsumerState<TraineeDetailScreen> createState() => _TraineeDetailScreenState();
}

class _TraineeDetailScreenState extends ConsumerState<TraineeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final traineeAsync = ref.watch(traineeDetailProvider(widget.traineeId));
    final activityAsync = ref.watch(traineeActivityProvider(widget.traineeId));

    return Scaffold(
      body: traineeAsync.when(
        data: (trainee) {
          if (trainee == null) {
            return const Center(child: Text('Trainee not found'));
          }
          return _buildContent(context, trainee, activityAsync);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    TraineeDetailModel trainee,
    AsyncValue<List<ActivitySummary>> activityAsync,
  ) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          _buildSliverAppBar(trainee),
          SliverToBoxAdapter(
            child: _buildQuickStats(trainee, activityAsync),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                indicatorColor: Theme.of(context).colorScheme.primary,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Analytics'),
                  Tab(text: 'Nutrition'),
                  Tab(text: 'Activity'),
                ],
              ),
              Theme.of(context).cardColor,
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(trainee),
          _buildAnalyticsTab(trainee, activityAsync),
          _buildNutritionTab(trainee),
          _buildActivityTab(activityAsync),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(TraineeDetailModel trainee) {
    final name = '${trainee.firstName ?? ''} ${trainee.lastName ?? ''}'.trim();
    final displayName = name.isEmpty ? trainee.email.split('@').first : name;

    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.psychology),
          onPressed: () {
            final name = '${trainee.firstName ?? ''} ${trainee.lastName ?? ''}'.trim();
            final displayName = name.isEmpty ? trainee.email.split('@').first : name;
            context.push(
              '/trainer/ai-chat?trainee_id=${trainee.id}&trainee_name=$displayName',
            );
          },
          tooltip: 'Ask AI about this trainee',
        ),
        IconButton(
          icon: const Icon(Icons.visibility),
          onPressed: () => _startImpersonation(context),
          tooltip: 'View as Trainee',
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'message') {
              // Message trainee
            } else if (value == 'remove') {
              _openRemoveTrainee(context, trainee);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'message', child: Text('Send Message')),
            const PopupMenuItem(
              value: 'remove',
              child: Text('Remove Trainee', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade900,
                Colors.blue.shade600,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Hero(
                  tag: 'avatar_${widget.traineeId}',
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(
                        displayName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  trainee.email,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                if (trainee.profile?.onboardingCompleted == false)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Onboarding Incomplete',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(TraineeDetailModel trainee, AsyncValue<List<ActivitySummary>> activityAsync) {
    final activities = activityAsync.valueOrNull ?? [];
    final last7Days = activities.take(7).toList();

    int workoutDays = last7Days.where((a) => a.loggedWorkout).length;
    int nutritionDays = last7Days.where((a) => a.loggedFood).length;
    int proteinDays = last7Days.where((a) => a.hitProteinGoal).length;

    double workoutAdherence = last7Days.isEmpty ? 0 : (workoutDays / 7) * 100;
    double nutritionAdherence = last7Days.isEmpty ? 0 : (nutritionDays / 7) * 100;
    double proteinAdherence = last7Days.isEmpty ? 0 : (proteinDays / 7) * 100;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _QuickStatCard(
              icon: Icons.fitness_center,
              label: 'Workouts',
              value: '${workoutAdherence.toInt()}%',
              subLabel: '$workoutDays/7 days',
              color: Colors.green,
              progress: workoutAdherence / 100,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickStatCard(
              icon: Icons.restaurant,
              label: 'Nutrition',
              value: '${nutritionAdherence.toInt()}%',
              subLabel: '$nutritionDays/7 days',
              color: Colors.blue,
              progress: nutritionAdherence / 100,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickStatCard(
              icon: Icons.egg_alt,
              label: 'Protein',
              value: '${proteinAdherence.toInt()}%',
              subLabel: '$proteinDays/7 days',
              color: Colors.orange,
              progress: proteinAdherence / 100,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(TraineeDetailModel trainee) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Profile Card
        _buildSectionTitle('Profile Information'),
        const SizedBox(height: 12),
        _buildProfileCard(trainee),
        const SizedBox(height: 24),

        // Goals Card
        if (trainee.profile != null) ...[
          _buildSectionTitle('Fitness Goals'),
          const SizedBox(height: 12),
          _buildGoalsCard(trainee),
          const SizedBox(height: 24),
        ],

        // Current Program
        _buildSectionTitle('Current Program'),
        const SizedBox(height: 12),
        _buildCurrentProgramCard(trainee),
        const SizedBox(height: 24),

        // Workout Display Layout
        _buildSectionTitle('Workout Display'),
        const SizedBox(height: 12),
        _WorkoutLayoutPicker(traineeId: trainee.id),
        const SizedBox(height: 24),

        // Quick Actions
        _buildSectionTitle('Quick Actions'),
        const SizedBox(height: 12),
        _buildQuickActions(trainee),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildAnalyticsTab(TraineeDetailModel trainee, AsyncValue<List<ActivitySummary>> activityAsync) {
    final activities = activityAsync.valueOrNull ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Weekly Overview Chart
        _buildSectionTitle('Weekly Overview'),
        const SizedBox(height: 12),
        _buildWeeklyChart(activities),
        const SizedBox(height: 24),

        // Adherence Trends
        _buildSectionTitle('30-Day Adherence'),
        const SizedBox(height: 12),
        _buildAdherenceTrend(activities),
        const SizedBox(height: 24),

        // Volume Progress
        _buildSectionTitle('Training Volume'),
        const SizedBox(height: 12),
        _buildVolumeProgress(activities),
        const SizedBox(height: 24),

        // Calorie Trend
        _buildSectionTitle('Calorie Intake'),
        const SizedBox(height: 12),
        _buildCalorieTrend(activities),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildNutritionTab(TraineeDetailModel trainee) {
    return _MacroPresetsTab(
      traineeId: trainee.id,
      traineeName: trainee.firstName ?? 'Trainee',
      onEditPreset: (preset, onComplete) => _showEditPresetDialogWithCallback(
        context,
        trainee,
        preset,
        onComplete,
      ),
      onAddPreset: (onComplete) => _showEditPresetDialogWithCallback(
        context,
        trainee,
        null,
        onComplete,
      ),
      loadPresets: () => _loadMacroPresets(trainee.id),
      loadAllPresets: _loadAllMacroPresets,
      copyPreset: (presetId, targetTraineeId) => _copyMacroPreset(presetId, targetTraineeId),
    );
  }

  Future<List<Map<String, dynamic>>> _loadAllMacroPresets() async {
    final apiClient = ref.read(apiClientProvider);
    final response = await apiClient.dio.get(ApiConstants.allMacroPresets);
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<void> _copyMacroPreset(int presetId, int targetTraineeId) async {
    final apiClient = ref.read(apiClientProvider);
    await apiClient.dio.post(
      ApiConstants.copyMacroPreset(presetId),
      data: {'trainee_id': targetTraineeId},
    );
  }

  void _showEditPresetDialogWithCallback(
    BuildContext parentContext,
    TraineeDetailModel trainee,
    Map<String, dynamic>? existingPreset,
    VoidCallback onComplete,
  ) {
    _showEditPresetDialog(parentContext, trainee, existingPreset, onComplete);
  }

  Widget _buildActivityTab(AsyncValue<List<ActivitySummary>> activityAsync) {
    return activityAsync.when(
      data: (activities) {
        if (activities.isEmpty) {
          return _buildNoDataCard('No activity recorded yet');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            return _buildActivityCard(activities[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildProfileCard(TraineeDetailModel trainee) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileRow(Icons.cake, 'Age', '${trainee.profile?.age ?? "N/A"} years'),
            const Divider(height: 24),
            _buildProfileRow(Icons.height, 'Height', trainee.profile?.heightCm != null
                ? '${trainee.profile!.heightCm!.toStringAsFixed(0)} cm'
                : 'N/A'),
            const Divider(height: 24),
            _buildProfileRow(Icons.monitor_weight, 'Weight', trainee.profile?.weightKg != null
                ? '${trainee.profile!.weightKg!.toStringAsFixed(1)} kg'
                : 'N/A'),
            const Divider(height: 24),
            _buildProfileRow(Icons.directions_run, 'Activity', _formatActivityLevel(trainee.profile?.activityLevel)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue, size: 20),
        ),
        const SizedBox(width: 16),
        Text(label, style: TextStyle(color: Colors.grey[600])),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      ],
    );
  }

  Widget _buildGoalsCard(TraineeDetailModel trainee) {
    final goal = trainee.profile?.goal;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade400, Colors.purple.shade700],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getGoalIcon(goal),
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Primary Goal', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    _formatGoal(goal),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _openEditGoals(context, trainee),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentProgramCard(TraineeDetailModel trainee) {
    if (trainee.programs.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.calendar_today, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text('No Active Program', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Assign a program to get started', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => context.push('/trainer/programs/assign/${widget.traineeId}'),
                icon: const Icon(Icons.add),
                label: const Text('Assign Program'),
              ),
            ],
          ),
        ),
      );
    }

    final program = trainee.programs.first;

    // Calculate current week based on start date
    int currentWeek = 1;

    if (program.startDate != null) {
      try {
        final startDate = DateTime.parse(program.startDate!);
        final now = DateTime.now();
        final elapsed = now.difference(startDate).inDays;

        currentWeek = (elapsed / 7).floor() + 1;
        if (currentWeek < 1) currentWeek = 1;
      } catch (_) {
        // Use defaults if date parsing fails
      }
    }

    return InkWell(
      onTap: () => _openProgramOptions(trainee, program),
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.green.withValues(alpha: 0.3)),
        ),
        color: Colors.green.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.fitness_center, color: Colors.green),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(program.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(_formatStartDateLabel(program.startDate), style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Week $currentWeek', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text('Active', style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          final name = '${trainee.firstName ?? ''} ${trainee.lastName ?? ''}'.trim();
                          final displayName = name.isEmpty ? trainee.email.split('@').first : name;
                          context.push('/trainer/trainees/${widget.traineeId}/calendar?name=$displayName&program_id=${program.id}');
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.calendar_month, size: 14, color: Colors.blue),
                              SizedBox(width: 4),
                              Text('Calendar', style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Tap to manage', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatStartDateLabel(String? startDate) {
    if (startDate == null) return 'N/A';
    try {
      final date = DateTime.parse(startDate);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startDay = DateTime(date.year, date.month, date.day);

      if (startDay.isAfter(today)) {
        return 'Starts on $startDate';
      } else {
        return 'Started $startDate';
      }
    } catch (_) {
      return 'Started $startDate';
    }
  }

  void _openProgramOptions(TraineeDetailModel trainee, ProgramSummary program) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProgramOptionsScreen(
          traineeId: trainee.id,
          program: program,
        ),
      ),
    );
  }

  Widget _buildQuickActions(TraineeDetailModel trainee) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.message,
            label: 'Message',
            color: Colors.green,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Messaging coming soon')),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.calendar_month,
            label: 'Schedule',
            color: Colors.orange,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scheduling coming soon')),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(List<ActivitySummary> activities) {
    final last7Days = activities.take(7).toList().reversed.toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final activity = index < last7Days.length ? last7Days[index] : null;
                final hasWorkout = activity?.loggedWorkout ?? false;
                final hasNutrition = activity?.loggedFood ?? false;
                final dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                final dayIndex = (DateTime.now().weekday - 7 + index) % 7;

                return Column(
                  children: [
                    Container(
                      width: 36,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (hasWorkout)
                            Container(
                              width: 28,
                              height: 35,
                              margin: const EdgeInsets.only(bottom: 2),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.fitness_center, color: Colors.white, size: 14),
                            ),
                          if (hasNutrition)
                            Container(
                              width: 28,
                              height: 35,
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.restaurant, color: Colors.white, size: 14),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(dayNames[dayIndex], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                );
              }),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.green, 'Workout'),
                const SizedBox(width: 24),
                _buildLegendItem(Colors.blue, 'Nutrition'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildAdherenceTrend(List<ActivitySummary> activities) {
    // Calculate weekly adherence over last 4 weeks
    List<double> weeklyAdherence = [];
    for (int week = 0; week < 4; week++) {
      final start = week * 7;
      final end = math.min(start + 7, activities.length);
      if (start < activities.length) {
        final weekActivities = activities.sublist(start, end);
        final daysLogged = weekActivities.where((a) => a.loggedWorkout || a.loggedFood).length;
        weeklyAdherence.add((daysLogged / 7) * 100);
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAdherenceWeek('Week 4', weeklyAdherence.length > 3 ? weeklyAdherence[3] : 0),
                _buildAdherenceWeek('Week 3', weeklyAdherence.length > 2 ? weeklyAdherence[2] : 0),
                _buildAdherenceWeek('Week 2', weeklyAdherence.length > 1 ? weeklyAdherence[1] : 0),
                _buildAdherenceWeek('This Week', weeklyAdherence.isNotEmpty ? weeklyAdherence[0] : 0),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdherenceWeek(String label, double percentage) {
    Color color;
    if (percentage >= 80) {
      color = Colors.green;
    } else if (percentage >= 50) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: percentage / 100,
                strokeWidth: 6,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(color),
              ),
              Center(
                child: Text(
                  '${percentage.toInt()}%',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
      ],
    );
  }

  Widget _buildVolumeProgress(List<ActivitySummary> activities) {
    final last7Days = activities.take(7).toList().reversed.toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Total Sets', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(
                  '${last7Days.fold(0, (sum, a) => sum + a.totalSets)} sets',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 80,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (index) {
                  final activity = index < last7Days.length ? last7Days[index] : null;
                  final sets = activity?.totalSets ?? 0;
                  final maxSets = last7Days.isEmpty ? 1 : last7Days.map((a) => a.totalSets).reduce(math.max);
                  final height = maxSets == 0 ? 0.0 : (sets / maxSets) * 60;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: height,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Colors.purple.shade700, Colors.purple.shade300],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('$sets', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieTrend(List<ActivitySummary> activities) {
    final last7Days = activities.take(7).toList().reversed.toList();
    final avgCalories = last7Days.isEmpty
        ? 0
        : last7Days.fold(0, (sum, a) => sum + a.caloriesConsumed) ~/ last7Days.length;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Avg Daily Intake', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(
                  '$avgCalories kcal',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 80,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (index) {
                  final activity = index < last7Days.length ? last7Days[index] : null;
                  final cals = activity?.caloriesConsumed ?? 0;
                  final maxCals = last7Days.isEmpty ? 1 : last7Days.map((a) => a.caloriesConsumed).reduce(math.max);
                  final height = maxCals == 0 ? 0.0 : (cals / maxCals) * 60;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: height,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Colors.orange.shade700, Colors.orange.shade300],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadMacroPresets(int traineeId) async {
    final apiClient = ref.read(apiClientProvider);
    final response = await apiClient.dio.get(
      ApiConstants.macroPresetsForTrainee(traineeId),
    );
    return List<Map<String, dynamic>>.from(response.data);
  }

  void _showEditPresetDialog(
    BuildContext parentContext,
    TraineeDetailModel trainee,
    Map<String, dynamic>? existingPreset,
    VoidCallback onSaved,
  ) {
    final theme = Theme.of(context);
    final isEditing = existingPreset != null;

    String name = existingPreset?['name'] ?? '';
    int protein = existingPreset?['protein'] ?? 150;
    int carbs = existingPreset?['carbs'] ?? 200;
    int fat = existingPreset?['fat'] ?? 70;
    int? frequencyPerWeek = existingPreset?['frequency_per_week'];
    bool isDefault = existingPreset?['is_default'] ?? false;
    bool isSaving = false;
    bool isDeleting = false;

    // Calculate calories from macros: P*4 + C*4 + F*9
    int calculateCalories() => (protein * 4) + (carbs * 4) + (fat * 9);

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setModalState) {
          final bottomPadding = MediaQuery.of(dialogContext).viewInsets.bottom +
              MediaQuery.of(dialogContext).padding.bottom + 24;

          Future<void> savePreset() async {
            if (name.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a preset name'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            setModalState(() => isSaving = true);

            try {
              final apiClient = ref.read(apiClientProvider);

              if (isEditing) {
                await apiClient.dio.put(
                  ApiConstants.macroPreset(existingPreset!['id']),
                  data: {
                    'name': name.trim(),
                    'calories': calculateCalories(),
                    'protein': protein,
                    'carbs': carbs,
                    'fat': fat,
                    'frequency_per_week': frequencyPerWeek,
                    'is_default': isDefault,
                  },
                );
              } else {
                await apiClient.dio.post(
                  ApiConstants.macroPresets,
                  data: {
                    'trainee_id': trainee.id,
                    'name': name.trim(),
                    'calories': calculateCalories(),
                    'protein': protein,
                    'carbs': carbs,
                    'fat': fat,
                    'frequency_per_week': frequencyPerWeek,
                    'is_default': isDefault,
                  },
                );
              }

              if (mounted) {
                Navigator.pop(dialogContext);
                onSaved();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEditing ? 'Preset updated' : 'Preset created'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              setModalState(() => isSaving = false);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to save: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }

          Future<void> deletePreset() async {
            setModalState(() => isDeleting = true);

            try {
              final apiClient = ref.read(apiClientProvider);
              await apiClient.dio.delete(
                ApiConstants.macroPreset(existingPreset!['id']),
              );

              if (mounted) {
                Navigator.pop(dialogContext);
                onSaved();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Preset deleted'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            } catch (e) {
              setModalState(() => isDeleting = false);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }

          Widget buildMacroSlider({
            required String label,
            required int value,
            required int min,
            required int max,
            required String unit,
            required IconData icon,
            required Color color,
            required ValueChanged<int> onChanged,
            int? divisions,
          }) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(icon, color: color, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    const Spacer(),
                    Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(unit, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: color,
                    inactiveTrackColor: color.withValues(alpha: 0.2),
                    thumbColor: color,
                    overlayColor: color.withValues(alpha: 0.1),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: value.toDouble(),
                    min: min.toDouble(),
                    max: max.toDouble(),
                    divisions: divisions ?? (max - min > 0 ? max - min : 1),
                    onChanged: (v) => onChanged(v.round()),
                  ),
                ),
              ],
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: bottomPadding,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
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
                      Expanded(
                        child: Text(
                          isEditing ? 'Edit Preset' : 'New Preset',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.withValues(alpha: 0.1),
                          foregroundColor: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Name field
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Preset Name',
                      hintText: 'e.g., Training Day, Rest Day',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    controller: TextEditingController(text: name),
                    onChanged: (v) => name = v,
                  ),
                  const SizedBox(height: 16),
                  // Frequency dropdown
                  DropdownButtonFormField<int?>(
                    value: frequencyPerWeek,
                    decoration: InputDecoration(
                      labelText: 'Frequency (optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Not specified'),
                      ),
                      ...List.generate(7, (i) => i + 1).map(
                        (i) => DropdownMenuItem(
                          value: i,
                          child: Text('$i× per week'),
                        ),
                      ),
                    ],
                    onChanged: (v) => setModalState(() => frequencyPerWeek = v),
                  ),
                  const SizedBox(height: 16),
                  // Default toggle
                  SwitchListTile(
                    title: const Text('Set as Default'),
                    subtitle: const Text('Show as primary option'),
                    value: isDefault,
                    onChanged: (v) => setModalState(() => isDefault = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  // Calculated calories display
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.local_fire_department, color: Colors.orange, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Calories',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                'Calculated from macros',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${calculateCalories()}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('kcal', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Macro sliders
                  buildMacroSlider(
                    label: 'Protein',
                    value: protein,
                    min: 50,
                    max: 350,
                    unit: 'g',
                    icon: Icons.egg_alt,
                    color: Colors.red,
                    divisions: 60,
                    onChanged: (v) => setModalState(() => protein = v),
                  ),
                  const SizedBox(height: 12),
                  buildMacroSlider(
                    label: 'Carbs',
                    value: carbs,
                    min: 50,
                    max: 500,
                    unit: 'g',
                    icon: Icons.bakery_dining,
                    color: Colors.amber,
                    divisions: 90,
                    onChanged: (v) => setModalState(() => carbs = v),
                  ),
                  const SizedBox(height: 12),
                  buildMacroSlider(
                    label: 'Fat',
                    value: fat,
                    min: 20,
                    max: 200,
                    unit: 'g',
                    icon: Icons.water_drop,
                    color: Colors.purple,
                    divisions: 36,
                    onChanged: (v) => setModalState(() => fat = v),
                  ),
                  const SizedBox(height: 24),
                  // Action buttons
                  Row(
                    children: [
                      if (isEditing)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isDeleting || isSaving
                                ? null
                                : () {
                                    showDialog(
                                      context: dialogContext,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Preset?'),
                                        content: Text(
                                          'Are you sure you want to delete "${existingPreset?['name']}"?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(ctx);
                                              deletePreset();
                                            },
                                            child: const Text(
                                              'Delete',
                                              style: TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: isDeleting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.red,
                                    ),
                                  )
                                : const Text('Delete'),
                          ),
                        ),
                      if (isEditing) const SizedBox(width: 12),
                      Expanded(
                        flex: isEditing ? 2 : 1,
                        child: ElevatedButton(
                          onPressed: isSaving || isDeleting ? null : savePreset,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(isEditing ? 'Save Changes' : 'Create Preset'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityCard(ActivitySummary activity) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _formatDateFull(activity.date),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Spacer(),
                if (activity.loggedWorkout)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fitness_center, size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        const Text('Workout', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                if (activity.loggedFood)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.restaurant, size: 14, color: Colors.blue),
                        const SizedBox(width: 4),
                        const Text('Nutrition', style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildActivityStat(Icons.local_fire_department, '${activity.caloriesConsumed}', 'kcal', Colors.orange),
                const SizedBox(width: 16),
                _buildActivityStat(Icons.egg_alt, '${activity.proteinConsumed}', 'g protein', Colors.red),
                const SizedBox(width: 16),
                _buildActivityStat(Icons.fitness_center, '${activity.totalSets}', 'sets', Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityStat(IconData icon, String value, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 2),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildNoDataCard(String message) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(message, style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getGoalIcon(String? goal) {
    switch (goal) {
      case 'build_muscle':
        return Icons.fitness_center;
      case 'fat_loss':
        return Icons.trending_down;
      case 'recomp':
        return Icons.sync;
      default:
        return Icons.flag;
    }
  }

  String _formatGoal(String? goal) {
    switch (goal) {
      case 'build_muscle':
        return 'Build Muscle';
      case 'fat_loss':
        return 'Fat Loss';
      case 'recomp':
        return 'Body Recomposition';
      default:
        return goal ?? 'Not Set';
    }
  }

  String _formatActivityLevel(String? level) {
    switch (level) {
      case 'sedentary':
        return 'Sedentary';
      case 'lightly_active':
        return 'Lightly Active';
      case 'moderately_active':
        return 'Moderately Active';
      case 'very_active':
        return 'Very Active';
      case 'extremely_active':
        return 'Extremely Active';
      default:
        return level ?? 'N/A';
    }
  }

  String _formatDateFull(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
    } catch (_) {
      return dateStr;
    }
  }

  void _startImpersonation(BuildContext context) async {
    final result = await ref.read(impersonationProvider.notifier).startImpersonation(widget.traineeId);

    if (!result['success'] && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to start session'),
          backgroundColor: Colors.red,
        ),
      );
    } else if (context.mounted) {
      context.go('/home');
    }
  }

  void _openEditGoals(BuildContext context, TraineeDetailModel trainee) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditTraineeGoalsScreen(trainee: trainee),
      ),
    );
  }

  void _openRemoveTrainee(BuildContext context, TraineeDetailModel trainee) {
    final name = '${trainee.firstName ?? ''} ${trainee.lastName ?? ''}'.trim();
    final displayName = name.isEmpty ? trainee.email.split('@').first : name;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RemoveTraineeScreen(
          traineeId: trainee.id,
          traineeName: displayName,
          traineeEmail: trainee.email,
        ),
      ),
    );
  }
}

// Custom Widgets

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _SliverTabBarDelegate(this.tabBar, this.backgroundColor);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) =>
      oldDelegate.backgroundColor != backgroundColor;
}

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subLabel;
  final Color color;
  final double progress;

  const _QuickStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subLabel,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      color: color.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 4),
            Text(subLabel, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _MacroPresetsTab extends StatefulWidget {
  final int traineeId;
  final String traineeName;
  final Function(Map<String, dynamic>, VoidCallback onComplete) onEditPreset;
  final Function(VoidCallback onComplete) onAddPreset;
  final Future<List<Map<String, dynamic>>> Function() loadPresets;
  final Future<List<Map<String, dynamic>>> Function() loadAllPresets;
  final Future<void> Function(int presetId, int targetTraineeId) copyPreset;

  const _MacroPresetsTab({
    required this.traineeId,
    required this.traineeName,
    required this.onEditPreset,
    required this.onAddPreset,
    required this.loadPresets,
    required this.loadAllPresets,
    required this.copyPreset,
  });

  @override
  State<_MacroPresetsTab> createState() => _MacroPresetsTabState();
}

class _MacroPresetsTabState extends State<_MacroPresetsTab> {
  List<Map<String, dynamic>> _presets = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final presets = await widget.loadPresets();
      if (mounted) {
        setState(() {
          _presets = presets;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showImportDialog() {
    final theme = Theme.of(context);
    List<Map<String, dynamic>> allTraineePresets = [];
    bool isLoading = true;
    String? error;
    Set<int> selectedPresetIds = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setModalState) {
          // Load all presets on first build
          if (isLoading && error == null) {
            widget.loadAllPresets().then((result) {
              // Filter out current trainee's presets
              final filtered = result.where(
                (t) => t['trainee_id'] != widget.traineeId,
              ).toList();
              setModalState(() {
                allTraineePresets = filtered;
                isLoading = false;
              });
            }).catchError((e) {
              setModalState(() {
                error = e.toString();
                isLoading = false;
              });
            });
          }

          final bottomPadding = MediaQuery.of(dialogContext).padding.bottom + 24;

          Future<void> importSelected() async {
            if (selectedPresetIds.isEmpty) return;

            setModalState(() => isLoading = true);

            try {
              for (final presetId in selectedPresetIds) {
                await widget.copyPreset(presetId, widget.traineeId);
              }

              if (mounted) {
                Navigator.pop(dialogContext);
                _loadPresets();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Imported ${selectedPresetIds.length} preset(s)'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              setModalState(() => isLoading = false);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to import: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(dialogContext).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Import Presets',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey.withValues(alpha: 0.1),
                              foregroundColor: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Copy presets from another trainee to ${widget.traineeName}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: theme.dividerColor),
                // Content
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : error != null
                          ? Center(
                              child: Text(
                                'Error: $error',
                                style: const TextStyle(color: Colors.red),
                              ),
                            )
                          : allTraineePresets.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'No Presets to Import',
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Create presets for other trainees first, then you can import them here',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: allTraineePresets.length,
                                  itemBuilder: (context, index) {
                                    final traineeData = allTraineePresets[index];
                                    final presets = List<Map<String, dynamic>>.from(
                                      traineeData['presets'] ?? [],
                                    );

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 16,
                                                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                                child: Text(
                                                  (traineeData['trainee_name'] as String? ?? 'T')
                                                      .substring(0, 1)
                                                      .toUpperCase(),
                                                  style: TextStyle(
                                                    color: theme.colorScheme.primary,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      traineeData['trainee_name'] ?? 'Unknown',
                                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                                    ),
                                                    Text(
                                                      '${presets.length} preset(s)',
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        ...presets.map((preset) {
                                          final presetId = preset['id'] as int;
                                          final isSelected = selectedPresetIds.contains(presetId);
                                          final protein = preset['protein'] ?? 0;
                                          final carbs = preset['carbs'] ?? 0;
                                          final fat = preset['fat'] ?? 0;
                                          final calories = (protein * 4) + (carbs * 4) + (fat * 9);

                                          return Card(
                                            margin: const EdgeInsets.only(bottom: 8, left: 28),
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              side: BorderSide(
                                                color: isSelected
                                                    ? theme.colorScheme.primary
                                                    : Colors.grey.withValues(alpha: 0.2),
                                                width: isSelected ? 2 : 1,
                                              ),
                                            ),
                                            child: InkWell(
                                              onTap: () {
                                                setModalState(() {
                                                  if (isSelected) {
                                                    selectedPresetIds.remove(presetId);
                                                  } else {
                                                    selectedPresetIds.add(presetId);
                                                  }
                                                });
                                              },
                                              borderRadius: BorderRadius.circular(12),
                                              child: Padding(
                                                padding: const EdgeInsets.all(12),
                                                child: Row(
                                                  children: [
                                                    Checkbox(
                                                      value: isSelected,
                                                      onChanged: (v) {
                                                        setModalState(() {
                                                          if (v == true) {
                                                            selectedPresetIds.add(presetId);
                                                          } else {
                                                            selectedPresetIds.remove(presetId);
                                                          }
                                                        });
                                                      },
                                                    ),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            preset['name'] ?? 'Unnamed',
                                                            style: const TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            '$calories kcal • ${protein}g P • ${carbs}g C • ${fat}g F',
                                                            style: TextStyle(
                                                              color: Colors.grey[600],
                                                              fontSize: 12,
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
                                        }),
                                        const SizedBox(height: 8),
                                      ],
                                    );
                                  },
                                ),
                ),
                // Import button
                if (!isLoading && allTraineePresets.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 8,
                      bottom: bottomPadding,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: selectedPresetIds.isEmpty ? null : importSelected,
                        icon: const Icon(Icons.file_download),
                        label: Text(
                          selectedPresetIds.isEmpty
                              ? 'Select presets to import'
                              : 'Import ${selectedPresetIds.length} preset(s)',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Error loading presets', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadPresets,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPresets,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header with info
          Row(
            children: [
              const Text(
                'Macro Presets',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _showImportDialog,
                icon: const Icon(Icons.file_download_outlined, size: 18),
                label: const Text('Import'),
              ),
              TextButton.icon(
                onPressed: () {
                  widget.onAddPreset(_loadPresets);
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Set different macro targets for ${widget.traineeName}\'s training and rest days',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 16),

          if (_presets.isEmpty)
            _buildEmptyState()
          else
            ..._presets.map((preset) => _buildPresetCard(preset, theme)),

          const SizedBox(height: 24),

          // Add preset button at bottom
          if (_presets.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () {
                widget.onAddPreset(_loadPresets);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add New Preset'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.restaurant_menu, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No Macro Presets Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Create presets like "Training Day", "Rest Day", or "Growth Day"',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _showImportDialog,
                  icon: const Icon(Icons.file_download_outlined),
                  label: const Text('Import'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    widget.onAddPreset(_loadPresets);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create New'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetCard(Map<String, dynamic> preset, ThemeData theme) {
    final isDefault = preset['is_default'] == true;
    final frequency = preset['frequency_per_week'];
    final protein = preset['protein'] ?? 0;
    final carbs = preset['carbs'] ?? 0;
    final fat = preset['fat'] ?? 0;
    final calories = (protein * 4) + (carbs * 4) + (fat * 9);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDefault ? theme.colorScheme.primary : Colors.grey.withValues(alpha: 0.2),
          width: isDefault ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          widget.onEditPreset(preset, _loadPresets);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              preset['name'] ?? 'Unnamed',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                            if (isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'DEFAULT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (frequency != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${frequency}× per week',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.edit_outlined, size: 20, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 16),

              // Calories row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '$calories',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('kcal', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Macros row
              Row(
                children: [
                  _buildMacroItem('Protein', protein, 'g', Colors.red),
                  const SizedBox(width: 12),
                  _buildMacroItem('Carbs', carbs, 'g', Colors.amber.shade700),
                  const SizedBox(width: 12),
                  _buildMacroItem('Fat', fat, 'g', Colors.purple),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroItem(String label, int value, String unit, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$value$unit',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

/// Workout layout picker segmented control for the trainer detail screen.
class _WorkoutLayoutPicker extends ConsumerStatefulWidget {
  final int traineeId;

  const _WorkoutLayoutPicker({required this.traineeId});

  @override
  ConsumerState<_WorkoutLayoutPicker> createState() =>
      _WorkoutLayoutPickerState();
}

class _WorkoutLayoutPickerState extends ConsumerState<_WorkoutLayoutPicker> {
  String _selectedLayout = 'classic';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLayout();
  }

  Future<void> _fetchCurrentLayout() async {
    final apiClient = ref.read(apiClientProvider);
    final repository = TrainerRepository(apiClient);
    final result = await repository.getTraineeLayoutConfig(widget.traineeId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true && result['data'] != null) {
          final data = result['data'] as Map<String, dynamic>;
          _selectedLayout = data['layout_type'] as String? ?? 'classic';
        }
      });
    }
  }

  Future<void> _updateLayout(String layoutType) async {
    if (_isSaving || layoutType == _selectedLayout) return;

    setState(() {
      _isSaving = true;
      _selectedLayout = layoutType;
    });

    final apiClient = ref.read(apiClientProvider);
    final repository = TrainerRepository(apiClient);
    final result = await repository.updateTraineeLayoutConfig(
      widget.traineeId,
      layoutType: layoutType,
    );

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (result['success'] == true) {
      final label = _layoutLabel(layoutType);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Layout updated to $label'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // Revert on failure
      _fetchCurrentLayout();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] as String? ?? 'Failed to update layout'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _layoutLabel(String type) {
    switch (type) {
      case 'classic':
        return 'Classic';
      case 'card':
        return 'Card';
      case 'minimal':
        return 'Minimal';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose the workout UI this trainee sees during active workouts.',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _LayoutOption(
                    icon: Icons.table_chart,
                    label: 'Classic',
                    description: 'All exercises visible',
                    isSelected: _selectedLayout == 'classic',
                    onTap: () => _updateLayout('classic'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _LayoutOption(
                    icon: Icons.view_carousel,
                    label: 'Card',
                    description: 'One at a time',
                    isSelected: _selectedLayout == 'card',
                    onTap: () => _updateLayout('card'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _LayoutOption(
                    icon: Icons.checklist,
                    label: 'Minimal',
                    description: 'Compact list',
                    isSelected: _selectedLayout == 'minimal',
                    onTap: () => _updateLayout('minimal'),
                  ),
                ),
              ],
            ),
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LayoutOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _LayoutOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.1)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? primaryColor : theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? primaryColor
                    : theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: TextStyle(
                fontSize: 10,
                color: theme.textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


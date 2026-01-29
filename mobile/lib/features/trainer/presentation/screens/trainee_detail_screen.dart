import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/trainer_provider.dart';
import '../../data/models/trainee_model.dart';
import 'dart:math' as math;

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
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).primaryColor,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Analytics'),
                  Tab(text: 'Nutrition'),
                  Tab(text: 'Activity'),
                ],
              ),
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
      expandedHeight: 200,
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
            if (value == 'edit') {
              // Edit trainee
            } else if (value == 'message') {
              // Message trainee
            } else if (value == 'remove') {
              _showRemoveDialog(context);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit Goals')),
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

        // Quick Actions
        _buildSectionTitle('Quick Actions'),
        const SizedBox(height: 12),
        _buildQuickActions(),
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
    final goal = trainee.nutritionGoal;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Macro Targets
        _buildSectionTitle('Daily Macro Targets'),
        const SizedBox(height: 12),
        if (goal != null) _buildMacroTargetsCard(goal) else _buildNoDataCard('No nutrition goals set'),
        const SizedBox(height: 24),

        // Macro Distribution
        if (goal != null) ...[
          _buildSectionTitle('Macro Distribution'),
          const SizedBox(height: 12),
          _buildMacroDistributionChart(goal),
          const SizedBox(height: 24),
        ],

        // Adjust Nutrition
        _buildSectionTitle('Adjustments'),
        const SizedBox(height: 12),
        _buildNutritionAdjustmentCard(trainee),
        const SizedBox(height: 32),
      ],
    );
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
              onPressed: () {},
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
    return Card(
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
                      Text('${program.startDate} - ${program.endDate}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Active', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 0.4, // Calculate actual progress
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation(Colors.green),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text('Week 3 of 8', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.edit_note,
            label: 'Edit Goals',
            color: Colors.blue,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.message,
            label: 'Message',
            color: Colors.green,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.calendar_month,
            label: 'Schedule',
            color: Colors.orange,
            onTap: () {},
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

  Widget _buildMacroTargetsCard(NutritionGoalSummary goal) {
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
            _MacroRow(
              label: 'Calories',
              value: goal.caloriesGoal,
              unit: 'kcal',
              color: Colors.orange,
              icon: Icons.local_fire_department,
            ),
            const SizedBox(height: 16),
            _MacroRow(
              label: 'Protein',
              value: goal.proteinGoal,
              unit: 'g',
              color: Colors.red,
              icon: Icons.egg_alt,
            ),
            const SizedBox(height: 16),
            _MacroRow(
              label: 'Carbs',
              value: goal.carbsGoal,
              unit: 'g',
              color: Colors.blue,
              icon: Icons.breakfast_dining,
            ),
            const SizedBox(height: 16),
            _MacroRow(
              label: 'Fat',
              value: goal.fatGoal,
              unit: 'g',
              color: Colors.amber,
              icon: Icons.water_drop,
            ),
            if (goal.isTrainerAdjusted) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    const Text('Trainer adjusted', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMacroDistributionChart(NutritionGoalSummary goal) {
    final total = goal.proteinGoal * 4 + goal.carbsGoal * 4 + goal.fatGoal * 9;
    final proteinPct = total > 0 ? (goal.proteinGoal * 4 / total * 100) : 0;
    final carbsPct = total > 0 ? (goal.carbsGoal * 4 / total * 100) : 0;
    final fatPct = total > 0 ? (goal.fatGoal * 9 / total * 100) : 0;

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
            SizedBox(
              width: 120,
              height: 120,
              child: CustomPaint(
                painter: _PieChartPainter(
                  protein: proteinPct.toDouble(),
                  carbs: carbsPct.toDouble(),
                  fat: fatPct.toDouble(),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                children: [
                  _buildPieLegend(Colors.red, 'Protein', '${proteinPct.toInt()}%'),
                  const SizedBox(height: 12),
                  _buildPieLegend(Colors.blue, 'Carbs', '${carbsPct.toInt()}%'),
                  const SizedBox(height: 12),
                  _buildPieLegend(Colors.amber, 'Fat', '${fatPct.toInt()}%'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieLegend(Color color, String label, String value) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Text(label),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildNutritionAdjustmentCard(TraineeDetailModel trainee) {
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
            const Text(
              'Adjust your trainee\'s nutrition targets based on their progress',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.tune),
                label: const Text('Adjust Macros'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
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

  void _showRemoveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Trainee?'),
        content: const Text('This will unassign this trainee from your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await ref.read(trainerRepositoryProvider).removeTrainee(widget.traineeId);

              if (context.mounted) {
                if (result['success']) {
                  ref.invalidate(traineesProvider);
                  context.pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result['error'] ?? 'Failed to remove'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

// Custom Widgets

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
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

class _MacroRow extends StatelessWidget {
  final String label;
  final int value;
  final String unit;
  final Color color;
  final IconData icon;

  const _MacroRow({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 16),
        Text(label, style: const TextStyle(fontSize: 16)),
        const Spacer(),
        Text(
          '$value',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(width: 4),
        Text(unit, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
      ],
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final double protein;
  final double carbs;
  final double fat;

  _PieChartPainter({required this.protein, required this.carbs, required this.fat});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final proteinSweep = protein / 100 * 2 * math.pi;
    final carbsSweep = carbs / 100 * 2 * math.pi;
    final fatSweep = fat / 100 * 2 * math.pi;

    var startAngle = -math.pi / 2;

    // Protein
    final proteinPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 10), startAngle, proteinSweep, false, proteinPaint);
    startAngle += proteinSweep;

    // Carbs
    final carbsPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 10), startAngle, carbsSweep, false, carbsPaint);
    startAngle += carbsSweep;

    // Fat
    final fatPaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 10), startAngle, fatSweep, false, fatPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

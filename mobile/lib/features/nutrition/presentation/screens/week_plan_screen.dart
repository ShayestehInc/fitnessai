import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/nutrition_template_models.dart';
import '../providers/nutrition_template_provider.dart';
import '../widgets/day_type_badge.dart';
import '../../../../shared/widgets/loading_shimmer.dart';

class WeekPlanScreen extends ConsumerStatefulWidget {
  const WeekPlanScreen({super.key});

  @override
  ConsumerState<WeekPlanScreen> createState() => _WeekPlanScreenState();
}

class _WeekPlanScreenState extends ConsumerState<WeekPlanScreen> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekStart = now.subtract(Duration(days: now.weekday - 1));
  }

  String get _weekStartKey => DateFormat('yyyy-MM-dd').format(_weekStart);

  void _changeWeek(int delta) {
    setState(() {
      _weekStart = _weekStart.add(Duration(days: delta * 7));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekAsync = ref.watch(weekPlansProvider(_weekStartKey));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Nutrition'),
      ),
      body: Column(
        children: [
          // Week navigator
          _WeekNavigator(
            weekStart: _weekStart,
            onPrevious: () => _changeWeek(-1),
            onNext: () => _changeWeek(1),
            onThisWeek: () {
              final now = DateTime.now();
              setState(() {
                _weekStart = now.subtract(Duration(days: now.weekday - 1));
              });
            },
          ),
          // Content
          Expanded(
            child: weekAsync.when(
              loading: () => const Center(child: LoadingShimmer()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Failed to load week plan',
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => ref.invalidate(
                        weekPlansProvider(_weekStartKey),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (plans) {
                if (plans.isEmpty) {
                  return Center(
                    child: Text(
                      'No nutrition plans for this week',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  );
                }
                return _WeekContent(
                  plans: plans,
                  weekStart: _weekStart,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekNavigator extends StatelessWidget {
  final DateTime weekStart;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onThisWeek;

  const _WeekNavigator({
    required this.weekStart,
    required this.onPrevious,
    required this.onNext,
    required this.onThisWeek,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekEnd = weekStart.add(const Duration(days: 6));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous week',
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: GestureDetector(
              onTap: onThisWeek,
              child: Text(
                '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d').format(weekEnd)}',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next week',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _WeekContent extends StatelessWidget {
  final List<NutritionDayPlanModel> plans;
  final DateTime weekStart;

  const _WeekContent({required this.plans, required this.weekStart});

  @override
  Widget build(BuildContext context) {
    // Build a map of date → plan for quick lookup
    final planMap = <String, NutritionDayPlanModel>{};
    for (final plan in plans) {
      planMap[plan.date] = plan;
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 7,
      itemBuilder: (context, index) {
        final day = weekStart.add(Duration(days: index));
        final dateKey = DateFormat('yyyy-MM-dd').format(day);
        final plan = planMap[dateKey];

        return _DayCard(
          date: day,
          plan: plan,
          onTap: () {
            context.push('/nutrition/day-plan?date=$dateKey');
          },
        );
      },
    );
  }
}

class _DayCard extends StatelessWidget {
  final DateTime date;
  final NutritionDayPlanModel? plan;
  final VoidCallback onTap;

  const _DayCard({
    required this.date,
    required this.plan,
    required this.onTap,
  });

  bool get _isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: _isToday
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Day label
              SizedBox(
                width: 48,
                child: Column(
                  children: [
                    Text(
                      DateFormat('EEE').format(date),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _isToday
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                        fontWeight:
                            _isToday ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${date.day}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _isToday
                            ? theme.colorScheme.primary
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Plan info
              Expanded(
                child: plan != null
                    ? _PlanSummary(plan: plan!)
                    : Text(
                        'No plan',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
              ),
              Icon(
                Icons.chevron_right,
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanSummary extends StatelessWidget {
  final NutritionDayPlanModel plan;

  const _PlanSummary({required this.plan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            DayTypeBadge(dayType: plan.dayType),
            const Spacer(),
            Text(
              '${plan.totalCalories} cal',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _MiniMacro('P', plan.totalProtein, Colors.blue),
            const SizedBox(width: 8),
            _MiniMacro('C', plan.totalCarbs, Colors.orange),
            const SizedBox(width: 8),
            _MiniMacro('F', plan.totalFat, Colors.red),
          ],
        ),
      ],
    );
  }
}

class _MiniMacro extends StatelessWidget {
  final String label;
  final int grams;
  final Color color;

  const _MiniMacro(this.label, this.grams, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: ${grams}g',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }
}

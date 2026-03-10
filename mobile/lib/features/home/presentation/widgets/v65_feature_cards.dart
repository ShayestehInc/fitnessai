import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Reusable card for navigating to a v6.5 feature screen.
class _FeatureNavCard extends StatelessWidget {
  final String route;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _FeatureNavCard({
    required this.route,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Navigate to $title',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(route),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Card linking to Training Plans (My Plans).
class TrainingPlansCard extends StatelessWidget {
  const TrainingPlansCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _FeatureNavCard(
      route: '/my-plans',
      icon: Icons.calendar_today_rounded,
      iconColor: Theme.of(context).colorScheme.primary,
      title: 'Training Plans',
      subtitle: 'View your active plan and upcoming sessions',
    );
  }
}

/// Card linking to Lift Maxes screen.
class LiftMaxesCard extends StatelessWidget {
  const LiftMaxesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const _FeatureNavCard(
      route: '/lift-maxes',
      icon: Icons.trending_up_rounded,
      iconColor: Colors.orange,
      title: 'Lift Maxes',
      subtitle: 'Track your estimated 1RM and training maxes',
    );
  }
}

/// Card linking to Workload overview.
class WorkloadCard extends StatelessWidget {
  const WorkloadCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const _FeatureNavCard(
      route: '/workload',
      icon: Icons.bar_chart_rounded,
      iconColor: Colors.purple,
      title: 'Workload',
      subtitle: 'Monitor weekly volume and training stress',
    );
  }
}

/// Card linking to Voice Memos.
class VoiceMemosCard extends StatelessWidget {
  const VoiceMemosCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const _FeatureNavCard(
      route: '/voice-memos',
      icon: Icons.mic_rounded,
      iconColor: Colors.teal,
      title: 'Voice Memos',
      subtitle: 'Log workouts and meals with your voice',
    );
  }
}

/// Card linking to Video Analysis.
class VideoAnalysisCard extends StatelessWidget {
  const VideoAnalysisCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const _FeatureNavCard(
      route: '/video-analysis',
      icon: Icons.videocam_rounded,
      iconColor: Colors.blue,
      title: 'Video Analysis',
      subtitle: 'Get AI form feedback on your lifts',
    );
  }
}

/// Card linking to Session Feedback history.
class FeedbackHistoryCard extends StatelessWidget {
  const FeedbackHistoryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const _FeatureNavCard(
      route: '/feedback-history',
      icon: Icons.rate_review_rounded,
      iconColor: Colors.amber,
      title: 'Session Feedback',
      subtitle: 'Review your workout feedback and pain reports',
    );
  }
}

/// Composite section containing all v6.5 feature navigation cards,
/// grouped under "Performance" and "AI Tools" headings.
class V65FeatureSection extends StatelessWidget {
  const V65FeatureSection({super.key});

  @override
  Widget build(BuildContext context) {
    final sectionStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Performance section
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Performance', style: sectionStyle),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: TrainingPlansCard(),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: LiftMaxesCard(),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: WorkloadCard(),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: FeedbackHistoryCard(),
        ),

        // AI Tools section
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('AI Tools', style: sectionStyle),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: VoiceMemosCard(),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: VideoAnalysisCard(),
        ),
      ],
    );
  }
}

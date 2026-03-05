import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Screen for rest day completion with optional recovery exercises.
class RestDayScreen extends ConsumerStatefulWidget {
  const RestDayScreen({super.key});

  @override
  ConsumerState<RestDayScreen> createState() => _RestDayScreenState();
}

class _RestDayScreenState extends ConsumerState<RestDayScreen> {
  final List<_RecoveryExercise> _recoveryExercises = [
    _RecoveryExercise(name: 'Foam Rolling', duration: '10 min', icon: Icons.self_improvement),
    _RecoveryExercise(name: 'Stretching', duration: '15 min', icon: Icons.accessibility_new),
    _RecoveryExercise(name: 'Light Walk', duration: '20 min', icon: Icons.directions_walk),
    _RecoveryExercise(name: 'Yoga', duration: '20 min', icon: Icons.spa),
    _RecoveryExercise(name: 'Mobility Work', duration: '10 min', icon: Icons.fitness_center),
    _RecoveryExercise(name: 'Meditation', duration: '10 min', icon: Icons.psychology),
  ];

  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitRestDay() async {
    setState(() => _isSubmitting = true);

    final completedExercises = _recoveryExercises
        .where((e) => e.completed)
        .map((e) => {'name': e.name, 'duration': e.duration})
        .toList();

    try {
      final client = ref.read(apiClientProvider);
      await client.dio.post(
        ApiConstants.completeRestDay,
        data: {
          'completed_exercises': completedExercises,
          'notes': _notesController.text,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rest day completed!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save rest day: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedCount = _recoveryExercises.where((e) => e.completed).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Rest Day')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.bedtime_outlined,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Recovery Day',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Take it easy today. Complete optional recovery exercises below.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Recovery exercises section
          Text(
            'Recovery Activities (Optional)',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          ...List.generate(_recoveryExercises.length, (index) {
            final exercise = _recoveryExercises[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: CheckboxListTile(
                value: exercise.completed,
                onChanged: (value) {
                  setState(() => exercise.completed = value ?? false);
                },
                title: Text(exercise.name),
                subtitle: Text(exercise.duration),
                secondary: Icon(
                  exercise.icon,
                  color: exercise.completed
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // Notes field
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'How are you feeling today?',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 24),

          // Submit button
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _submitRestDay,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(
              completedCount > 0
                  ? 'Complete Rest Day ($completedCount activities)'
                  : 'Complete Rest Day',
            ),
          ),
        ],
      ),
    );
  }
}

class _RecoveryExercise {
  final String name;
  final String duration;
  final IconData icon;
  bool completed;

  _RecoveryExercise({
    required this.name,
    required this.duration,
    required this.icon,
    this.completed = false,
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/chat_models.dart';
import '../providers/ai_chat_provider.dart';

class TraineeSelector extends ConsumerWidget {
  const TraineeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(aiChatProvider);
    final traineesAsync = ref.watch(traineesForChatProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person_search,
            size: 20,
            color: AppTheme.mutedForeground,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: traineesAsync.when(
              data: (trainees) => _buildSelector(
                context,
                ref,
                trainees,
                chatState,
              ),
              loading: () => Text(
                'Loading trainees...',
                style: TextStyle(
                  color: AppTheme.mutedForeground,
                  fontSize: 14,
                ),
              ),
              error: (_, __) => Text(
                'Error loading trainees',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (chatState.selectedTraineeId != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () {
                ref.read(aiChatProvider.notifier).selectTrainee(null, null);
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: AppTheme.mutedForeground,
            ),
        ],
      ),
    );
  }

  Widget _buildSelector(
    BuildContext context,
    WidgetRef ref,
    List<TraineeOption> trainees,
    AIChatState chatState,
  ) {
    if (trainees.isEmpty) {
      return Text(
        'No trainees found',
        style: TextStyle(
          color: AppTheme.mutedForeground,
          fontSize: 14,
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showTraineeBottomSheet(context, ref, trainees),
      child: Row(
        children: [
          Expanded(
            child: Text(
              chatState.selectedTraineeName ?? 'All trainees',
              style: TextStyle(
                color: chatState.selectedTraineeId != null
                    ? AppTheme.primary
                    : AppTheme.foreground,
                fontSize: 14,
                fontWeight: chatState.selectedTraineeId != null
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down,
            size: 20,
            color: AppTheme.mutedForeground,
          ),
        ],
      ),
    );
  }

  void _showTraineeBottomSheet(
    BuildContext context,
    WidgetRef ref,
    List<TraineeOption> trainees,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _TraineeBottomSheet(trainees: trainees),
    );
  }
}

class _TraineeBottomSheet extends ConsumerStatefulWidget {
  final List<TraineeOption> trainees;

  const _TraineeBottomSheet({required this.trainees});

  @override
  ConsumerState<_TraineeBottomSheet> createState() =>
      _TraineeBottomSheetState();
}

class _TraineeBottomSheetState extends ConsumerState<_TraineeBottomSheet> {
  String _searchQuery = '';

  List<TraineeOption> get _filteredTrainees {
    if (_searchQuery.isEmpty) return widget.trainees;
    final query = _searchQuery.toLowerCase();
    return widget.trainees.where((t) {
      return t.name.toLowerCase().contains(query) ||
          t.email.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Title
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Select Trainee',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.foreground,
            ),
          ),
        ),

        // Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search trainees...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.border),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),

        const SizedBox(height: 8),

        // "All trainees" option
        ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
            child: Icon(
              Icons.groups,
              color: AppTheme.primary,
              size: 20,
            ),
          ),
          title: const Text('All trainees'),
          subtitle: Text(
            'Get insights across all your trainees',
            style: TextStyle(
              color: AppTheme.mutedForeground,
              fontSize: 12,
            ),
          ),
          trailing: chatState.selectedTraineeId == null
              ? Icon(Icons.check, color: AppTheme.primary)
              : null,
          onTap: () {
            ref.read(aiChatProvider.notifier).selectTrainee(null, null);
            Navigator.pop(context);
          },
        ),

        const Divider(),

        // Trainee list
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _filteredTrainees.length,
            itemBuilder: (context, index) {
              final trainee = _filteredTrainees[index];
              final isSelected = chatState.selectedTraineeId == trainee.id;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    trainee.name[0].toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                title: Text(trainee.name),
                subtitle: Text(
                  trainee.email,
                  style: TextStyle(
                    color: AppTheme.mutedForeground,
                    fontSize: 12,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check, color: AppTheme.primary)
                    : null,
                onTap: () {
                  ref.read(aiChatProvider.notifier).selectTrainee(
                    trainee.id,
                    trainee.name,
                  );
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),

        SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
      ],
    );
  }
}

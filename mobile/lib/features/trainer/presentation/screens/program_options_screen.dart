import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/trainee_model.dart';
import '../providers/trainer_provider.dart';

/// Full-page program options screen for managing a trainee's program.
class ProgramOptionsScreen extends ConsumerStatefulWidget {
  final int traineeId;
  final ProgramSummary program;

  const ProgramOptionsScreen({
    super.key,
    required this.traineeId,
    required this.program,
  });

  @override
  ConsumerState<ProgramOptionsScreen> createState() => _ProgramOptionsScreenState();
}

class _ProgramOptionsScreenState extends ConsumerState<ProgramOptionsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Program Options'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Program info card
          _buildProgramInfoCard(theme),
          const SizedBox(height: 32),

          // Options
          _buildOptionTile(
            theme: theme,
            icon: Icons.swap_horiz,
            title: 'Change Program',
            subtitle: 'Assign a different program',
            color: Colors.blue,
            onTap: () {
              Navigator.pop(context);
              context.push('/trainer/programs/assign/${widget.traineeId}');
            },
          ),
          const SizedBox(height: 12),
          _buildOptionTile(
            theme: theme,
            icon: Icons.calendar_today,
            title: 'Extend Program',
            subtitle: 'Change the end date',
            color: Colors.orange,
            onTap: () => _navigateToEditProgram(context),
          ),
          const SizedBox(height: 12),
          _buildOptionTile(
            theme: theme,
            icon: Icons.cancel,
            title: 'End Program',
            subtitle: 'Remove this program from trainee',
            color: Colors.red,
            isDestructive: true,
            onTap: () => _navigateToEndProgram(context),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramInfoCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.program.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.program.startDate ?? 'N/A'} - ${widget.program.endDate ?? 'N/A'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDestructive
                ? color.withValues(alpha: 0.3)
                : theme.dividerColor.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
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
                      color: isDestructive ? color : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEditProgram(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditProgramScreen(
          traineeId: widget.traineeId,
          program: widget.program,
        ),
      ),
    );
  }

  void _navigateToEndProgram(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EndProgramScreen(
          traineeId: widget.traineeId,
          program: widget.program,
        ),
      ),
    );
  }
}

/// Screen to edit program dates.
class EditProgramScreen extends ConsumerStatefulWidget {
  final int traineeId;
  final ProgramSummary program;

  const EditProgramScreen({
    super.key,
    required this.traineeId,
    required this.program,
  });

  @override
  ConsumerState<EditProgramScreen> createState() => _EditProgramScreenState();
}

class _EditProgramScreenState extends ConsumerState<EditProgramScreen> {
  late TextEditingController _endDateController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _endDateController = TextEditingController(text: widget.program.endDate ?? '');
  }

  @override
  void dispose() {
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final initialDate = widget.program.endDate != null
        ? DateTime.tryParse(widget.program.endDate!) ?? DateTime.now().add(const Duration(days: 30))
        : DateTime.now().add(const Duration(days: 30));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      _endDateController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  Future<void> _saveChanges() async {
    if (_endDateController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.dio.patch(
        ApiConstants.programDetail(widget.program.id),
        data: {'end_date': _endDateController.text},
      );

      if (mounted) {
        ref.invalidate(traineeDetailProvider(widget.traineeId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Program updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Pop back to trainee detail
        Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name?.contains('trainee') == true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Program'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.program.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Extend or shorten the program duration',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'End Date',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.light
                        ? const Color(0xFFF5F5F8)
                        : theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _endDateController.text.isEmpty ? 'Select date' : _endDateController.text,
                          style: TextStyle(
                            color: _endDateController.text.isEmpty
                                ? theme.hintColor
                                : theme.textTheme.bodyLarge?.color,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.calendar_today,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Screen to confirm ending a program.
class EndProgramScreen extends ConsumerStatefulWidget {
  final int traineeId;
  final ProgramSummary program;

  const EndProgramScreen({
    super.key,
    required this.traineeId,
    required this.program,
  });

  @override
  ConsumerState<EndProgramScreen> createState() => _EndProgramScreenState();
}

class _EndProgramScreenState extends ConsumerState<EndProgramScreen> {
  bool _isLoading = false;

  Future<void> _endProgram() async {
    setState(() => _isLoading = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.dio.delete(ApiConstants.programDetail(widget.program.id));

      if (mounted) {
        ref.invalidate(traineeDetailProvider(widget.traineeId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Program ended successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Pop back to trainee detail
        Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name?.contains('trainee') == true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to end program: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('End Program'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cancel_outlined,
                        size: 40,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'End "${widget.program.name}"?',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'This will remove the program from this trainee. They will no longer have a workout schedule until you assign a new program.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.5,
                        color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _endProgram,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('End Program'),
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
}

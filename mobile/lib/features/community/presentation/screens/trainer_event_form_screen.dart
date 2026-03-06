import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/event_model.dart';
import '../providers/event_provider.dart';

class TrainerEventFormScreen extends ConsumerStatefulWidget {
  final int? eventId;

  const TrainerEventFormScreen({super.key, this.eventId});

  @override
  ConsumerState<TrainerEventFormScreen> createState() =>
      _TrainerEventFormScreenState();
}

class _TrainerEventFormScreenState
    extends ConsumerState<TrainerEventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _meetingUrlController = TextEditingController();
  final _maxAttendeesController = TextEditingController();

  String _eventType = 'live_session';
  bool _isVirtual = false;
  DateTime _startsAt = DateTime.now().add(const Duration(hours: 1));
  DateTime _endsAt = DateTime.now().add(const Duration(hours: 2));
  bool _isSubmitting = false;
  bool _isDeleting = false;

  bool get _isEditing => widget.eventId != null;
  CommunityEventModel? _existingEvent;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadExistingEvent();
    }
  }

  void _loadExistingEvent() {
    final state = ref.read(trainerEventProvider);
    final event =
        state.events.where((e) => e.id == widget.eventId).firstOrNull;
    if (event != null) {
      _existingEvent = event;
      _titleController.text = event.title;
      _descriptionController.text = event.description;
      _meetingUrlController.text = event.meetingUrl;
      if (event.maxAttendees != null) {
        _maxAttendeesController.text = event.maxAttendees.toString();
      }
      _eventType = event.eventType;
      _isVirtual = event.isVirtual;
      _startsAt = event.startsAt.toLocal();
      _endsAt = event.endsAt.toLocal();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _meetingUrlController.dispose();
    _maxAttendeesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Event' : 'Create Event'),
        actions: [
          if (_isEditing && _existingEvent != null) ...[
            if (!_existingEvent!.isCancelled)
              IconButton(
                icon: const Icon(Icons.cancel_outlined),
                tooltip: 'Cancel event',
                onPressed: _confirmCancel,
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete event',
              onPressed: _confirmDelete,
            ),
          ],
        ],
      ),
      body: PopScope(
        canPop: !_isSubmitting && !_isDeleting,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildTitleField(),
              const SizedBox(height: 16),
              _buildDescriptionField(),
              const SizedBox(height: 16),
              _buildEventTypeSelector(),
              const SizedBox(height: 16),
              _buildDateTimeSection(),
              const SizedBox(height: 16),
              _buildVirtualToggle(),
              if (_isVirtual) ...[
                const SizedBox(height: 12),
                _buildMeetingUrlField(),
              ],
              const SizedBox(height: 16),
              _buildMaxAttendeesField(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      maxLength: 200,
      decoration: const InputDecoration(
        labelText: 'Title',
        border: OutlineInputBorder(),
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Title is required' : null,
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLength: 2000,
      maxLines: 4,
      decoration: const InputDecoration(
        labelText: 'Description (optional)',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildEventTypeSelector() {
    return DropdownButtonFormField<String>(
      value: _eventType,
      decoration: const InputDecoration(
        labelText: 'Event Type',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'live_session', child: Text('Live Session')),
        DropdownMenuItem(value: 'q_and_a', child: Text('Q&A')),
        DropdownMenuItem(value: 'workshop', child: Text('Workshop')),
        DropdownMenuItem(value: 'challenge', child: Text('Challenge')),
        DropdownMenuItem(value: 'other', child: Text('Other')),
      ],
      onChanged: (v) {
        if (v != null) setState(() => _eventType = v);
      },
    );
  }

  Widget _buildDateTimeSection() {
    final dateFmt = DateFormat.yMMMd();
    final timeFmt = DateFormat.jm();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Start', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickDate(isStart: true),
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(dateFmt.format(_startsAt)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickTime(isStart: true),
                icon: const Icon(Icons.access_time, size: 16),
                label: Text(timeFmt.format(_startsAt)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('End', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickDate(isStart: false),
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(dateFmt.format(_endsAt)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickTime(isStart: false),
                icon: const Icon(Icons.access_time, size: 16),
                label: Text(timeFmt.format(_endsAt)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVirtualToggle() {
    return SwitchListTile(
      title: const Text('Virtual Event'),
      subtitle: const Text('Attendees join via meeting link'),
      value: _isVirtual,
      onChanged: (v) => setState(() => _isVirtual = v),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildMeetingUrlField() {
    return TextFormField(
      controller: _meetingUrlController,
      keyboardType: TextInputType.url,
      decoration: const InputDecoration(
        labelText: 'Meeting Link',
        hintText: 'https://zoom.us/j/...',
        border: OutlineInputBorder(),
      ),
      validator: (v) {
        if (!_isVirtual) return null;
        if (v != null && v.isNotEmpty) {
          final uri = Uri.tryParse(v);
          if (uri == null || !uri.hasScheme) {
            return 'Enter a valid URL';
          }
        }
        return null;
      },
    );
  }

  Widget _buildMaxAttendeesField() {
    return TextFormField(
      controller: _maxAttendeesController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Max Attendees (optional)',
        helperText: 'Leave empty for unlimited.',
        border: OutlineInputBorder(),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null;
        final n = int.tryParse(v.trim());
        if (n == null || n < 1) return 'Must be at least 1';
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _isSubmitting ? null : _submit,
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(_isEditing ? 'Save Changes' : 'Create Event'),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startsAt : _endsAt;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startsAt = DateTime(
          picked.year, picked.month, picked.day,
          _startsAt.hour, _startsAt.minute,
        );
        if (_endsAt.isBefore(_startsAt)) {
          _endsAt = _startsAt.add(const Duration(hours: 1));
        }
      } else {
        _endsAt = DateTime(
          picked.year, picked.month, picked.day,
          _endsAt.hour, _endsAt.minute,
        );
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart
        ? TimeOfDay.fromDateTime(_startsAt)
        : TimeOfDay.fromDateTime(_endsAt);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startsAt = DateTime(
          _startsAt.year, _startsAt.month, _startsAt.day,
          picked.hour, picked.minute,
        );
        if (_endsAt.isBefore(_startsAt)) {
          _endsAt = _startsAt.add(const Duration(hours: 1));
        }
      } else {
        _endsAt = DateTime(
          _endsAt.year, _endsAt.month, _endsAt.day,
          picked.hour, picked.minute,
        );
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_endsAt.isBefore(_startsAt) || _endsAt == _startsAt) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('End time must be after start time'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final maxAtt = _maxAttendeesController.text.trim().isEmpty
          ? null
          : int.tryParse(_maxAttendeesController.text.trim());

      if (_isEditing) {
        await ref.read(trainerEventProvider.notifier).updateEvent(
              widget.eventId!,
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim(),
              eventType: _eventType,
              startsAt: _startsAt,
              endsAt: _endsAt,
              meetingUrl: _isVirtual ? _meetingUrlController.text.trim() : '',
              maxAttendees: maxAtt,
              clearMaxAttendees: maxAtt == null,
            );
      } else {
        await ref.read(trainerEventProvider.notifier).createEvent(
              title: _titleController.text.trim(),
              eventType: _eventType,
              startsAt: _startsAt,
              endsAt: _endsAt,
              description: _descriptionController.text.trim(),
              meetingUrl:
                  _isVirtual ? _meetingUrlController.text.trim() : '',
              maxAttendees: maxAtt,
            );
      }

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Event updated' : 'Event created'),
        ),
      );
      context.pop(_isEditing ? 'updated' : 'created');
    } on Exception {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to ${_isEditing ? "update" : "create"} event. Try again.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _confirmCancel() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Event?'),
        content: const Text(
          'Trainees will see this event as cancelled. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(trainerEventProvider.notifier)
                    .cancelEvent(widget.eventId!);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Event cancelled')),
                );
                context.pop('updated');
              } on Exception {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Failed to cancel event'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Cancel Event'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event?'),
        content: const Text(
          'This event will be permanently deleted. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isDeleting = true);
              try {
                await ref
                    .read(trainerEventProvider.notifier)
                    .deleteEvent(widget.eventId!);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Event deleted')),
                );
                context.pop('deleted');
              } on Exception {
                if (!mounted) return;
                setState(() => _isDeleting = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Failed to delete event'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

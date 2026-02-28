import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../shared/widgets/adaptive/adaptive_dialog.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../providers/calendar_provider.dart';
import '../../data/models/calendar_connection_model.dart';
import '../widgets/calendar_card.dart';

class CalendarConnectionScreen extends ConsumerStatefulWidget {
  const CalendarConnectionScreen({super.key});

  @override
  ConsumerState<CalendarConnectionScreen> createState() =>
      _CalendarConnectionScreenState();
}

class _CalendarConnectionScreenState
    extends ConsumerState<CalendarConnectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(calendarProvider.notifier).loadConnections();
    });
  }

  Future<void> _connectProvider(String provider) async {
    final notifier = ref.read(calendarProvider.notifier);
    final authUrl = provider == 'google'
        ? await notifier.getGoogleAuthUrl()
        : await notifier.getMicrosoftAuthUrl();

    if (authUrl != null && mounted) {
      final uri = Uri.parse(authUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) _showCallbackDialog(provider);
      } else {
        if (mounted) {
          showAdaptiveToast(context,
              message: 'Could not open browser', type: ToastType.error);
        }
      }
    }
  }

  void _showCallbackDialog(String provider) {
    final codeController = TextEditingController();
    final stateController = TextEditingController();
    final providerName = provider == 'google' ? 'Google' : 'Microsoft';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Complete $providerName Connection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'After authorizing in the browser, copy and paste the values here:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Authorization Code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: stateController,
              decoration: const InputDecoration(
                labelText: 'State Parameter',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final code = codeController.text.trim();
              final state = stateController.text.trim();
              if (code.isEmpty || state.isEmpty) {
                showAdaptiveToast(context,
                    message: 'Please enter both code and state',
                    type: ToastType.warning);
                return;
              }
              Navigator.pop(context);
              final notifier = ref.read(calendarProvider.notifier);
              final success = provider == 'google'
                  ? await notifier.completeGoogleCallback(code, state)
                  : await notifier.completeMicrosoftCallback(code, state);
              if (mounted && success) {
                showAdaptiveToast(context,
                    message: '$providerName Calendar connected!',
                    type: ToastType.success);
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  Future<void> _disconnectCalendar(CalendarConnectionModel connection) async {
    final confirmed = await showAdaptiveConfirmDialog(
      context: context,
      title: 'Disconnect Calendar',
      message:
          'Are you sure you want to disconnect ${connection.providerDisplay}?\n\n'
          'This will remove all synced events from this calendar.',
      confirmText: 'Disconnect',
      isDestructive: true,
    );
    if (confirmed == true) {
      await ref
          .read(calendarProvider.notifier)
          .disconnectCalendar(connection.provider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calendarProvider);
    final theme = Theme.of(context);

    ref.listen<CalendarState>(calendarProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        showAdaptiveToast(context, message: next.error!, type: ToastType.error);
        ref.read(calendarProvider.notifier).clearMessages();
      }
      if (next.successMessage != null &&
          next.successMessage != previous?.successMessage) {
        showAdaptiveToast(context,
            message: next.successMessage!, type: ToastType.success);
        ref.read(calendarProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar Integration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: state.isLoading && state.connections.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(calendarProvider.notifier).loadConnections(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: 24),
                  CalendarCard(
                    provider: 'google',
                    title: 'Google Calendar',
                    icon: Icons.calendar_today,
                    iconColor: Colors.red,
                    connection: state.googleConnection,
                    onConnect: () => _connectProvider('google'),
                    onDisconnect: state.googleConnection != null
                        ? () => _disconnectCalendar(state.googleConnection!)
                        : null,
                    onSync: state.hasGoogleConnected
                        ? () => ref
                            .read(calendarProvider.notifier)
                            .syncCalendar('google')
                        : null,
                    isLoading: state.isLoading,
                  ),
                  const SizedBox(height: 16),
                  CalendarCard(
                    provider: 'microsoft',
                    title: 'Microsoft Outlook',
                    icon: Icons.mail_outline,
                    iconColor: Colors.blue,
                    connection: state.microsoftConnection,
                    onConnect: () => _connectProvider('microsoft'),
                    onDisconnect: state.microsoftConnection != null
                        ? () => _disconnectCalendar(state.microsoftConnection!)
                        : null,
                    onSync: state.hasMicrosoftConnected
                        ? () => ref
                            .read(calendarProvider.notifier)
                            .syncCalendar('microsoft')
                        : null,
                    isLoading: state.isLoading,
                  ),
                  const SizedBox(height: 32),
                  if (state.hasAnyConnection) ...[
                    _buildActionsSection(theme),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month,
                  color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Connect Your Calendar',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Sync your Google or Microsoft calendar to manage appointments and availability.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Synced Events',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () => context.push('/trainer/calendar/events'),
              icon: const Icon(Icons.event, size: 18),
              label: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Your calendar events are synced automatically. You can also set your availability for clients.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => context.push('/trainer/calendar/availability'),
          icon: const Icon(Icons.access_time),
          label: const Text('Manage Availability'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }
}

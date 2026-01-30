import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/calendar_provider.dart';
import '../../data/models/calendar_connection_model.dart';

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

  Future<void> _connectGoogle() async {
    final notifier = ref.read(calendarProvider.notifier);
    final authUrl = await notifier.getGoogleAuthUrl();

    if (authUrl != null && mounted) {
      final uri = Uri.parse(authUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        // Show dialog to enter callback code
        if (mounted) {
          _showCallbackDialog('google');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open browser')),
        );
      }
    }
  }

  Future<void> _connectMicrosoft() async {
    final notifier = ref.read(calendarProvider.notifier);
    final authUrl = await notifier.getMicrosoftAuthUrl();

    if (authUrl != null && mounted) {
      final uri = Uri.parse(authUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        // Show dialog to enter callback code
        if (mounted) {
          _showCallbackDialog('microsoft');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open browser')),
        );
      }
    }
  }

  void _showCallbackDialog(String provider) {
    final codeController = TextEditingController();
    final stateController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Complete ${provider == 'google' ? 'Google' : 'Microsoft'} Connection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'After authorizing in the browser, you\'ll be redirected to a page with a code. Copy and paste the values here:',
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter both code and state')),
                );
                return;
              }

              Navigator.pop(context);

              final notifier = ref.read(calendarProvider.notifier);
              bool success;

              if (provider == 'google') {
                success = await notifier.completeGoogleCallback(code, state);
              } else {
                success = await notifier.completeMicrosoftCallback(code, state);
              }

              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${provider == 'google' ? 'Google' : 'Microsoft'} Calendar connected!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  Future<void> _disconnectCalendar(CalendarConnectionModel connection) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Calendar'),
        content: Text(
          'Are you sure you want to disconnect ${connection.providerDisplay}?\n\n'
          'This will remove all synced events from this calendar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(calendarProvider.notifier).disconnectCalendar(connection.provider);
    }
  }

  Future<void> _syncCalendar(String provider) async {
    await ref.read(calendarProvider.notifier).syncCalendar(provider);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calendarProvider);
    final theme = Theme.of(context);

    // Listen for error/success messages
    ref.listen<CalendarState>(calendarProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(calendarProvider.notifier).clearMessages();
      }
      if (next.successMessage != null &&
          next.successMessage != previous?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
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
                  // Header
                  Container(
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
                            Icon(
                              Icons.calendar_month,
                              color: theme.colorScheme.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Connect Your Calendar',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
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
                  ),

                  const SizedBox(height: 24),

                  // Google Calendar
                  _buildCalendarCard(
                    context: context,
                    provider: 'google',
                    title: 'Google Calendar',
                    icon: Icons.calendar_today,
                    iconColor: Colors.red,
                    connection: state.googleConnection,
                    onConnect: _connectGoogle,
                    onDisconnect: state.googleConnection != null
                        ? () => _disconnectCalendar(state.googleConnection!)
                        : null,
                    onSync: state.hasGoogleConnected
                        ? () => _syncCalendar('google')
                        : null,
                    isLoading: state.isLoading,
                  ),

                  const SizedBox(height: 16),

                  // Microsoft Calendar
                  _buildCalendarCard(
                    context: context,
                    provider: 'microsoft',
                    title: 'Microsoft Outlook',
                    icon: Icons.mail_outline,
                    iconColor: Colors.blue,
                    connection: state.microsoftConnection,
                    onConnect: _connectMicrosoft,
                    onDisconnect: state.microsoftConnection != null
                        ? () => _disconnectCalendar(state.microsoftConnection!)
                        : null,
                    onSync: state.hasMicrosoftConnected
                        ? () => _syncCalendar('microsoft')
                        : null,
                    isLoading: state.isLoading,
                  ),

                  const SizedBox(height: 32),

                  // Availability section
                  if (state.hasAnyConnection) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Synced Events',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            context.push('/trainer/calendar/events');
                          },
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
                      onPressed: () {
                        context.push('/trainer/availability');
                      },
                      icon: const Icon(Icons.access_time),
                      label: const Text('Manage Availability'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildCalendarCard({
    required BuildContext context,
    required String provider,
    required String title,
    required IconData icon,
    required Color iconColor,
    CalendarConnectionModel? connection,
    required VoidCallback onConnect,
    VoidCallback? onDisconnect,
    VoidCallback? onSync,
    required bool isLoading,
  }) {
    final theme = Theme.of(context);
    final isConnected = connection != null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isConnected
              ? Colors.green.withOpacity(0.5)
              : theme.colorScheme.outline.withOpacity(0.3),
          width: isConnected ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 12),
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
                      if (isConnected && connection.calendarEmail != null)
                        Text(
                          connection.calendarEmail!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isConnected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Connected',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            if (isConnected) ...[
              const SizedBox(height: 16),
              if (connection.lastSyncedAt != null)
                Text(
                  'Last synced: ${_formatDate(connection.lastSyncedAt!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : onSync,
                      icon: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync, size: 18),
                      label: const Text('Sync Now'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: isLoading ? null : onDisconnect,
                    icon: const Icon(Icons.link_off),
                    tooltip: 'Disconnect',
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: isLoading ? null : onConnect,
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_link),
                label: Text('Connect $title'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}

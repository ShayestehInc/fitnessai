import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../shared/widgets/adaptive/adaptive_dialog.dart';
import '../../../../shared/widgets/adaptive/adaptive_refresh_indicator.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../providers/calendar_provider.dart';
import '../../data/models/calendar_connection_model.dart';
import '../widgets/calendar_actions_section.dart';
import '../widgets/calendar_card.dart';
import '../widgets/calendar_connection_header.dart';

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

    if (!mounted) return;

    if (authUrl == null) {
      // Error toast is already shown via the listener for state.error,
      // but if the notifier returned null without setting an error,
      // show a fallback message.
      final state = ref.read(calendarProvider);
      if (state.error == null) {
        showAdaptiveToast(context,
            message: 'Could not get authorization URL',
            type: ToastType.error);
      }
      return;
    }

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

  void _showCallbackDialog(String provider) {
    final codeController = TextEditingController();
    final stateController = TextEditingController();
    final providerName = provider == 'google' ? 'Google' : 'Microsoft';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
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
              autofocus: true,
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
            onPressed: () {
              Navigator.pop(dialogContext);
              codeController.dispose();
              stateController.dispose();
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final code = codeController.text.trim();
              final stateParam = stateController.text.trim();
              if (code.isEmpty || stateParam.isEmpty) {
                showAdaptiveToast(dialogContext,
                    message: 'Please enter both code and state',
                    type: ToastType.warning);
                return;
              }
              Navigator.pop(dialogContext);
              final notifier = ref.read(calendarProvider.notifier);
              final success = provider == 'google'
                  ? await notifier.completeGoogleCallback(code, stateParam)
                  : await notifier.completeMicrosoftCallback(code, stateParam);
              codeController.dispose();
              stateController.dispose();
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
          tooltip: 'Go back',
        ),
      ),
      body: state.isLoading && state.connections.isEmpty
          ? const Center(child: AdaptiveSpinner())
          : AdaptiveRefreshIndicator(
              onRefresh: () =>
                  ref.read(calendarProvider.notifier).loadConnections(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const CalendarConnectionHeader(),
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
                    const CalendarActionsSection(),
                  ],
                ],
              ),
            ),
    );
  }
}

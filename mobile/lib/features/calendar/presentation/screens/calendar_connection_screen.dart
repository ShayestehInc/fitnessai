import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../shared/widgets/adaptive/adaptive_bottom_sheet.dart';
import '../../../../shared/widgets/adaptive/adaptive_dialog.dart';
import '../../../../shared/widgets/adaptive/adaptive_icons.dart';
import '../../../../shared/widgets/adaptive/adaptive_refresh_indicator.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../providers/calendar_provider.dart';
import '../../data/models/calendar_connection_model.dart';
import '../widgets/calendar_actions_section.dart';
import '../widgets/calendar_card.dart';
import '../widgets/calendar_connection_header.dart';
import '../../../../core/l10n/l10n_extension.dart';

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
            message: context.l10n.calendarCouldNotGetAuthorizationURL,
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
            message: context.l10n.calendarCouldNotOpenBrowser, type: ToastType.error);
      }
    }
  }

  void _showCallbackDialog(String provider) {
    final codeController = TextEditingController();
    final stateController = TextEditingController();
    final providerName = provider == 'google' ? 'Google' : 'Microsoft';

    showAdaptiveBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Complete $providerName Connection',
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'After authorizing in the browser, copy and paste the values here:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                decoration: InputDecoration(
                  labelText: context.l10n.calendarAuthorizationCode,
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stateController,
                decoration: InputDecoration(
                  labelText: context.l10n.calendarStateParameter,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        codeController.dispose();
                        stateController.dispose();
                      },
                      child: Text(context.l10n.commonCancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        final code = codeController.text.trim();
                        final stateParam = stateController.text.trim();
                        if (code.isEmpty || stateParam.isEmpty) {
                          showAdaptiveToast(sheetContext,
                              message: context.l10n.calendarPleaseEnterBothCodeAndState,
                              type: ToastType.warning);
                          return;
                        }
                        Navigator.pop(sheetContext);
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
                      child: Text(context.l10n.calendarConnect),
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

  Future<void> _disconnectCalendar(CalendarConnectionModel connection) async {
    final confirmed = await showAdaptiveConfirmDialog(
      context: context,
      title: context.l10n.calendarDisconnectCalendar,
      message:
          'Are you sure you want to disconnect ${connection.providerDisplay}?\n\n'
          'This will remove all synced events from this calendar.',
      confirmText: context.l10n.calendarDisconnect,
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
        title: Text(context.l10n.settingsCalendar),
        leading: IconButton(
          icon: Icon(AdaptiveIcons.back),
          onPressed: () => context.pop(),
          tooltip: context.l10n.calendarGoBack,
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
                    title: context.l10n.calendarGoogleCalendar,
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
                  // TODO: Re-enable Microsoft calendar when keys are configured
                  // const SizedBox(height: 16),
                  // CalendarCard(
                  //   provider: 'microsoft',
                  //   title: context.l10n.calendarMicrosoftOutlook,
                  //   icon: Icons.mail_outline,
                  //   iconColor: Colors.blue,
                  //   connection: state.microsoftConnection,
                  //   onConnect: () => _connectProvider('microsoft'),
                  //   onDisconnect: state.microsoftConnection != null
                  //       ? () => _disconnectCalendar(state.microsoftConnection!)
                  //       : null,
                  //   onSync: state.hasMicrosoftConnected
                  //       ? () => ref
                  //           .read(calendarProvider.notifier)
                  //           .syncCalendar('microsoft')
                  //       : null,
                  //   isLoading: state.isLoading,
                  // ),
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

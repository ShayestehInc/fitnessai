import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/adaptive/adaptive_dialog.dart';
import '../../../../shared/widgets/adaptive/adaptive_refresh_indicator.dart';
import '../../../../shared/widgets/adaptive/adaptive_scroll_physics.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_tappable.dart';
import '../../../ambassador/data/models/ambassador_models.dart';
import '../../../ambassador/presentation/providers/ambassador_provider.dart';
import '../../../../core/l10n/l10n_extension.dart';

class AdminAmbassadorsScreen extends ConsumerStatefulWidget {
  const AdminAmbassadorsScreen({super.key});

  @override
  ConsumerState<AdminAmbassadorsScreen> createState() =>
      _AdminAmbassadorsScreenState();
}

class _AdminAmbassadorsScreenState
    extends ConsumerState<AdminAmbassadorsScreen> {
  final _searchController = TextEditingController();
  bool? _activeFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminAmbassadorsProvider.notifier).loadAmbassadors();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    ref.read(adminAmbassadorsProvider.notifier).loadAmbassadors(
          search: _searchController.text.trim(),
          isActive: _activeFilter,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(adminAmbassadorsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.l10n.adminAmbassadors),
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: context.l10n.adminCreateAmbassador,
            onPressed: () => context.push('/admin/ambassadors/create'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: context.l10n.adminSearchByNameOrEmail,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                Theme.of(context).platform == TargetPlatform.iOS
                    ? IconButton(
                        icon: Icon(
                          Icons.filter_list,
                          color: _activeFilter != null
                              ? theme.colorScheme.primary
                              : theme.textTheme.bodySmall?.color,
                        ),
                        onPressed: () => showAdaptiveActionSheet(
                          context: context,
                          title: context.l10n.commonFilter,
                          actions: [
                            AdaptiveAction(
                              label: context.l10n.commonAll,
                              onPressed: () {
                                setState(() => _activeFilter = null);
                                _search();
                              },
                            ),
                            AdaptiveAction(
                              label: context.l10n.adminActive,
                              onPressed: () {
                                setState(() => _activeFilter = true);
                                _search();
                              },
                            ),
                            AdaptiveAction(
                              label: context.l10n.adminInactive,
                              onPressed: () {
                                setState(() => _activeFilter = false);
                                _search();
                              },
                            ),
                          ],
                        ),
                      )
                    : PopupMenuButton<bool?>(
                        icon: Icon(
                          Icons.filter_list,
                          color: _activeFilter != null
                              ? theme.colorScheme.primary
                              : theme.textTheme.bodySmall?.color,
                        ),
                        onSelected: (value) {
                          setState(() => _activeFilter = value);
                          _search();
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(value: null, child: Text(context.l10n.commonAll)),
                          PopupMenuItem(value: true, child: Text(context.l10n.adminActive)),
                          PopupMenuItem(value: false, child: Text(context.l10n.adminInactive)),
                        ],
                      ),
              ],
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: AdaptiveSpinner())
                : state.error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                              const SizedBox(height: 16),
                              Text(
                                'Could not load ambassadors',
                                style: TextStyle(
                                  color: theme.textTheme.bodyLarge?.color,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                state.error!,
                                style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 14),
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _search,
                                icon: const Icon(Icons.refresh, size: 18),
                                label: Text(context.l10n.commonRetry),
                              ),
                            ],
                          ),
                        ),
                      )
                    : state.ambassadors.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.handshake_outlined,
                                    size: 64, color: theme.textTheme.bodySmall?.color),
                                const SizedBox(height: 16),
                                Text(
                                  'No ambassadors found',
                                  style: TextStyle(
                                      color: theme.textTheme.bodySmall?.color, fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : AdaptiveRefreshIndicator(
                            onRefresh: () => ref
                                .read(adminAmbassadorsProvider.notifier)
                                .loadAmbassadors(
                                  search: _searchController.text.trim().isNotEmpty
                                      ? _searchController.text.trim()
                                      : null,
                                  isActive: _activeFilter,
                                ),
                            child: ListView.builder(
                              physics: adaptiveAlwaysScrollablePhysics(context),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: state.ambassadors.length,
                              itemBuilder: (context, index) =>
                                  _buildAmbassadorTile(theme, state.ambassadors[index]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbassadorTile(ThemeData theme, AmbassadorProfile ambassador) {
    return Semantics(
      button: true,
      label: '${ambassador.user.displayName}, ${ambassador.totalReferrals} referrals, ${ambassador.isActive ? "active" : "inactive"}',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AdaptiveTappable(
          onTap: () => context.push('/admin/ambassadors/${ambassador.id}'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: ambassador.isActive
                      ? Colors.teal.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.handshake,
                    color: ambassador.isActive ? Colors.teal : Colors.grey,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ambassador.user.displayName,
                        style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        ambassador.user.email,
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${ambassador.totalReferrals} referrals',
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '\$${ambassador.totalEarnings}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: theme.textTheme.bodySmall?.color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


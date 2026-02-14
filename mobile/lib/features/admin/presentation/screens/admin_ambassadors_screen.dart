import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../ambassador/data/models/ambassador_models.dart';
import '../../../ambassador/presentation/providers/ambassador_provider.dart';

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
        title: const Text('Ambassadors'),
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create Ambassador',
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
                      hintText: 'Search by name or email...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<bool?>(
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
                    const PopupMenuItem(value: null, child: Text('All')),
                    const PopupMenuItem(value: true, child: Text('Active')),
                    const PopupMenuItem(value: false, child: Text('Inactive')),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(state.error!, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _search,
                              child: const Text('Retry'),
                            ),
                          ],
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
                        : RefreshIndicator(
                            onRefresh: () => ref
                                .read(adminAmbassadorsProvider.notifier)
                                .loadAmbassadors(),
                            child: ListView.builder(
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
    return GestureDetector(
      onTap: () => context.push('/admin/ambassadors/${ambassador.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
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
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/adaptive/adaptive_refresh_indicator.dart';
import '../../../../shared/widgets/adaptive/adaptive_scroll_physics.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../data/models/space_model.dart';
import '../providers/space_provider.dart';

/// Browse / search all spaces in the trainer's community.
class SpaceListScreen extends ConsumerStatefulWidget {
  const SpaceListScreen({super.key});

  @override
  ConsumerState<SpaceListScreen> createState() => _SpaceListScreenState();
}

class _SpaceListScreenState extends ConsumerState<SpaceListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(spacesProvider.notifier).loadSpaces();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacesState = ref.watch(spacesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spaces'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(theme),
          Expanded(
            child: AdaptiveRefreshIndicator(
              onRefresh: () =>
                  ref.read(spacesProvider.notifier).loadSpaces(),
              child: _buildBody(theme, spacesState),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search spaces...',
          prefixIcon: const Icon(Icons.search, size: 20),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: theme.scaffoldBackgroundColor,
          isDense: true,
        ),
        onChanged: (value) => setState(() => _query = value.trim()),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, SpacesState spacesState) {
    if (spacesState.isLoading && spacesState.spaces.isEmpty) {
      return const Center(child: AdaptiveSpinner());
    }

    if (spacesState.error != null && spacesState.spaces.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              spacesState.error!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () =>
                  ref.read(spacesProvider.notifier).loadSpaces(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filtered = _filterSpaces(spacesState.spaces);

    if (filtered.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ListView.separated(
      physics: adaptiveAlwaysScrollablePhysics(context),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _SpaceCard(
        space: filtered[index],
        onTap: () => context.push('/community/spaces/${filtered[index].id}'),
      ),
    );
  }

  List<SpaceModel> _filterSpaces(List<SpaceModel> spaces) {
    if (_query.isEmpty) return spaces;
    final lower = _query.toLowerCase();
    return spaces
        .where((s) =>
            s.name.toLowerCase().contains(lower) ||
            s.description.toLowerCase().contains(lower))
        .toList();
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group_outlined,
                size: 64, color: theme.textTheme.bodySmall?.color),
            const SizedBox(height: 16),
            Text(
              _query.isEmpty ? 'No spaces yet' : 'No matching spaces',
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card displaying a single space in the list.
class _SpaceCard extends StatelessWidget {
  final SpaceModel space;
  final VoidCallback onTap;

  const _SpaceCard({required this.space, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            // Emoji avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                space.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 12),
            // Space info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    space.name,
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (space.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      space.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.people_outline,
                          size: 14, color: theme.textTheme.bodySmall?.color),
                      const SizedBox(width: 4),
                      Text(
                        '${space.memberCount} member${space.memberCount == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 12,
                        ),
                      ),
                      if (space.isPrivate) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.lock_outline,
                            size: 14, color: theme.textTheme.bodySmall?.color),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Membership badge
            if (space.isMember)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Joined',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

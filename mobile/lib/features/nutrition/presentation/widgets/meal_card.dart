import 'package:flutter/material.dart';
import '../../../../shared/widgets/adaptive/adaptive_tappable.dart';
import '../../data/models/nutrition_models.dart';

class MealCard extends StatelessWidget {
  final MealLogModel meal;
  final VoidCallback onAddFood;
  final void Function(MealLogEntryModel entry) onDeleteEntry;

  const MealCard({
    super.key,
    required this.meal,
    required this.onAddFood,
    required this.onDeleteEntry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Text(
                    meal.displayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Meal subtotals
                Text(
                  '${meal.totalCalories} cal',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                AdaptiveTappable(
                  onTap: onAddFood,
                  child: Icon(
                    Icons.add_circle_outline,
                    color: theme.colorScheme.primary,
                    size: 24,
                    semanticLabel: 'Add food to ${meal.displayName}',
                  ),
                ),
              ],
            ),

            if (meal.entries.isEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'No foods logged yet',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ] else ...[
              const SizedBox(height: 4),
              // Macro subtotals row
              Row(
                children: [
                  _MacroChip(label: 'P', value: meal.totalProtein, color: Colors.blue),
                  const SizedBox(width: 8),
                  _MacroChip(label: 'C', value: meal.totalCarbs, color: Colors.orange),
                  const SizedBox(width: 8),
                  _MacroChip(label: 'F', value: meal.totalFat, color: Colors.red),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              // Entry list
              ...meal.entries.map((entry) => _EntryRow(
                    entry: entry,
                    onDelete: () => onDeleteEntry(entry),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: ${value.toStringAsFixed(0)}g',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  final MealLogEntryModel entry;
  final VoidCallback onDelete;

  const _EntryRow({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: theme.colorScheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return true; // Deletion handled with undo snackbar by parent
      },
      onDismissed: (_) => onDelete(),
      child: Semantics(
        label: '${entry.displayName}, ${entry.calories} calories. Swipe left to delete.',
        child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.displayName,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${entry.quantity}x ${entry.servingUnit}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entry.calories} cal',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'P${entry.protein.toStringAsFixed(0)} C${entry.carbs.toStringAsFixed(0)} F${entry.fat.toStringAsFixed(0)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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

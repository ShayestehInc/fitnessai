import 'package:flutter/material.dart';
import '../../../../shared/widgets/animated_widgets.dart';
import '../../data/models/branding_model.dart';

/// Color picker section for the branding screen.
class BrandingColorSection extends StatelessWidget {
  final Color primaryColor;
  final Color secondaryColor;
  final ValueChanged<Color> onPrimaryChanged;
  final ValueChanged<Color> onSecondaryChanged;

  const BrandingColorSection({
    super.key,
    required this.primaryColor,
    required this.secondaryColor,
    required this.onPrimaryChanged,
    required this.onSecondaryChanged,
  });

  static const _presetColors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Purple
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Emerald
    Color(0xFFF43F5E), // Rose
    Color(0xFFF59E0B), // Amber
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEC4899), // Pink
    Color(0xFFEF4444), // Red
    Color(0xFF14B8A6), // Teal
    Color(0xFF8B5E3C), // Brown
    Color(0xFF64748B), // Slate
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StaggeredListItem(
      index: 3,
      delay: const Duration(milliseconds: 30),
      child: Column(
        children: [
          _buildColorRow(
            theme: theme,
            context: context,
            label: 'Primary Color',
            subtitle: 'Buttons, headers, accent elements',
            color: primaryColor,
            onTap: () => _showColorPicker(
              context: context,
              currentColor: primaryColor,
              title: 'Primary Color',
              onSelected: onPrimaryChanged,
            ),
          ),
          const SizedBox(height: 8),
          _buildColorRow(
            theme: theme,
            context: context,
            label: 'Secondary Color',
            subtitle: 'Highlights, badges, secondary actions',
            color: secondaryColor,
            onTap: () => _showColorPicker(
              context: context,
              currentColor: secondaryColor,
              title: 'Secondary Color',
              onSelected: onSecondaryChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorRow({
    required ThemeData theme,
    required BuildContext context,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedPress(
      onTap: onTap,
      scaleDown: 0.98,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.dividerColor,
                  width: 1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              BrandingModel.colorToHex(color),
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              color: theme.textTheme.bodySmall?.color,
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker({
    required BuildContext context,
    required Color currentColor,
    required String title,
    required ValueChanged<Color> onSelected,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 280,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _presetColors.map((color) {
                final isSelected = color == currentColor;
                return GestureDetector(
                  onTap: () {
                    onSelected(color);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../shared/widgets/animated_widgets.dart';

/// Preview card showing how branding will appear to trainees.
class BrandingPreviewCard extends StatelessWidget {
  final String appName;
  final Color primaryColor;
  final Color secondaryColor;
  final String? logoUrl;

  const BrandingPreviewCard({
    super.key,
    required this.appName,
    required this.primaryColor,
    required this.secondaryColor,
    this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = appName.isNotEmpty ? appName : 'FitnessAI';
    final hasLogo = logoUrl != null && logoUrl!.isNotEmpty;

    return StaggeredListItem(
      index: 0,
      delay: const Duration(milliseconds: 30),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor.withValues(alpha: 0.15),
              secondaryColor.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Text(
              'Preview',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            _buildMiniLogo(hasLogo),
            const SizedBox(height: 12),
            Text(
              displayName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            _buildSampleButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniLogo(bool hasLogo) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: hasLogo
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                logoUrl!,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.fitness_center,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            )
          : const Icon(
              Icons.fitness_center,
              color: Colors.white,
              size: 28,
            ),
    );
  }

  Widget _buildSampleButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Start Workout',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: secondaryColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'View Plan',
            style: TextStyle(color: secondaryColor, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

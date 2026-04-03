import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class MuscleInfoBottomSheet extends StatelessWidget {
  final String muscleSlug;
  final String displayName;
  final String? latinName;
  final String? description;
  final String? bodyRegion;
  final int movementCount;
  final int exerciseCount;

  const MuscleInfoBottomSheet({
    super.key,
    required this.muscleSlug,
    required this.displayName,
    this.latinName,
    this.description,
    this.bodyRegion,
    this.movementCount = 0,
    this.exerciseCount = 0,
  });

  static Future<void> show(
    BuildContext context, {
    required String muscleSlug,
    required String displayName,
    String? latinName,
    String? description,
    String? bodyRegion,
    int movementCount = 0,
    int exerciseCount = 0,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      isScrollControlled: true,
      builder: (_) => MuscleInfoBottomSheet(
        muscleSlug: muscleSlug,
        displayName: displayName,
        latinName: latinName,
        description: description,
        bodyRegion: bodyRegion,
        movementCount: movementCount,
        exerciseCount: exerciseCount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF6366F1);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111114).withValues(alpha: 0.92),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(
                color: accent.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Glowing accent line
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 20),
                      width: 48,
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accent.withValues(alpha: 0.0),
                            accent,
                            accent.withValues(alpha: 0.0),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Region badge
                  if (bodyRegion != null && bodyRegion!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        bodyRegion!.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: accent.withValues(alpha: 0.9),
                        ),
                      ),
                    ),

                  // Muscle name
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),

                  // Latin name
                  if (latinName != null && latinName!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        latinName!,
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ),

                  // Description
                  if (description != null && description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Text(
                        description!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),

                  // Quick stats
                  if (movementCount > 0 || exerciseCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        children: [
                          if (movementCount > 0)
                            _StatChip(
                              icon: Icons.swap_horiz,
                              label: '$movementCount movements',
                            ),
                          if (movementCount > 0 && exerciseCount > 0)
                            const SizedBox(width: 12),
                          if (exerciseCount > 0)
                            _StatChip(
                              icon: Icons.fitness_center,
                              label: '$exerciseCount exercises',
                            ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Explore button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/anatomy/muscles/$muscleSlug');
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'EXPLORE MUSCLE',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.white.withValues(alpha: 0.35),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}

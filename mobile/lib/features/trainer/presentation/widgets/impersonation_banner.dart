import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/trainer_provider.dart';

class ImpersonationBanner extends ConsumerWidget {
  const ImpersonationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final impersonationState = ref.watch(impersonationProvider);

    if (!impersonationState.isImpersonating) {
      return const SizedBox.shrink();
    }

    final traineeName = impersonationState.trainee?.firstName != null
        ? '${impersonationState.trainee!.firstName} ${impersonationState.trainee!.lastName ?? ""}'.trim()
        : impersonationState.trainee?.email ?? 'Trainee';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade700, Colors.purple.shade500],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.visibility,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Viewing as Trainee',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    traineeName,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => _endImpersonation(context, ref),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.purple.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: const Icon(Icons.exit_to_app, size: 18),
              label: const Text(
                'Exit',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _endImpersonation(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(impersonationProvider.notifier).endImpersonation();

    if (context.mounted) {
      if (result['success']) {
        // Navigate back to trainer dashboard
        context.go('/trainer');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to end session'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Wrapper that adds the impersonation banner above the child widget
class ImpersonationBannerWrapper extends ConsumerWidget {
  final Widget child;

  const ImpersonationBannerWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final impersonationState = ref.watch(impersonationProvider);

    if (!impersonationState.isImpersonating) {
      return child;
    }

    return Column(
      children: [
        const ImpersonationBanner(),
        Expanded(child: child),
      ],
    );
  }
}

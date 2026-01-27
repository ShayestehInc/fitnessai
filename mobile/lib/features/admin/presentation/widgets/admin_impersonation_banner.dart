import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_impersonation_provider.dart';

/// Banner shown when admin is impersonating a trainer
class AdminImpersonationBanner extends ConsumerWidget {
  const AdminImpersonationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminImpersonationProvider);

    if (!state.isImpersonating) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade700, Colors.orange.shade500],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
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
                Icons.admin_panel_settings,
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
                    'Viewing as Trainer',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    state.trainerName ?? state.trainerEmail ?? 'Trainer',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'ADMIN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: () => _endImpersonation(context, ref),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.orange.shade700,
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
    final result = await ref.read(adminImpersonationProvider.notifier).endImpersonation();

    if (context.mounted) {
      if (result['success'] == true) {
        // Navigate back to admin dashboard
        context.go('/admin');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Returned to admin account'),
            backgroundColor: Colors.green,
          ),
        );
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

/// Wrapper that adds the admin impersonation banner above the child widget
class AdminImpersonationBannerWrapper extends ConsumerWidget {
  final Widget child;

  const AdminImpersonationBannerWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminImpersonationProvider);

    if (!state.isImpersonating) {
      return child;
    }

    return Column(
      children: [
        const AdminImpersonationBanner(),
        Expanded(child: child),
      ],
    );
  }
}

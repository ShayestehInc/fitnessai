import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/adaptive/adaptive_tappable.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';

/// Data class representing a single FAQ entry.
class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});
}

/// Data class representing a titled section of FAQ items.
class _FaqSection {
  final String title;
  final IconData icon;
  final List<_FaqItem> items;

  const _FaqSection({
    required this.title,
    required this.icon,
    required this.items,
  });
}

const String _supportEmail = 'support@shayestehinc.com';

class HelpSupportScreen extends ConsumerStatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  ConsumerState<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends ConsumerState<HelpSupportScreen> {
  String _appVersion = '...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = '${info.version} (${info.buildNumber})';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _appVersion = 'Unknown');
      }
    }
  }

  static const List<_FaqSection> _commonSections = [
    _FaqSection(
      title: 'Getting Started',
      icon: Icons.rocket_launch_outlined,
      items: [
        _FaqItem(
          question: 'How do I set up my account?',
          answer:
              'Complete the onboarding wizard to set your profile, activity '
              'level, goals, and diet preferences. Your trainer will assign '
              'you a workout program.',
        ),
        _FaqItem(
          question: 'How do I change my profile?',
          answer:
              'Go to Settings > Edit Name or Body Measurements to update '
              'your information.',
        ),
      ],
    ),
    _FaqSection(
      title: 'Workouts',
      icon: Icons.fitness_center,
      items: [
        _FaqItem(
          question: 'How do I start a workout?',
          answer:
              "From the Home screen, tap on today's workout. The active "
              'workout screen will guide you through each exercise with '
              'sets, reps, and weights.',
        ),
        _FaqItem(
          question: 'Can I log missed workouts?',
          answer:
              'Your trainer can mark missed days and either skip them or '
              'push your program schedule forward.',
        ),
      ],
    ),
    _FaqSection(
      title: 'Nutrition',
      icon: Icons.restaurant_menu,
      items: [
        _FaqItem(
          question: 'How do I log food?',
          answer:
              "Go to the Nutrition tab and tap 'Add Food'. You can search "
              'for foods or use AI to parse natural language like '
              "'2 eggs and toast'.",
        ),
        _FaqItem(
          question: 'How are my macro goals set?',
          answer:
              'Your trainer sets your daily macro targets. They can also '
              'create presets for training days, rest days, etc.',
        ),
      ],
    ),
    _FaqSection(
      title: 'Account',
      icon: Icons.person_outline,
      items: [
        _FaqItem(
          question: 'How do I reset my password?',
          answer:
              "On the login screen, tap 'Forgot Password'. You'll receive "
              'an email with a reset link.',
        ),
        _FaqItem(
          question: 'How do I delete my account?',
          answer:
              'Go to Settings > Danger Zone > Delete Account. This action '
              'is permanent and cannot be undone.',
        ),
      ],
    ),
  ];

  static const _FaqSection _billingSection = _FaqSection(
    title: 'Billing',
    icon: Icons.payment,
    items: [
      _FaqItem(
        question: 'How do I set up payments?',
        answer:
            'Go to Settings > Payment Setup to connect your Stripe account. '
            'Then set your pricing in Settings > Set Your Prices.',
      ),
      _FaqItem(
        question: 'How do I create coupons?',
        answer:
            'Go to Settings > My Coupons to create discount codes for '
            'your trainees.',
      ),
    ],
  );

  List<_FaqSection> _sectionsForRole(String role) {
    final sections = List<_FaqSection>.from(_commonSections);
    if (role == 'TRAINER' || role == 'ADMIN') {
      sections.add(_billingSection);
    }
    return sections;
  }

  Future<void> _launchSupportEmail() async {
    final uri = Uri(scheme: 'mailto', path: _supportEmail);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Copy email to clipboard as fallback
      await Clipboard.setData(const ClipboardData(text: _supportEmail));
      if (mounted) {
        showAdaptiveToast(
          context,
          message: 'Could not open email app. Email copied to clipboard.',
          type: ToastType.info,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final role = authState.user?.role ?? 'TRAINEE';
    final sections = _sectionsForRole(role);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          for (final section in sections)
            _FaqSectionWidget(section: section),
          const SizedBox(height: 24),
          _ContactCard(onTap: _launchSupportEmail),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Version $_appVersion',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _FaqSectionWidget extends StatelessWidget {
  final _FaqSection section;

  const _FaqSectionWidget({required this.section});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 8),
            child: Row(
              children: [
                Icon(section.icon, size: 18, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  section.title,
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              children: [
                for (int i = 0; i < section.items.length; i++) ...[
                  _FaqExpansionTile(item: section.items[i]),
                  if (i < section.items.length - 1)
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: theme.dividerColor.withValues(alpha: 0.3),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqExpansionTile extends StatelessWidget {
  final _FaqItem item;

  const _FaqExpansionTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          item.question,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              item.answer,
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodySmall?.color,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ContactCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Semantics(
      button: true,
      label: 'Contact support via email at $_supportEmail',
      child: AdaptiveTappable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.email_outlined,
                color: primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Need more help?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Contact us at $_supportEmail',
              style: TextStyle(
                fontSize: 14,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

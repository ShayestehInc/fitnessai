import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ambassador/data/models/ambassador_models.dart';
import '../../../ambassador/presentation/providers/ambassador_provider.dart';

class AdminAmbassadorDetailScreen extends ConsumerStatefulWidget {
  final int ambassadorId;

  const AdminAmbassadorDetailScreen({super.key, required this.ambassadorId});

  @override
  ConsumerState<AdminAmbassadorDetailScreen> createState() =>
      _AdminAmbassadorDetailScreenState();
}

class _AdminAmbassadorDetailScreenState
    extends ConsumerState<AdminAmbassadorDetailScreen> {
  AmbassadorProfile? _profile;
  List<AmbassadorReferral> _referrals = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(ambassadorRepositoryProvider);
      final data = await repo.getAmbassadorDetail(widget.ambassadorId);

      setState(() {
        _profile = AmbassadorProfile.fromJson(data['profile'] as Map<String, dynamic>);
        _referrals = (data['referrals'] as List<dynamic>)
            .map((e) => AmbassadorReferral.fromJson(e as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _toggleActive() async {
    if (_profile == null) return;

    final newActive = !_profile!.isActive;
    final success = await ref.read(adminAmbassadorsProvider.notifier).updateAmbassador(
          _profile!.id,
          isActive: newActive,
        );

    if (success) {
      await _loadDetail();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newActive ? 'Ambassador activated' : 'Ambassador deactivated'),
            backgroundColor: newActive ? Colors.green : Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Ambassador Detail'),
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          if (_profile != null)
            IconButton(
              icon: Icon(
                _profile!.isActive ? Icons.pause_circle : Icons.play_circle,
                color: _profile!.isActive ? Colors.orange : Colors.green,
              ),
              tooltip: _profile!.isActive ? 'Deactivate' : 'Activate',
              onPressed: _toggleActive,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadDetail, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDetail,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileCard(theme),
                        const SizedBox(height: 16),
                        _buildStatsCard(theme),
                        const SizedBox(height: 24),
                        _buildReferralsList(theme),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildProfileCard(ThemeData theme) {
    final profile = _profile!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: profile.isActive
                ? Colors.teal.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            child: Icon(
              Icons.handshake,
              color: profile.isActive ? Colors.teal : Colors.grey,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.user.displayName,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  profile.user.email,
                  style: TextStyle(color: theme.textTheme.bodySmall?.color),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: profile.isActive
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        profile.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: profile.isActive ? Colors.green : Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Code: ${profile.referralCode}',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(ThemeData theme) {
    final profile = _profile!;
    return Row(
      children: [
        Expanded(
          child: _buildStatTile(theme, 'Referrals', profile.totalReferrals.toString(), Colors.blue),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatTile(theme, 'Earnings', '\$${profile.totalEarnings}', Colors.green),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatTile(
              theme, 'Rate', '${profile.commissionPercent.toStringAsFixed(0)}%', Colors.purple),
        ),
      ],
    );
  }

  Widget _buildStatTile(ThemeData theme, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildReferralsList(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Referrals (${_referrals.length})',
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (_referrals.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Center(
              child: Text(
                'No referrals yet',
                style: TextStyle(color: theme.textTheme.bodySmall?.color),
              ),
            ),
          )
        else
          ..._referrals.map((r) => _buildReferralTile(theme, r)),
      ],
    );
  }

  Widget _buildReferralTile(ThemeData theme, AmbassadorReferral referral) {
    final statusColor = switch (referral.status) {
      'ACTIVE' => Colors.green,
      'PENDING' => Colors.orange,
      'CHURNED' => Colors.red,
      _ => Colors.grey,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  referral.trainer.displayName,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${referral.trainerSubscriptionTier} tier',
                  style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '\$${referral.totalCommissionEarned}',
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              referral.status,
              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

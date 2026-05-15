import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/core/theme/app_design_constants.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/providers/auth/auth_provider.dart';
import 'package:sheryan/providers/points/points_provider.dart';
import 'package:sheryan/screens/sponsor/manage_reward_screen.dart';
import 'package:sheryan/screens/sponsor/scan_redeem_screen.dart';

import 'package:sheryan/widgets/notification_badge.dart';
import 'package:sheryan/screens/settings/userside_settings_screen.dart';

class SponsorDashboard extends ConsumerWidget {
  const SponsorDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final profile = ref.watch(userProfileProvider).asData?.value ?? {};
    final orgName = profile['name'] as String? ?? l10n.sponsorDashboard;

    final rewardsAsync = ref.watch(sponsorRewardsProvider(uid));
    final redemptionsAsync = ref.watch(sponsorRedemptionsCountProvider(uid));
    final activeCount = rewardsAsync.asData?.value
            .where((r) => r['isActive'] == true)
            .length ??
        0;
    final totalRedeemed = redemptionsAsync.asData?.value ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sponsorDashboard),
        actions: [
          if (uid.isNotEmpty) NotificationBadge(userId: uid),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(sponsorRewardsProvider(uid)),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppDesignConstants.edgeInsetsMedium,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, orgName, activeCount, totalRedeemed,
                  l10n, theme),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.myRewards,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ManageRewardScreen()),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(l10n.addReward),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              rewardsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(e.toString())),
                data: (rewards) {
                  if (rewards.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(Icons.card_giftcard_outlined,
                                size: 60,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.3)),
                            const SizedBox(height: 12),
                            Text(l10n.noRewardsAdded,
                                style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: rewards
                        .map((r) =>
                            _buildRewardTile(context, r, uid, l10n, theme))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String orgName,
    int activeCount,
    int totalRedeemed,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.store, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  orgName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _statBox(
                    l10n.activeRewards, '$activeCount', Icons.check_circle_outline),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statBox(
                    l10n.totalRedeemed, '$totalRedeemed', Icons.redeem),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRewardTile(
    BuildContext context,
    Map<String, dynamic> reward,
    String uid,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final isActive = reward['isActive'] as bool? ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.success.withOpacity(0.12)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isActive ? l10n.activeRewards : '—',
                    style: TextStyle(
                        fontSize: 10,
                        color: isActive
                            ? AppColors.success
                            : theme.colorScheme.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reward['title'] as String? ?? '',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${reward['pointsRequired']} ⭐',
                  style: const TextStyle(
                      color: AppColors.primaryRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              reward['description'] as String? ?? '',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
            Text(
              '📍 ${reward['city'] ?? ''} • 📞 ${reward['sponsorPhone'] ?? ''}',
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              ScanRedeemScreen(reward: reward)),
                    ),
                    icon: const Icon(Icons.qr_code_scanner, size: 16),
                    label: Text(l10n.scanDonorQrRedeem,
                        style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryRed,
                      side:
                          BorderSide(color: AppColors.primaryRed.withOpacity(0.5)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: Colors.blue, size: 20),
                  tooltip: l10n.editReward,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ManageRewardScreen(existingReward: reward)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.error, size: 20),
                  tooltip: l10n.deleteReward,
                  onPressed: () =>
                      _confirmDelete(context, reward, l10n),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> reward,
      AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteReward),
        content: Text(l10n.confirmDeleteReward),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () async {
              final id = reward['id'] as String?;
              if (id != null) {
                await FirebaseFirestore.instance
                    .collection('rewards')
                    .doc(id)
                    .delete();
              }
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.rewardDeleted)));
              }
            },
            child: Text(l10n.yesDelete),
          ),
        ],
      ),
    );
  }
}

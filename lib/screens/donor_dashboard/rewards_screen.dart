import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/core/theme/app_design_constants.dart';
import 'package:sheryan/core/utils/qr_dialog.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/providers/auth/auth_provider.dart';
import 'package:sheryan/providers/points/points_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  String _selectedCity = '';

  @override
  void initState() {
    super.initState();
    ref.listenManual(userProfileProvider, (_, next) {
      final city = next.asData?.value?['city'] as String?;
      if (city != null && _selectedCity.isEmpty) {
        setState(() => _selectedCity = city);
      }
    }, fireImmediately: true);
  }

  String _tierLabel(String tier, AppLocalizations l10n) {
    switch (tier) {
      case 'silver':
        return l10n.tierSilver;
      case 'gold':
        return l10n.tierGold;
      case 'platinum':
        return l10n.tierPlatinum;
      default:
        return l10n.tierBronze;
    }
  }

  Color _tierColor(String tier) {
    switch (tier) {
      case 'silver':
        return Colors.grey.shade400;
      case 'gold':
        return Colors.amber;
      case 'platinum':
        return Colors.deepPurple;
      default:
        return Colors.brown;
    }
  }

  IconData _tierIcon(String tier) {
    switch (tier) {
      case 'silver':
        return Icons.military_tech;
      case 'gold':
        return Icons.emoji_events;
      case 'platinum':
        return Icons.diamond;
      default:
        return Icons.shield;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final userName =
        ref.watch(userProfileProvider).asData?.value?['name'] as String? ?? '';

    final pointsData = ref.watch(pointsProvider).asData?.value ??
        {'points': 0, 'tier': 'bronze'};
    final points = pointsData['points'] as int;
    final tier = pointsData['tier'] as String;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
      appBar: AppBar(
        title: Text(l10n.myPoints),
        bottom: TabBar(
          indicatorColor: AppColors.primaryRed,
          tabs: [
            Tab(text: l10n.availableRewards, icon: const Icon(Icons.card_giftcard)),
            Tab(text: l10n.pointsHistory, icon: const Icon(Icons.history)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildPointsHeader(context, points, tier, uid, userName, l10n, theme),
          Expanded(
            child: TabBarView(
              children: [
                _buildRewardsTab(context, points, l10n, theme),
                _buildHistoryTab(context, l10n, theme),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildPointsHeader(
    BuildContext context,
    int points,
    String tier,
    String uid,
    String userName,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final tierColor = _tierColor(tier);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryRed, AppColors.accentRed],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_tierIcon(tier), color: tierColor, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$points ${l10n.pointsBalance}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: tierColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: tierColor.withOpacity(0.6), width: 1),
                          ),
                          child: Text(
                            '${l10n.donorTier}: ${_tierLabel(tier, l10n)}',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => QrDialog.show(
                  context,
                  data: uid,
                  label: userName,
                  idLabel: l10n.donorId,
                ),
                icon: const Icon(Icons.qr_code, color: Colors.white, size: 16),
                label: Text(l10n.showMyQr,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTierProgress(points, tier, l10n, theme),
        ],
      ),
    );
  }

  Widget _buildTierProgress(
      int points, String tier, AppLocalizations l10n, ThemeData theme) {
    int nextMilestone;
    String nextTier;
    if (points < 500) {
      nextMilestone = 500;
      nextTier = l10n.tierSilver;
    } else if (points < 1000) {
      nextMilestone = 1000;
      nextTier = l10n.tierGold;
    } else if (points < 2000) {
      nextMilestone = 2000;
      nextTier = l10n.tierPlatinum;
    } else {
      return Text(
        '🏆 ${l10n.tierPlatinum}',
        style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600),
      );
    }

    final prevMilestone = points < 500
        ? 0
        : points < 1000
            ? 500
            : 1000;
    final progress =
        (points - prevMilestone) / (nextMilestone - prevMilestone);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${nextMilestone - points} ${l10n.pointsBalance} → $nextTier',
              style:
                  const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            Text(
              '$nextMilestone',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.white.withOpacity(0.25),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildRewardsTab(
      BuildContext context, int points, AppLocalizations l10n, ThemeData theme) {
    final rewardsAsync = ref.watch(cityRewardsProvider(_selectedCity));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.filter_list,
                  size: 18, color: AppColors.primaryRed),
              const SizedBox(width: 8),
              Text(l10n.filterByCity,
                  style: theme.textTheme.labelLarge),
              const SizedBox(width: 8),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('cities')
                      .orderBy('name')
                      .snapshots(),
                  builder: (ctx, snap) {
                    final cities = snap.data?.docs ?? [];
                    return DropdownButton<String>(
                      value: _selectedCity.isEmpty ? null : _selectedCity,
                      isExpanded: true,
                      hint: Text(l10n.allCities),
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem(
                            value: '',
                            child: Text(l10n.allCities)),
                        ...cities.map((c) => DropdownMenuItem(
                            value: c['name'] as String,
                            child: Text(c['name'] as String))),
                      ],
                      onChanged: (v) =>
                          setState(() => _selectedCity = v ?? ''),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: rewardsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (rewards) {
              if (rewards.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.card_giftcard_outlined,
                          size: 60,
                          color: theme.colorScheme.onSurface
                              .withOpacity(0.3)),
                      const SizedBox(height: 12),
                      Text(l10n.noRewardsFound,
                          style: theme.textTheme.bodyMedium),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: AppDesignConstants.edgeInsetsMedium,
                itemCount: rewards.length,
                itemBuilder: (ctx, i) =>
                    _buildRewardCard(context, rewards[i], points, l10n, theme),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRewardCard(
    BuildContext context,
    Map<String, dynamic> reward,
    int points,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final required = (reward['pointsRequired'] as int?) ?? 0;
    final canRedeem = points >= required;
    final phone = reward['sponsorPhone'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.card_giftcard,
                      color: AppColors.primaryRed, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reward['title'] as String? ?? '',
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        reward['description'] as String? ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.6)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: canRedeem
                        ? AppColors.success.withOpacity(0.12)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: canRedeem
                          ? AppColors.success.withOpacity(0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    '$required ⭐',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: canRedeem
                          ? AppColors.success
                          : theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            _infoRow(Icons.store_outlined,
                reward['sponsorName'] as String? ?? '', theme),
            _infoRow(Icons.location_on_outlined,
                reward['sponsorAddress'] as String? ?? '', theme),
            if (phone.isNotEmpty)
              GestureDetector(
                onTap: () => launchUrl(Uri(scheme: 'tel', path: phone)),
                child: _infoRow(
                    Icons.phone_outlined, phone, theme,
                    color: AppColors.primaryRed),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: canRedeem
                        ? () => _confirmRedeem(context, reward, l10n)
                        : null,
                    icon: const Icon(Icons.redeem, size: 18),
                    label: Text(canRedeem
                        ? l10n.redeemReward
                        : l10n.notEnoughPoints),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          canRedeem ? AppColors.primaryRed : null,
                      foregroundColor:
                          canRedeem ? Colors.white : null,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, ThemeData theme,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon,
              size: 14,
              color: color ?? theme.colorScheme.onSurface.withOpacity(0.5)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  fontSize: 12,
                  color:
                      color ?? theme.colorScheme.onSurface.withOpacity(0.7)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRedeem(BuildContext context, Map<String, dynamic> reward,
      AppLocalizations l10n) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.redeemReward),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reward['title'] as String? ?? ''),
            const SizedBox(height: 8),
            Text('${reward['pointsRequired']} ⭐',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryRed)),
            const SizedBox(height: 12),
            Text(l10n.showMyQr,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              QrDialog.show(
                context,
                data: uid,
                label: reward['title'] as String? ?? '',
                idLabel: l10n.donorId,
              );
            },
            child: Text(l10n.showMyQr),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(
      BuildContext context, AppLocalizations l10n, ThemeData theme) {
    final historyAsync = ref.watch(pointsHistoryProvider);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (history) {
        if (history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history,
                    size: 60,
                    color: theme.colorScheme.onSurface.withOpacity(0.3)),
                const SizedBox(height: 12),
                Text(l10n.noPointsYet,
                    style: theme.textTheme.bodyMedium),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: AppDesignConstants.edgeInsetsMedium,
          itemCount: history.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (ctx, i) {
            final item = history[i];
            final pts = (item['points'] as int?) ?? 0;
            final desc = isAr
                ? item['descriptionAr'] as String? ?? ''
                : item['descriptionEn'] as String? ?? '';
            final createdAt = item['createdAt'];
            String timeStr = '';
            if (createdAt is Timestamp) {
              final dt = createdAt.toDate();
              timeStr =
                  '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
            }
            return ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_circle_outline,
                    color: AppColors.success, size: 20),
              ),
              title: Text(desc, style: theme.textTheme.bodyMedium),
              subtitle: Text(timeStr,
                  style: theme.textTheme.labelSmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withOpacity(0.5))),
              trailing: Text(
                '+$pts ⭐',
                style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            );
          },
        );
      },
    );
  }
}

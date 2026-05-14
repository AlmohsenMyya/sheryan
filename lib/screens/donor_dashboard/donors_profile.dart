import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/core/theme/app_design_constants.dart';
import 'package:sheryan/core/utils/profile_completion.dart';
import 'package:sheryan/core/utils/qr_dialog.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/providers/auth/auth_provider.dart';
import 'package:sheryan/providers/points/points_provider.dart';
import 'package:sheryan/screens/donor_dashboard/blood_compatibility_screen.dart';
import 'package:sheryan/screens/donor_dashboard/donation_history_screen.dart';
import 'package:sheryan/screens/donor_dashboard/profile_sections/basic_info_screen.dart';
import 'package:sheryan/screens/donor_dashboard/profile_sections/emergency_contact_screen.dart';
import 'package:sheryan/screens/donor_dashboard/profile_sections/health_info_screen.dart';
import 'package:sheryan/screens/donor_dashboard/profile_sections/medical_history_screen.dart';
import 'package:sheryan/screens/donor_dashboard/rewards_screen.dart';

class DonorProfileScreen extends ConsumerWidget {
  const DonorProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final profileAsync = ref.watch(userProfileProvider);
    final pointsData = ref.watch(pointsProvider).asData?.value ??
        {'points': 0, 'tier': 'bronze'};
    final points = pointsData['points'] as int;
    final tier = pointsData['tier'] as String;

    if (profileAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final data = profileAsync.asData?.value ?? {};

    if (data.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.myProfile)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final completion = ProfileCompletion.calculate(data);
    final sections = ProfileCompletion.getSections(data);
    final isVerified = ProfileCompletion.bloodVerified(data);
    final name = data['name'] as String? ?? l10n.bloodDonor;
    final bloodGroup = data['bloodGroup'] as String? ?? l10n.notAvailable;
    final city = data['city'] as String? ?? l10n.unknownCity;

    Future<void> navigateToSection(Widget screen) async {
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => screen),
      );
      ref.invalidate(userProfileProvider);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myProfile),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(userProfileProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(userProfileProvider),
        color: AppColors.primaryRed,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfileHeader(
                  context, name, bloodGroup, city, isVerified, completion, l10n, theme),

              // ── Points / Tier quick card ──────────────────────────────
              _buildPointsCard(context, points, tier, l10n, theme),

              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.profileSections,
                  style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5)),
                ),
              ),
              const SizedBox(height: 8),

              ...sections.asMap().entries.map((entry) {
                final i = entry.key;
                final s = entry.value;
                final title = isAr ? s.titleAr : s.titleEn;
                final subtitle = isAr ? s.subtitleAr : s.subtitleEn;
                return _buildSectionCard(
                  context: context,
                  index: i,
                  title: title,
                  subtitle: subtitle,
                  weight: s.weight,
                  isComplete: s.isComplete,
                  requiresHospital: s.requiresHospital,
                  l10n: l10n,
                  theme: theme,
                  onTap: s.requiresHospital
                      ? null
                      : () => navigateToSection(_screenForIndex(i, data)),
                );
              }),

              const SizedBox(height: 16),
              _buildRewardsCard(context, l10n, theme),
              const SizedBox(height: 5),
              _buildDonationHistoryCard(context, l10n, theme),
              const SizedBox(height: 5),
              _buildCompatibilityCard(context, bloodGroup, l10n, theme),
              const SizedBox(height: 4),

              Padding(
                padding: AppDesignConstants.edgeInsetsMedium,
                child: OutlinedButton.icon(
                  onPressed: () => QrDialog.show(
                    context,
                    data: uid,
                    label: name,
                    idLabel: l10n.donorId,
                  ),
                  icon: const Icon(Icons.qr_code),
                  label: Text(l10n.donorCard),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.primary),
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointsCard(
    BuildContext context,
    int points,
    String tier,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    Color tierColor;
    IconData tierIcon;
    String tierLabel;
    switch (tier) {
      case 'silver':
        tierColor = Colors.grey.shade400;
        tierIcon = Icons.military_tech;
        tierLabel = l10n.tierSilver;
        break;
      case 'gold':
        tierColor = Colors.amber;
        tierIcon = Icons.emoji_events;
        tierLabel = l10n.tierGold;
        break;
      case 'platinum':
        tierColor = Colors.deepPurple;
        tierIcon = Icons.diamond;
        tierLabel = l10n.tierPlatinum;
        break;
      default:
        tierColor = Colors.brown;
        tierIcon = Icons.shield;
        tierLabel = l10n.tierBronze;
    }

    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const RewardsScreen())),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.primaryRed.withOpacity(0.25), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.stars_rounded,
                  color: AppColors.primaryRed, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.myPoints, style: theme.textTheme.titleSmall),
                  Text(
                    '$points ⭐ • $tierLabel',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
            Icon(tierIcon, color: tierColor, size: 26),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
                size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    String name,
    String bloodGroup,
    String city,
    bool isVerified,
    int completion,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(bloodGroup,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                          if (isVerified) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.verified,
                                      color: Colors.white, size: 12),
                                  const SizedBox(width: 3),
                                  Text(l10n.verified,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(city,
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.profileCompletion,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                Text('$completion%',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: completion / 100,
                backgroundColor: Colors.white.withOpacity(0.25),
                valueColor: AlwaysStoppedAnimation<Color>(
                  completion >= 80
                      ? Colors.greenAccent
                      : completion >= 50
                          ? Colors.yellowAccent
                          : Colors.white,
                ),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _completionMessage(completion, l10n),
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  String _completionMessage(int pct, AppLocalizations l10n) {
    if (pct == 100) return l10n.completionFull;
    if (pct >= 65) return l10n.completionGood;
    if (pct >= 35) return l10n.completionPartial;
    return l10n.completionLow;
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required int index,
    required String title,
    required String subtitle,
    required int weight,
    required bool isComplete,
    required bool requiresHospital,
    required AppLocalizations l10n,
    required ThemeData theme,
    VoidCallback? onTap,
  }) {
    final iconData = _iconForIndex(index);
    final Color statusColor =
        isComplete ? AppColors.success : theme.colorScheme.onSurface.withOpacity(0.5);
    final Color borderColor =
        isComplete ? AppColors.success.withOpacity(0.4) : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isComplete
                      ? AppColors.success.withOpacity(0.12)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(iconData, color: statusColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: isComplete
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withOpacity(0.7),
                        )),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5))),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isComplete
                          ? AppColors.success.withOpacity(0.12)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+$weight%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isComplete
                            ? AppColors.success
                            : theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isComplete)
                    const Icon(Icons.check_circle, color: AppColors.success, size: 18)
                  else if (requiresHospital)
                    const Icon(Icons.local_hospital_outlined,
                        color: Colors.blue, size: 18)
                  else
                    Icon(Icons.chevron_right,
                        color: theme.colorScheme.onSurface.withOpacity(0.5), size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardsCard(
      BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RewardsScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.withOpacity(0.18),
              Colors.orange.withOpacity(0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.amber.withOpacity(0.4), width: 1.2),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.card_giftcard,
                    color: Colors.amber, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.availableRewards,
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(l10n.rewardsTab,
                        style: theme.textTheme.labelSmall?.copyWith(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.5))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.amber, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompatibilityCard(
      BuildContext context, String bloodGroup, AppLocalizations l10n, ThemeData theme) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BloodCompatibilityScreen(donorBloodGroup: bloodGroup),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.deepPurple.withOpacity(0.18),
              Colors.deepPurple.withOpacity(0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: Colors.deepPurple.withOpacity(0.3), width: 1.2),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.bloodtype_outlined,
                    color: Colors.deepPurple, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.bloodCompatibilityTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(l10n.viewCompatibilityGuide,
                        style: theme.textTheme.labelSmall?.copyWith(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.5))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: Colors.deepPurple, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDonationHistoryCard(
      BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DonationHistoryScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryRed.withOpacity(0.18),
              AppColors.accentRed.withOpacity(0.10),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.primaryRed.withOpacity(0.3), width: 1.2),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.favorite,
                    color: AppColors.primaryRed, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.donationHistory,
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(l10n.viewDonationHistory,
                        style: theme.textTheme.labelSmall?.copyWith(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.5))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.primaryRed, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForIndex(int i) {
    switch (i) {
      case 0:
        return Icons.person_outline;
      case 1:
        return Icons.monitor_weight_outlined;
      case 2:
        return Icons.medical_services_outlined;
      case 3:
        return Icons.contact_phone_outlined;
      case 4:
        return Icons.verified_user_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Widget _screenForIndex(int index, Map<String, dynamic> data) {
    switch (index) {
      case 0:
        return BasicInfoScreen(existingData: data);
      case 1:
        return HealthInfoScreen(existingData: data);
      case 2:
        return MedicalHistoryScreen(existingData: data);
      case 3:
        return EmergencyContactScreen(existingData: data);
      default:
        return const SizedBox.shrink();
    }
  }
}

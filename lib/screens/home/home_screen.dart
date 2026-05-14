import 'package:sheryan/providers/connectivity/connectivity_provider.dart';
import 'package:sheryan/services/pending_actions_service.dart';
import 'package:sheryan/widgets/offline_banner.dart';
import 'package:sheryan/screens/misc/notifications_screen.dart';
import 'package:sheryan/services/notification_service.dart';
import 'package:sheryan/providers/theme/theme_provider.dart';
import 'package:sheryan/screens/admin/admin_dashboard.dart';
import 'package:sheryan/screens/hospital/hospital_dashboard.dart';
import 'package:sheryan/screens/sponsor/sponsor_dashboard.dart';
import 'package:sheryan/core/enums/user_role.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/core/theme/app_design_constants.dart';
import 'package:sheryan/screens/donor_dashboard/donor_settings.dart';
import 'package:sheryan/screens/donor_dashboard/donors_list.dart';
import 'package:sheryan/screens/donor_dashboard/donors_profile.dart';
import 'package:sheryan/screens/donor_dashboard/nearby_users_req.dart';
import 'package:sheryan/screens/donor_dashboard/see_users_request.dart';
import 'package:sheryan/screens/donors/donors_list_screen.dart';
import 'package:sheryan/screens/donors/nearby_donors_screen.dart';
import 'package:sheryan/screens/misc/awareness_screen.dart';
import 'package:sheryan/screens/profile/user_profile_screen.dart';
import 'package:sheryan/screens/requests/create_request_screen.dart';
import 'package:sheryan/screens/requests/requests_list_screen.dart';
import 'package:sheryan/screens/settings/userside_settings_screen.dart';
import 'package:sheryan/services/auth_service.dart';
import 'package:sheryan/providers/auth/auth_provider.dart';
import 'package:sheryan/providers/locale/locale_provider.dart';
import 'package:sheryan/screens/auth/sign_in_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // userData is populated reactively from userProfileProvider in build().
  // It is kept as a field so helper methods (_greeting, _statCard, etc.) can
  // read it without requiring explicit parameters.
  Map<String, dynamic>? userData;

  int _selectedTab = 0;
  String _currentQuote = '';
  bool _notificationsInitialized = false;

  @override
  void initState() {
    super.initState();
    _listenForReconnect();
  }

  // ─── Connectivity helpers ─────────────────────────────────────────────────

  void _listenForReconnect() {
    ref.listenManual(connectivityProvider, (prev, next) {
      if (prev == false && next == true) {
        _syncPendingRequests();
      }
    });
  }

  Future<void> _syncPendingRequests() async {
    final count = await PendingActionsService().getPendingCount();
    if (count == 0 || !mounted) return;
    final synced = await PendingActionsService().syncPendingRequests();
    if (synced > 0 && mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pendingRequestsSynced),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
  }

  // ─── Auth ─────────────────────────────────────────────────────────────────

  Future<void> _signOutAndGoLogin() async {
    try {
      await NotificationService().logout();
      await ref.read(authServiceProvider).logoutUser();
    } catch (_) {
      await AuthService().logoutUser();
    }
    ref.read(roleProvider.notifier).clearRole();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // ─── Language sheet ───────────────────────────────────────────────────────

  Future<void> _showLanguageSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final currentCode = ref.read(localeProvider)?.languageCode;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDesignConstants.radiusExtraLarge),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(l10n.changeLanguage, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ListTile(
                leading: const Text('🇺🇸', style: TextStyle(fontSize: 20)),
                title: Text(l10n.languageEnglish, style: Theme.of(context).textTheme.bodyLarge),
                trailing: currentCode == 'en'
                    ? const Icon(Icons.check, color: AppColors.primaryRed)
                    : null,
                onTap: () async {
                  await ref.read(localeProvider.notifier).setLocale(const Locale('en'));
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Text('🇸🇦', style: TextStyle(fontSize: 20)),
                title: Text(l10n.languageArabic, style: Theme.of(context).textTheme.bodyLarge),
                trailing: currentCode == 'ar'
                    ? const Icon(Icons.check, color: AppColors.primaryRed)
                    : null,
                onTap: () async {
                  await ref.read(localeProvider.notifier).setLocale(const Locale('ar'));
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ─── UI helpers ───────────────────────────────────────────────────────────

  Widget _topAppBar(UserRole role) {
    final l10n = AppLocalizations.of(context)!;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    String title = l10n.appTitle;
    if (role == UserRole.donor) title = l10n.donorDashboard;
    if (role == UserRole.hospitalAdmin) title = l10n.hospitalAdminDashboard;

    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return AppBar(
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          Image.asset('assets/logo.png', height: 32),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 22),
          onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
        ),
        if (userId != null)
          StreamBuilder<int>(
            stream: NotificationService().getUnreadCountStream(userId),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, size: 22),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppColors.bloodRed,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Theme.of(context).colorScheme.surface, width: 1.5),
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        IconButton(
          tooltip: l10n.changeLanguage,
          icon: const Icon(Icons.translate_outlined, size: 22),
          onPressed: _showLanguageSheet,
        ),
        PopupMenuButton<String>(
          offset: const Offset(0, 45),
          shape: RoundedRectangleBorder(borderRadius: AppDesignConstants.borderRadiusMedium),
          icon: const Icon(Icons.more_vert_outlined, size: 22),
          onSelected: (v) {
            if (v == 'settings') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => role == UserRole.donor
                      ? const DonorSettingsScreen()
                      : const SettingsScreen(),
                ),
              );
            } else if (v == 'logout') {
              _signOutAndGoLogin();
            }
          },
          itemBuilder: (ctx) => [
            if (role != UserRole.hospitalAdmin)
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    const Icon(Icons.settings_outlined, size: 20),
                    const SizedBox(width: 12),
                    Text(l10n.settings),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  const Icon(Icons.logout_outlined, color: AppColors.bloodRed, size: 20),
                  const SizedBox(width: 12),
                  Text(l10n.logout, style: const TextStyle(color: AppColors.bloodRed)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildHeader(UserRole role) {
    final l10n = AppLocalizations.of(context)!;
    final name = userData?['name'] as String? ?? l10n.friend;
    final bloodGroup = userData?['bloodGroup'] as String? ?? '-';
    final city = userData?['city'] as String? ?? '-';
    
    final hour = DateTime.now().hour;
    final greetingPrefix = hour < 12
        ? l10n.goodMorning
        : hour < 18
            ? l10n.goodAfternoon
            : l10n.goodEvening;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppDesignConstants.borderRadiusLarge,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greetingPrefix,',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      city,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

      Row(
            children: [

              _headerStatItem(l10n.bloodGroup, bloodGroup, Icons.bloodtype_outlined),
              const SizedBox(width: 20),
              _headerStatItem(
                role == UserRole.donor ? l10n.myPoints : l10n.myRequests,
                role == UserRole.donor ? '${userData?['points'] ?? 0}' : '${userData?['requestCount'] ?? 0}',
                role == UserRole.donor ? Icons.stars_outlined : Icons.favorite_border,
              ),
              Spacer(),
              Center(
                child: Image.asset(
                  'assets/logo.png',
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),

            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStatItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: AppDesignConstants.borderRadiusMedium,
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationalBanner() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bloodRedLight.withOpacity(0.3),
        borderRadius: AppDesignConstants.borderRadiusMedium,
        border: Border.all(color: AppColors.bloodRed.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.format_quote, color: AppColors.bloodRed, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.motivationTitle,
                  style: const TextStyle(
                    color: AppColors.bloodRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentQuote,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(UserRole role) {
    final l10n = AppLocalizations.of(context)!;
    Future<void> onRefresh() async => ref.invalidate(userProfileProvider);

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: Theme.of(context).colorScheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(role),
            const SizedBox(height: 24),
            
            if (role == UserRole.donor) ...[
              _buildSectionHeader(l10n.quickActions),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _buildActionCard(
                    title: l10n.usersBloodRequests,
                    subtitle: l10n.viewAllRequestsFromUsersAcross,
                    icon: Icons.bloodtype_rounded,
                    color: AppColors.bloodRed,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UsersRequestsScreen()),
                    ),
                  ),
                  _buildActionCard(
                    title: l10n.nearbyRequests,
                    subtitle: l10n.checkNearbyBloodRequests,
                    icon: Icons.near_me_outlined,
                    color: AppColors.medicalBlue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NearbyRequestsScreen()),
                    ),
                  ),
                  _buildActionCard(
                    title: l10n.allDonorsTab,
                    subtitle: l10n.viewAllDonors,
                    icon: Icons.people_outline,
                    color: Colors.orange,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DonorsList()),
                    ),
                  ),
                  _buildActionCard(
                    title: l10n.awareness,
                    subtitle: l10n.awarenessDonorSubtitle,
                    icon: Icons.tips_and_updates_outlined,
                    color: Colors.teal,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TipsScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildMotivationalBanner(),
            ] else ...[
              // Recipient body
              _buildSectionHeader(l10n.needHelp),
              _buildLongActionCard(
                title: l10n.requestBlood,
                subtitle: l10n.createNewBloodRequest,
                icon: Icons.bloodtype,
                color: AppColors.bloodRed,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RequestBloodScreen()),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      title: l10n.myRequests,
                      subtitle: l10n.trackPreviousRequests,
                      icon: Icons.favorite_outline,
                      color: AppColors.medicalBlue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RequestsListScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      title: l10n.nearbyDonors,
                      subtitle: l10n.trackNearbyDonors,
                      icon: Icons.near_me,
                      color: Colors.orange,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NearbyDonorsScreen()),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(l10n.community),
              _buildLongActionCard(
                title: l10n.awareness,
                subtitle: l10n.awarenessUserSubtitle,
                icon: Icons.tips_and_updates_outlined,
                color: Colors.teal,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TipsScreen()),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLongActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: AppDesignConstants.borderRadiusMedium,
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3), size: 16),
          ],
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // ── 1. Watch the stream provider (single source of truth for user data) ──
    final profileAsync = ref.watch(userProfileProvider);

    // ── 2. Show loading spinner while the first snapshot hasn't arrived ──────
    //    This handles both app-start and hot-restart.
    if (profileAsync.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ── 3. Extract data (stream error treated same as null → loading) ─────────
    final profile = profileAsync.asData?.value;
    if (profile == null) {
      // Could be:
      //  • Stream errored (Firestore rules / network issues on web)
      //  • User document doesn't exist yet (race during sign-up)
      // Either way, show a spinner — the stream will retry automatically once
      // connectivity is restored or the document is created.
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ── 4. Sync profile into the local field used by widget helper methods ───
    userData = profile;

    // ── 5. One-time side effects (notifications, quotes) ─────────────────────
    if (!_notificationsInitialized) {
      _notificationsInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        NotificationService().init(context);
        final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        NotificationService().sendUserTags(
          uid: uid,
          city: profile['city'] as String? ?? 'unknown',
          bloodGroup: profile['bloodGroup'] as String? ?? 'unknown',
          role: profile['role'] as String? ?? 'user',
        );
      });
    }

    if (_currentQuote.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      final quotes = [
        l10n.quote1, l10n.quote2, l10n.quote3, l10n.quote4,
        l10n.quote5, l10n.quote6, l10n.quote7,
      ];
      _currentQuote = (List.from(quotes)..shuffle()).first;
    }

    // ── 6. Derive role directly from Firestore data ──────────────────────────
    //    No dependency on roleProvider for routing — avoids all race conditions.
    final roleStr = profile['role'] as String?;
    final UserRole role;
    if (roleStr == 'hospitalAdmin') {
      role = UserRole.hospitalAdmin;
    } else if (roleStr == 'superAdmin') {
      role = UserRole.superAdmin;
    } else if (roleStr == 'sponsorOrg') {
      role = UserRole.sponsorOrg;
    } else if (roleStr == 'donor') {
      role = UserRole.donor;
    } else {
      role = UserRole.recipient;
    }

    // Keep roleProvider in sync for any child widgets that still read it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(roleProvider.notifier).setRoleFromString(roleStr);
    });

    // ── 7. Route to the appropriate dashboard ────────────────────────────────
    final l10n = AppLocalizations.of(context)!;
print("83735672 $role");
    if (role == UserRole.hospitalAdmin) {
      return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _topAppBar(role),
        ),
        body: Column(
          children: const [
            OfflineBanner(),
            Expanded(child: HospitalDashboard()),
          ],
        ),
      );
    }

    if (role == UserRole.superAdmin) {
      return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _topAppBar(role),
        ),
        body: Column(
          children: const [
            OfflineBanner(),
            Expanded(child: AdminDashboard()),
          ],
        ),
      );
    }

    if (role == UserRole.sponsorOrg) {
      return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _topAppBar(role),
        ),
        body: Column(
          children: const [
            OfflineBanner(),
            Expanded(child: SponsorDashboard()),
          ],
        ),
      );
    }

    // Donor / Recipient
    final List<Widget> tabs = [
      _buildBody(role),
      if (role == UserRole.recipient) const DonorListScreen(),
      if (role == UserRole.recipient) const ProfileScreen(),
      if (role == UserRole.donor) const DonorsList(),
      if (role == UserRole.donor) const DonorProfileScreen(),
    ];

    final List<BottomNavigationBarItem> items = [
      BottomNavigationBarItem(icon: const Icon(Icons.home), label: l10n.homeTab),
      if (role == UserRole.recipient)
        BottomNavigationBarItem(icon: const Icon(Icons.people), label: l10n.donorsTab),
      if (role == UserRole.recipient)
        BottomNavigationBarItem(icon: const Icon(Icons.person), label: l10n.profileTab),
      if (role == UserRole.donor)
        BottomNavigationBarItem(icon: const Icon(Icons.person_3), label: l10n.allDonorsTab),
      if (role == UserRole.donor)
        BottomNavigationBarItem(icon: const Icon(Icons.person_3), label: l10n.profileTab),
    ];

    // Clamp _selectedTab in case the tab list shrank (e.g. role change)
    final safeTab = _selectedTab.clamp(0, tabs.length - 1);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: _topAppBar(role),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: tabs[safeTab]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeTab,
        onTap: (i) => setState(() => _selectedTab = i),
        items: items,
      ),
    );
  }
}

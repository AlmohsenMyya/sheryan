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
      title: Row(
        children: [
          Image.asset('assets/logo.png', height: 28),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
        ),
        if (userId != null)
          StreamBuilder<int>(
            stream: NotificationService().getUnreadCountStream(userId),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
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
          icon: const Icon(Icons.language),
          onPressed: _showLanguageSheet,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.settings),
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
                    const Icon(Icons.settings, color: Colors.black54),
                    const SizedBox(width: 8),
                    Text(l10n.settings),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  const Icon(Icons.logout, color: Colors.black54),
                  const SizedBox(width: 8),
                  Text(l10n.logout),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String title, String value) {
    return Container(
      padding: AppDesignConstants.edgeInsetsMedium,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppDesignConstants.borderRadiusMedium,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primaryRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _greeting() {
    final l10n = AppLocalizations.of(context)!;
    final name = userData?['name'] as String? ?? l10n.friend;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? l10n.goodMorning
        : hour < 18
            ? l10n.goodAfternoon
            : l10n.goodEvening;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$greeting,', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(
          name,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 22),
        ),
      ],
    );
  }

  Widget _buildMotivationalCard(String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildCard(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            icon,
            color: icon == Icons.bloodtype || icon == Icons.bloodtype_rounded
                ? AppColors.bloodRed
                : Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.textGrey, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildBody(UserRole role) {
    final l10n = AppLocalizations.of(context)!;

    // Refresh by invalidating the stream provider — it will re-subscribe and
    // return the latest Firestore data (online) or cached data (offline).
    Future<void> onRefresh() async => ref.invalidate(userProfileProvider);

    if (role == UserRole.donor) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppDesignConstants.edgeInsetsMedium,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _greeting(),
              const SizedBox(height: 10),
              _buildMotivationalCard(l10n.motivationTitle, _currentQuote),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _statCard(l10n.bloodGroup, userData?['bloodGroup'] as String? ?? '-')),
                  const SizedBox(width: 12),
                  Expanded(child: _statCard(l10n.city, userData?['city'] as String? ?? '-')),
                ],
              ),
              const SizedBox(height: 18),
              Card(
                child: InkWell(
                  borderRadius: AppDesignConstants.borderRadiusMedium,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UsersRequestsScreen()),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.bloodtype_rounded, color: AppColors.primaryRed),
                    title: Text(l10n.usersBloodRequests, style: Theme.of(context).textTheme.bodyLarge),
                    subtitle: Text(l10n.viewAllRequestsFromUsersAcross, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: InkWell(
                  borderRadius: AppDesignConstants.borderRadiusMedium,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NearbyRequestsScreen()),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.bloodtype, color: AppColors.primaryRed),
                    title: Text(l10n.nearbyRequests, style: Theme.of(context).textTheme.bodyLarge),
                    subtitle: Text(l10n.checkNearbyBloodRequests, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: InkWell(
                  borderRadius: AppDesignConstants.borderRadiusMedium,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TipsScreen()),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.tips_and_updates, color: AppColors.primaryRed),
                    title: Text(l10n.awareness, style: Theme.of(context).textTheme.bodyLarge),
                    subtitle: Text(l10n.awarenessDonorSubtitle, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Recipient body
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppDesignConstants.edgeInsetsMedium,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _greeting(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _statCard(l10n.bloodGroup, userData?['bloodGroup'] as String? ?? '-')),
                const SizedBox(width: 12),
                Expanded(child: _statCard(l10n.city, userData?['city'] as String? ?? '-')),
              ],
            ),
            const SizedBox(height: 18),
            _buildCard(
              Icons.bloodtype,
              l10n.requestBlood,
              l10n.createNewBloodRequest,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RequestBloodScreen()),
              ),
            ),
            _buildCard(
              Icons.favorite_outline,
              l10n.myRequests,
              l10n.trackPreviousRequests,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RequestsListScreen()),
              ),
            ),
            _buildCard(
              Icons.near_me,
              l10n.nearbyDonors,
              l10n.trackNearbyDonors,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NearbyDonorsScreen()),
              ),
            ),
            _buildCard(
              Icons.tips_and_updates,
              l10n.awareness,
              l10n.awarenessUserSubtitle,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TipsScreen()),
              ),
            ),
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

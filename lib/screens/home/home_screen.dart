import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sheryan/core/enums/user_role.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/core/theme/app_design_constants.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/providers/auth/auth_provider.dart';
import 'package:sheryan/providers/connectivity/connectivity_provider.dart';
import 'package:sheryan/providers/locale/locale_provider.dart';

import 'package:sheryan/widgets/offline_banner.dart';
import 'package:sheryan/screens/admin/admin_dashboard.dart';
import 'package:sheryan/screens/hospital/hospital_dashboard.dart';
import 'package:sheryan/screens/sponsor/sponsor_dashboard.dart';
import 'package:sheryan/screens/donors/donors_list_screen.dart';
import 'package:sheryan/screens/donor_dashboard/donors_list.dart';
import 'package:sheryan/screens/donor_dashboard/donors_profile.dart';
import 'package:sheryan/screens/profile/user_profile_screen.dart';
import 'package:sheryan/screens/requests/create_request_screen.dart';
import 'package:sheryan/screens/requests/requests_list_screen.dart';
import 'package:sheryan/screens/donors/nearby_donors_screen.dart';
import 'package:sheryan/screens/hospitals/nearby_hospitals_screen.dart';
import 'package:sheryan/screens/donor_dashboard/see_users_request.dart';
import 'package:sheryan/screens/donor_dashboard/nearby_users_req.dart';
import 'package:sheryan/screens/misc/awareness_screen.dart';

import 'package:sheryan/screens/donor_dashboard/emergency_alerts_tab.dart';

import 'controllers/home_controller.dart';
import 'providers/home_providers.dart';
import 'widgets/home_app_bar.dart';
import 'widgets/user_welcome_header.dart';
import 'widgets/action_card.dart';
import 'widgets/long_action_card.dart';
import 'widgets/motivational_banner.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedTab = 0;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _listenForReconnect();
  }

  void _listenForReconnect() {
    ref.listenManual(connectivityProvider, (prev, next) {
      if (prev == false && next == true) {
        ref.read(homeControllerProvider).syncPendingRequests(context);
      }
    });
  }

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

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final role = ref.watch(currentUserRoleProvider);

    return profileAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(body: Center(child: Text("Error loading profile"))),
      data: (profile) {
        if (profile == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!_initialized) {
          _initialized = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ref.read(homeControllerProvider).initNotifications(context, profile);
              ref.read(homeControllerProvider).syncPendingRequests(context);
            }
          });
        }

        return _buildRoleDashboard(role, profile);
      },
    );
  }

  Widget _buildRoleDashboard(UserRole role, Map<String, dynamic> profile) {
    if (role == UserRole.hospitalAdmin) {
      return const HospitalDashboard();
    }
    if (role == UserRole.superAdmin) {
      return const AdminDashboard();
    }
    if (role == UserRole.sponsorOrg) {
      return const SponsorDashboard();
    }

    // Donor / Recipient
    final l10n = AppLocalizations.of(context)!;
    final List<Widget> tabs = [
      _HomeBody(role: role, userData: profile),
      if (role == UserRole.recipient) const DonorListScreen(),
      if (role == UserRole.recipient) const ProfileScreen(),
      if (role == UserRole.donor) const EmergencyAlertsTab(),
      if (role == UserRole.donor) const DonorProfileScreen(),
    ];

    final List<BottomNavigationBarItem> items = [
      BottomNavigationBarItem(icon: const Icon(Icons.home), label: l10n.homeTab),
      if (role == UserRole.recipient) ...[
        BottomNavigationBarItem(icon: const Icon(Icons.people), label: l10n.donorsTab),
        BottomNavigationBarItem(icon: const Icon(Icons.person), label: l10n.profileTab),
      ],
      if (role == UserRole.donor) ...[
        BottomNavigationBarItem(icon: const Icon(Icons.campaign_rounded), label: l10n.emergencyAlertsTab),
        BottomNavigationBarItem(icon: const Icon(Icons.person), label: l10n.profileTab),
      ],
    ];

    final safeTab = _selectedTab.clamp(0, tabs.length - 1);

    return Scaffold(
      appBar: HomeAppBar(role: role),
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

class _DashboardWrapper extends StatelessWidget {
  final UserRole role;
  final Widget child;
  const _DashboardWrapper({required this.role, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppBar(role: role, ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  final UserRole role;
  final Map<String, dynamic> userData;
  const _HomeBody({required this.role, required this.userData});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return RefreshIndicator(
      onRefresh: () async => ProviderScope.containerOf(context).invalidate(userProfileProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserWelcomeHeader(userData: userData, role: role),
            const SizedBox(height: 24),
            
            if (role == UserRole.donor) ...[
              _buildSectionHeader(context, l10n.quickActions),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  ActionCard(
                    title: l10n.usersBloodRequests,
                    subtitle: l10n.viewAllRequestsFromUsersAcross,
                    icon: Icons.bloodtype_rounded,
                    color: AppColors.bloodRed,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UsersRequestsScreen()),
                    ),
                  ),
                  ActionCard(
                    title: l10n.nearbyRequests,
                    subtitle: l10n.checkNearbyBloodRequests,
                    icon: Icons.near_me_outlined,
                    color: AppColors.medicalBlue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NearbyRequestsScreen()),
                    ),
                  ),
                  ActionCard(
                    title: l10n.allDonorsTab,
                    subtitle: l10n.viewAllDonors,
                    icon: Icons.people_outline,
                    color: Colors.orange,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DonorsList()),
                    ),
                  ),
                  ActionCard(
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
              const MotivationalBanner(),
            ] else ...[
              // Recipient body
              _buildSectionHeader(context, l10n.needHelp),
              LongActionCard(
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
                    child: ActionCard(
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
                    child: ActionCard(
                      title: l10n.nearbyHospitals,
                      subtitle: l10n.trackNearbyHospitals,
                      icon: Icons.local_hospital_outlined,
                      color: Colors.orange,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NearbyHospitalsScreen()),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(context, l10n.community),
              LongActionCard(
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

  Widget _buildSectionHeader(BuildContext context, String title) {
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
}

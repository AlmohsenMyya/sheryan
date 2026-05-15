import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/providers/auth/auth_provider.dart';

import 'package:sheryan/widgets/offline_banner.dart';
import 'package:sheryan/widgets/notification_badge.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../settings/userside_settings_screen.dart';

import 'dashboard/hospital_stats_bar.dart';
import 'requests/requests_tab.dart';
import 'history/donation_history_tab.dart';
import 'profile/hospital_profile_tab.dart';
import 'scanner/scanner_screen.dart';
import 'scanner/blood_group_verification_screen.dart';

class HospitalDashboard extends ConsumerStatefulWidget {
  const HospitalDashboard({super.key});

  @override
  ConsumerState<HospitalDashboard> createState() => _HospitalDashboardState();
}

class _HospitalDashboardState extends ConsumerState<HospitalDashboard>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _openScanner(BuildContext context, {required bool isVerifyOnly, bool isGeneral = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScannerScreen(isVerifyOnly: isVerifyOnly, isGeneral: isGeneral),
      ),
    );
  }

  void _openBloodGroupVerification(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BloodGroupVerificationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final adminProfile = ref.watch(userProfileProvider).value;
    final hospitalId = adminProfile?['hospitalId'] as String?;
    final hospitalName = adminProfile?['name'] as String? ?? '';
    final adminUid = adminProfile?['uid'] as String? ?? '';
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.hospitalAdminDashboard),
        actions: [
          if (userId != null) NotificationBadge(userId: userId),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: [
            Tab(icon: const Icon(Icons.list_alt), text: l10n.incomingRequests),
            Tab(icon: const Icon(Icons.history), text: l10n.donationHistory),
            Tab(icon: const Icon(Icons.settings), text: l10n.hospitalProfile),
          ],
        ),
      ),
      body: hospitalId == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const OfflineBanner(),
                HospitalStatsBar(hospitalId: hospitalId),
                Container(height: 1, color: Colors.grey.shade200),
                Expanded(
                  child: TabBarView(
                    controller: _tab,
                    children: [
                      RequestsTab(
                        hospitalId: hospitalId,
                        hospitalName: hospitalName,
                        adminUid: adminUid,
                        onOpenScanner: (isVerifyOnly, {isGeneral = false}) =>
                            _openScanner(context, isVerifyOnly: isVerifyOnly, isGeneral: isGeneral),
                        onVerifyBloodGroup: () =>
                            _openBloodGroupVerification(context),
                      ),
                      DonationHistoryTab(hospitalId: hospitalId),
                      HospitalProfileTab(hospitalId: hospitalId),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

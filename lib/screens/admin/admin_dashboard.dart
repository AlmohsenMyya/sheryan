import 'package:flutter/material.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import '../../core/enums/user_role.dart';
import '../home/widgets/home_app_bar.dart';
import 'widgets/admin_sidebar.dart';
import 'overview/admin_overview_view.dart';
import 'hospital_admins/hospital_admin_view.dart';
import 'hospitals/hospital_manager_view.dart';
import 'cities/city_manager_view.dart';
import 'sponsors/sponsor_manager_view.dart';
import 'donors/donor_manager_view.dart';
import 'requests/blood_requests_admin_view.dart';
import 'broadcast/broadcast_view.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  static const _sectionIcons = [
    Icons.dashboard_outlined,
    Icons.admin_panel_settings_outlined,
    Icons.local_hospital_outlined,
    Icons.location_city_outlined,
    Icons.store_outlined,
    Icons.people_outlined,
    Icons.bloodtype_outlined,
    Icons.campaign_outlined,
  ];

  static const _sectionColors = [
    Color(0xFF1565C0),
    Color(0xFF6A1B9A),
    Color(0xFF00838F),
    Color(0xFF2E7D32),
    Color(0xFFE65100),
    Color(0xFFD32F2F), // AppColors.primaryRed fallback
    Color(0xFF6A1B9A),
    Color(0xFFF57F17),
  ];

  Widget _buildBody() {
    return switch (_selectedIndex) {
      0 => const AdminOverviewView(),
      1 => const HospitalAdminManagerView(),
      2 => const HospitalManagerView(),
      3 => const CityManagerView(),
      4 => const SponsorOrgManagerView(),
      5 => const DonorManagerView(),
      6 => const BloodRequestsAdminView(),
      7 => const BroadcastNotifView(),
      _ => const AdminOverviewView(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isWide = MediaQuery.of(context).size.width > 750;

    final labels = [
      l10n.adminOverview,
      l10n.manageHospitalAdmins,
      l10n.manageHospitals,
      l10n.manageCities,
      l10n.manageSponsorOrgs,
      l10n.manageDonors,
      l10n.allBloodRequests,
      l10n.broadcastNotif,
    ];

    return Scaffold(
      appBar: HomeAppBar(role: UserRole.hospitalAdmin),
      body: Row(
        children: [
          AdminSidebar(
            selectedIndex: _selectedIndex,
            onSelect: (i) => setState(() => _selectedIndex = i),
            labels: labels,
            icons: _sectionIcons,
            colors: _sectionColors,
            isWide: isWide,
          ),
          Container(width: 1, color: Colors.grey.shade200),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}

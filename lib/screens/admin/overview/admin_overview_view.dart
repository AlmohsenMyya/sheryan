import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/services/announcement_service.dart';
import 'package:sheryan/services/donation_service.dart';
import 'package:sheryan/services/hospital_service.dart';
import 'package:sheryan/services/request_service.dart';
import 'package:sheryan/services/user_service.dart';
import '../widgets/section_header.dart';
import '../widgets/empty_state.dart';

class AdminOverviewView extends StatelessWidget {
  const AdminOverviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          icon: Icons.dashboard,
          color: const Color(0xFF1565C0),
          title: l10n.adminOverview,
          subtitle: l10n.adminDashboard,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(builder: (context, constraints) {
                  final crossAxis = constraints.maxWidth > 600 ? 4 : 2;
                  return GridView.count(
                    crossAxisCount: crossAxis,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _StatCard(
                        icon: Icons.people,
                        color: AppColors.primaryRed,
                        label: l10n.totalDonors,
                        countStream: UserService().watchByRole('donor').map((l) => l.length),
                      ),
                      _StatCard(
                        icon: Icons.local_hospital,
                        color: const Color(0xFF00838F),
                        label: l10n.totalHospitals,
                        countStream: HospitalService().watchHospitalCount(),
                      ),
                      _StatCard(
                        icon: Icons.bloodtype,
                        color: const Color(0xFF6A1B9A),
                        label: l10n.openRequests,
                        countStream: RequestService().watchOpenCount(),
                      ),
                      _StatCard(
                        icon: Icons.favorite,
                        color: const Color(0xFF2E7D32),
                        label: l10n.totalDonations,
                        countStream: DonationService().watchTotalCount(),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 28),
                Text(l10n.announcementHistory, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: AnnouncementService().watchRecent(limit: 5),
                  builder: (context, snap) {
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                    final docs = snap.data!;
                    if (docs.isEmpty) return EmptyState(icon: Icons.campaign_outlined, message: l10n.noAnnouncementsYet);
                    return Column(
                      children: docs.map((d) {
                        final ts = d['createdAt'] as Timestamp?;
                        final date = ts != null ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}' : '—';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                          child: ListTile(
                            leading: const CircleAvatar(backgroundColor: Color(0xFFFFF8E1), child: Icon(Icons.campaign, color: Color(0xFFF57F17))),
                            title: Text(d['title'] ?? '—', style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(d['body'] ?? ''),
                            trailing: Text(date, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final Stream<int> countStream;

  const _StatCard({required this.icon, required this.color, required this.label, required this.countStream});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.18))),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
              StreamBuilder<int>(stream: countStream, builder: (ctx, snap) => Text(snap.hasData ? snap.data!.toString() : '…', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color))),
            ],
          ),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

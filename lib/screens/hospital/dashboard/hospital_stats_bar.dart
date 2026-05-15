import 'package:flutter/material.dart';
import 'package:sheryan/services/request_service.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/core/theme/app_colors.dart';

class HospitalStatsBar extends StatelessWidget {
  final String hospitalId;
  const HospitalStatsBar({super.key, required this.hospitalId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final svc = RequestService();

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          _HospitalStatCard(
            icon: Icons.assignment_outlined,
            color: const Color(0xFF1565C0),
            label: l10n.totalRequests,
            stream: svc.watchHospitalTotal(hospitalId),
          ),
          _HospitalStatCard(
            icon: Icons.pending_actions_outlined,
            color: Colors.orange,
            label: l10n.openRequests,
            stream: svc.watchHospitalOpen(hospitalId),
          ),
          _HospitalStatCard(
            icon: Icons.verified_outlined,
            color: Colors.blue,
            label: l10n.verifiedLabel,
            stream: svc.watchHospitalVerified(hospitalId),
          ),
          _HospitalStatCard(
            icon: Icons.check_circle_outline,
            color: AppColors.success,
            label: l10n.fulfilledLabel,
            stream: svc.watchHospitalFulfilled(hospitalId),
          ),
        ],
      ),
    );
  }
}

class _HospitalStatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final Stream<int> stream;

  const _HospitalStatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            StreamBuilder<int>(
              stream: stream,
              builder: (_, snap) => Text(
                snap.hasData ? snap.data!.toString() : '…',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

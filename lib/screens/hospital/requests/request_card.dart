import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'request_detail_sheet.dart';

class RequestCard extends StatelessWidget {
  final Map<String, dynamic> doc;
  final bool isDone;
  final bool isVerified;
  final bool isUrgent;
  final String hospitalName;
  final String adminUid;
  final String hospitalId;

  const RequestCard({
    super.key,
    required this.doc,
    required this.isDone,
    required this.isVerified,
    required this.isUrgent,
    required this.hospitalName,
    required this.adminUid,
    required this.hospitalId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final patientName = doc['patientName'] ?? '—';
    final bloodGroup = doc['bloodGroup'] ?? '?';
    final units = doc['units']?.toString() ?? '1';
    final ts = doc['createdAt'] as Timestamp?;
    final dateStr = ts != null
        ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}'
        : '—';

    final Color statusColor;
    final IconData statusIcon;
    if (isDone) {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle;
    } else if (isVerified) {
      statusColor = Colors.blue;
      statusIcon = Icons.verified;
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.pending;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isUrgent ? Colors.red.withOpacity(0.4) : Colors.grey.shade200,
          width: isUrgent ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetailSheet(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryRed.withOpacity(0.3)),
                ),
                alignment: Alignment.center,
                child: Text(
                  bloodGroup,
                  style: const TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(patientName, style: const TextStyle(fontWeight: FontWeight.w600))),
                        if (isUrgent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.red.shade200)),
                            child: Text(l10n.urgentLabel, style: TextStyle(fontSize: 9, color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('$bloodGroup • $units ${l10n.units}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    Text(dateStr, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(statusIcon, color: statusColor, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => RequestDetailSheet(
        doc: doc,
        isDone: isDone,
        isVerified: isVerified,
        hospitalName: hospitalName,
        adminUid: adminUid,
        hospitalId: hospitalId,
      ),
    );
  }
}

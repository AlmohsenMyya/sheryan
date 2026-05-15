import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sheryan/services/donation_service.dart';
import 'package:sheryan/services/user_service.dart';
import 'package:sheryan/services/request_service.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/core/theme/app_colors.dart';

class DonationHistoryTab extends StatelessWidget {
  final String hospitalId;
  const DonationHistoryTab({super.key, required this.hospitalId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: DonationService().watchByHospital(hospitalId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!;
        if (docs.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history, size: 64, color: Colors.grey[300]), const SizedBox(height: 12), Text(l10n.noDonationsYet, style: TextStyle(color: Colors.grey[500], fontSize: 15))]));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i];
            final donorId = data['donorId'] as String?;
            final requestId = data['requestId'] as String?;
            final ts = data['timestamp'] as Timestamp?;
            final isManual = data['manualOverride'] == true;
            final dateStr = ts != null ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}  ${ts.toDate().hour}:${ts.toDate().minute.toString().padLeft(2, '0')}' : '—';

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.favorite, color: AppColors.success, size: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (donorId != null)
                            FutureBuilder<Map<String, dynamic>?>(
                              future: UserService().getById(donorId),
                              builder: (_, snap) {
                                final name = snap.data?['name'] as String? ?? (snap.connectionState == ConnectionState.done ? donorId : '…');
                                final bg = snap.data?['bloodGroup'] as String? ?? '';
                                return Row(children: [Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600))), if (bg.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.primaryRed.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(bg, style: const TextStyle(fontSize: 10, color: AppColors.primaryRed, fontWeight: FontWeight.bold)))]);
                              },
                            ),
                          if (requestId != null)
                            FutureBuilder<Map<String, dynamic>?>(
                              future: RequestService().getById(requestId),
                              builder: (_, snap) {
                                final patient = snap.data?['patientName'] as String? ?? '';
                                if (patient.isEmpty) return const SizedBox.shrink();
                                return Text('${l10n.patientName}: $patient', style: TextStyle(fontSize: 12, color: Colors.grey[600]));
                              },
                            )
                          else
                            Text(l10n.bloodBankStock, style: TextStyle(fontSize: 12, color: Colors.teal.shade700, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Row(children: [Icon(Icons.schedule, size: 12, color: Colors.grey[500]), const SizedBox(width: 4), Text(dateStr, style: TextStyle(fontSize: 11, color: Colors.grey[500])), if (isManual) ...[const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.amber.shade200)), child: Text(l10n.manualBadge, style: TextStyle(fontSize: 9, color: Colors.amber.shade800)))]]),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

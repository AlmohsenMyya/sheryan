import 'package:flutter/material.dart';
import 'package:sheryan/services/request_service.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import '../widgets/action_btn.dart';
import 'request_card.dart';

class RequestsTab extends StatelessWidget {
  final String hospitalId;
  final String hospitalName;
  final String adminUid;
  final void Function(bool isVerifyOnly, {bool isGeneral}) onOpenScanner;
  final VoidCallback onVerifyBloodGroup;

  const RequestsTab({
    super.key,
    required this.hospitalId,
    required this.hospitalName,
    required this.adminUid,
    required this.onOpenScanner,
    required this.onVerifyBloodGroup,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: ActionBtn(icon: Icons.verified_user, label: l10n.verifyRequest, color: Theme.of(context).colorScheme.primary, onTap: () => onOpenScanner(true))),
                  const SizedBox(width: 8),
                  Expanded(child: ActionBtn(icon: Icons.handshake, label: l10n.registerDonation, color: AppColors.success, onTap: () => onOpenScanner(false))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: ActionBtn(icon: Icons.bloodtype, label: l10n.verifyDonorBloodGroup, color: Colors.deepPurple, onTap: onVerifyBloodGroup)),
                  const SizedBox(width: 8),
                  Expanded(child: ActionBtn(icon: Icons.volunteer_activism, label: l10n.registerGeneralDonation, color: Colors.teal, onTap: () => onOpenScanner(false, isGeneral: true))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 1, color: Colors.grey.shade200),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: RequestService().watchByHospital(hospitalId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!;
              if (docs.isEmpty) {
                return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]), const SizedBox(height: 12), Text(l10n.noRequestsFound, style: TextStyle(color: Colors.grey[500], fontSize: 15))]));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final data = docs[i];
                  return RequestCard(
                    doc: data,
                    isDone: data['status'] == 'done' || data['status'] == 'completed',
                    isVerified: (data['isVerified'] ?? false) as bool,
                    isUrgent: (data['isUrgent'] ?? false) as bool,
                    hospitalName: hospitalName,
                    adminUid: adminUid,
                    hospitalId: hospitalId,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

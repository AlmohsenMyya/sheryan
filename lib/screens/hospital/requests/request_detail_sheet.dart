import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import '../controllers/hospital_requests_controller.dart';
import '../widgets/detail_row.dart';
import '../widgets/status_chip.dart';
import 'manual_fulfill_dialog.dart';

class RequestDetailSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> doc;
  final bool isDone;
  final bool isVerified;
  final String hospitalName;
  final String adminUid;
  final String hospitalId;

  const RequestDetailSheet({
    super.key,
    required this.doc,
    required this.isDone,
    required this.isVerified,
    required this.hospitalName,
    required this.adminUid,
    required this.hospitalId,
  });

  @override
  ConsumerState<RequestDetailSheet> createState() => _RequestDetailSheetState();
}

class _RequestDetailSheetState extends ConsumerState<RequestDetailSheet> {
  bool _loading = false;

  void _openManualFulfill() {
    showDialog(
      context: context,
      builder: (_) => ManualFulfillDialog(
        requestDoc: widget.doc,
        hospitalName: widget.hospitalName,
        adminUid: widget.adminUid,
        hospitalId: widget.hospitalId,
        onDone: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = widget.doc;
    final patientName = data['patientName'] ?? '—';
    final bloodGroup = data['bloodGroup'] ?? '?';
    final units = data['units']?.toString() ?? '1';
    final city = data['city'] ?? '—';
    final phone = (data['phone'] ?? data['contactPhone'] ?? '') as String;
    final isUrgent = (data['isUrgent'] ?? false) as bool;
    final ts = data['createdAt'] as Timestamp?;
    final dateStr = ts != null
        ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}  ${ts.toDate().hour}:${ts.toDate().minute.toString().padLeft(2, '0')}'
        : '—';

    final String statusKey = widget.isDone ? 'done' : (widget.isVerified ? 'verified' : 'pending');

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollCtrl) => ListView(
        controller: scrollCtrl,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
          Row(
            children: [
              Expanded(child: Text(l10n.requestDetails, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
              StatusChip(statusKey: statusKey),
              if (isUrgent) ...[
                const SizedBox(width: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade300)), child: Text(l10n.urgentLabel, style: TextStyle(color: Colors.red.shade700, fontSize: 11, fontWeight: FontWeight.bold))),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14), decoration: BoxDecoration(color: AppColors.primaryRed.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primaryRed.withOpacity(0.3))), child: Text(bloodGroup, style: const TextStyle(color: AppColors.primaryRed, fontSize: 34, fontWeight: FontWeight.bold)))),
          const SizedBox(height: 20),
          DetailRow(icon: Icons.person_outline, label: l10n.patientName, value: patientName),
          DetailRow(icon: Icons.water_drop_outlined, label: l10n.units, value: '$units ${l10n.units}'),
          DetailRow(icon: Icons.location_city_outlined, label: l10n.city, value: city),
          DetailRow(icon: Icons.calendar_today_outlined, label: l10n.requestDate, value: dateStr),
          if (phone.isNotEmpty) DetailRow(icon: Icons.phone_outlined, label: l10n.phone, value: phone),
          if (!widget.isDone) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.shade200)), child: Row(children: [Icon(Icons.info_outline, size: 16, color: Colors.amber.shade700), const SizedBox(width: 8), Expanded(child: Text(l10n.manualOverrideNote, style: TextStyle(fontSize: 12, color: Colors.amber.shade800)))])),
            const SizedBox(height: 12),
            if (!widget.isVerified)
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size.fromHeight(48)),
                onPressed: _loading ? null : () async {
                  setState(() => _loading = true);
                  await ref.read(hospitalRequestsProvider).markVerified(context, widget.doc);
                  if (mounted) setState(() => _loading = false);
                },
                icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.verified_outlined),
                label: Text(l10n.markAsVerified),
              ),
            if (widget.isVerified && !widget.isDone) ...[
              const SizedBox(height: 8),
              FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: AppColors.success, minimumSize: const Size.fromHeight(48)), onPressed: _openManualFulfill, icon: const Icon(Icons.handshake_outlined), label: Text(l10n.manualDonationTitle)),
            ],
          ],
        ],
      ),
    );
  }
}

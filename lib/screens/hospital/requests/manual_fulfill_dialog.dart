import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import '../controllers/hospital_requests_controller.dart';

class ManualFulfillDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> requestDoc;
  final String hospitalName;
  final String adminUid;
  final String hospitalId;
  final VoidCallback onDone;

  const ManualFulfillDialog({
    super.key,
    required this.requestDoc,
    required this.hospitalName,
    required this.adminUid,
    required this.hospitalId,
    required this.onDone,
  });

  @override
  ConsumerState<ManualFulfillDialog> createState() => _ManualFulfillDialogState();
}

class _ManualFulfillDialogState extends ConsumerState<ManualFulfillDialog> {
  final _formKey = GlobalKey<FormState>();
  final _donorIdCtrl = TextEditingController();
  bool _loading = false;
  String? _donorName;

  @override
  void dispose() {
    _donorIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(hospitalRequestsProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [const Icon(Icons.handshake, color: AppColors.success), const SizedBox(width: 8), Expanded(child: Text(l10n.manualDonationTitle))]),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.enterDonorId, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _donorIdCtrl,
                    decoration: InputDecoration(labelText: l10n.donorId, prefixIcon: const Icon(Icons.badge_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null,
                    onChanged: (_) => setState(() => _donorName = null),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _loading ? null : () async {
                    setState(() => _loading = true);
                    final donor = await controller.lookupDonor(context, _donorIdCtrl.text.trim());
                    if (mounted) setState(() { _donorName = donor?['name']; _loading = false; });
                  },
                  icon: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.search),
                  style: IconButton.styleFrom(backgroundColor: Colors.blue.shade50),
                ),
              ],
            ),
            if (_donorName != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade200)),
                child: Row(children: [const Icon(Icons.person_outline, color: AppColors.success, size: 18), const SizedBox(width: 8), Expanded(child: Text(_donorName!, style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)))]),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.success),
          onPressed: _loading ? null : () async {
            if (!_formKey.currentState!.validate()) return;
            if (_donorName == null) {
               setState(() => _loading = true);
               final donor = await controller.lookupDonor(context, _donorIdCtrl.text.trim());
               if (mounted) setState(() { _donorName = donor?['name']; _loading = false; });
               if (_donorName == null) return;
            }

            final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: Text(l10n.confirmDonationTitle), content: Text(l10n.confirmDonationBody), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.confirm))]));
            if (confirmed != true) return;

            if (mounted) {
              setState(() => _loading = true);
              await controller.completeManualDonation(context: context, donorId: _donorIdCtrl.text.trim(), requestId: widget.requestDoc['id'], hospitalId: widget.hospitalId, hospitalName: widget.hospitalName, adminUid: widget.adminUid);
              if (mounted) { setState(() => _loading = false); widget.onDone(); }
            }
          },
          child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(l10n.markAsDone),
        ),
      ],
    );
  }
}

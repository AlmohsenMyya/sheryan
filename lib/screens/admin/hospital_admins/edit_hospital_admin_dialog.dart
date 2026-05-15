import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/services/hospital_service.dart';
import 'hospital_admin_controller.dart';

class EditHospitalAdminDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> admin;
  const EditHospitalAdminDialog({super.key, required this.admin});

  @override
  ConsumerState<EditHospitalAdminDialog> createState() => _EditHospitalAdminDialogState();
}

class _EditHospitalAdminDialogState extends ConsumerState<EditHospitalAdminDialog> {
  late final TextEditingController _nameCtrl;
  String? _hospitalId;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.admin['name']);
    _hospitalId = widget.admin['hospitalId'];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(hospitalAdminProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(l10n.editAdmin),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(controller: _nameCtrl, decoration: InputDecoration(labelText: l10n.fullName)),
            const SizedBox(height: 12),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: HospitalService().watchHospitals(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                final hospitals = snapshot.data!;
                return DropdownButtonFormField<String>(value: _hospitalId, decoration: InputDecoration(labelText: l10n.hospitalName), items: hospitals.map((h) => DropdownMenuItem(value: h['id'] as String, child: Text(h['name']))).toList(), onChanged: (v) => setState(() => _hospitalId = v));
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: state.isLoading ? null : () {
            ref.read(hospitalAdminProvider.notifier).updateAdmin(context: context, uid: widget.admin['id'], name: _nameCtrl.text.trim(), hospitalId: _hospitalId, onSuccess: () => Navigator.pop(context));
          },
          child: state.isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(l10n.saveChanges),
        ),
      ],
    );
  }
}

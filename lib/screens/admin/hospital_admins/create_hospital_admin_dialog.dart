import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/services/hospital_service.dart';
import 'hospital_admin_controller.dart';

class CreateHospitalAdminDialog extends ConsumerStatefulWidget {
  const CreateHospitalAdminDialog({super.key});

  @override
  ConsumerState<CreateHospitalAdminDialog> createState() => _CreateHospitalAdminDialogState();
}

class _CreateHospitalAdminDialogState extends ConsumerState<CreateHospitalAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String? _selectedHospitalId;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(hospitalAdminProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(l10n.createAdmin),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: _nameCtrl, decoration: InputDecoration(labelText: l10n.fullName, prefixIcon: const Icon(Icons.person_outline)), validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null),
                const SizedBox(height: 12),
                TextFormField(controller: _emailCtrl, decoration: InputDecoration(labelText: l10n.email, prefixIcon: const Icon(Icons.email_outlined)), validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null),
                const SizedBox(height: 12),
                TextFormField(controller: _passwordCtrl, obscureText: true, decoration: InputDecoration(labelText: l10n.password, prefixIcon: const Icon(Icons.lock_outline)), validator: (v) => (v == null || v.length < 6) ? l10n.passwordMinLength : null),
                const SizedBox(height: 12),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: HospitalService().watchHospitals(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const LinearProgressIndicator();
                    final hospitals = snapshot.data!;
                    return DropdownButtonFormField<String>(value: _selectedHospitalId, decoration: InputDecoration(labelText: l10n.hospitalName, prefixIcon: const Icon(Icons.local_hospital_outlined)), items: hospitals.map((h) => DropdownMenuItem(value: h['id'] as String, child: Text(h['name']))).toList(), onChanged: (v) => setState(() => _selectedHospitalId = v), validator: (v) => v == null ? l10n.requiredField : null);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: state.isLoading ? null : () {
            if (_formKey.currentState!.validate() && _selectedHospitalId != null) {
              ref.read(hospitalAdminProvider.notifier).createAdmin(context: context, name: _nameCtrl.text.trim(), email: _emailCtrl.text.trim(), password: _passwordCtrl.text, hospitalId: _selectedHospitalId!, onSuccess: () => Navigator.pop(context));
            }
          },
          child: state.isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(l10n.createAdmin),
        ),
      ],
    );
  }
}

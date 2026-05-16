import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/services/hospital_service.dart';
import 'sponsor_controller.dart';

class CreateSponsorDialog extends ConsumerStatefulWidget {
  const CreateSponsorDialog({super.key});

  @override
  ConsumerState<CreateSponsorDialog> createState() => _CreateSponsorDialogState();
}

class _CreateSponsorDialogState extends ConsumerState<CreateSponsorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _selectedCity;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(sponsorProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(l10n.createSponsor),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: _nameCtrl, decoration: InputDecoration(labelText: l10n.sponsorOrgName, prefixIcon: const Icon(Icons.store_outlined)), validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null),
                const SizedBox(height: 12),
                TextFormField(controller: _emailCtrl, decoration: InputDecoration(labelText: l10n.email, prefixIcon: const Icon(Icons.email_outlined)), validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null),
                const SizedBox(height: 12),
                TextFormField(controller: _passCtrl, obscureText: true, decoration: InputDecoration(labelText: l10n.password, prefixIcon: const Icon(Icons.lock_outline)), validator: (v) => (v == null || v.length < 6) ? l10n.passwordMinLength : null),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 9,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.sponsorPhone,
                    prefixIcon: const Icon(Icons.phone_outlined),
                    prefixText: l10n.phonePrefix,
                    hintText: '9XXXXXXXX',
                    counterText: '',
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null,
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: HospitalService().watchCities(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const LinearProgressIndicator();
                    final cities = snapshot.data!;
                    return DropdownButtonFormField<String>(value: _selectedCity, hint: Text(l10n.selectCity), decoration: InputDecoration(prefixIcon: const Icon(Icons.location_city_outlined)), items: cities.map((c) => DropdownMenuItem(value: c['name'] as String, child: Text(c['name']))).toList(), onChanged: (v) => setState(() => _selectedCity = v), validator: (v) => v == null ? l10n.requiredField : null);
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
            if (_formKey.currentState!.validate() && _selectedCity != null) {
              if (_phoneCtrl.text.trim().length != 9) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.invalidSyrianPhone)),
                );
                return;
              }

              final fullPhone = '+963${_phoneCtrl.text.trim()}';
              ref.read(sponsorProvider.notifier).createSponsor(
                context: context, 
                name: _nameCtrl.text.trim(), 
                email: _emailCtrl.text.trim(), 
                password: _passCtrl.text, 
                phone: fullPhone, 
                city: _selectedCity!, 
                onSuccess: () => Navigator.pop(context)
              );
            }
          },
          child: state.isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(l10n.createSponsor),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheryan/services/hospital_service.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import '../controllers/hospital_profile_controller.dart';

class HospitalProfileTab extends ConsumerStatefulWidget {
  final String hospitalId;
  const HospitalProfileTab({super.key, required this.hospitalId});

  @override
  ConsumerState<HospitalProfileTab> createState() => _HospitalProfileTabState();
}

class _HospitalProfileTabState extends ConsumerState<HospitalProfileTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _loading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<Map<String, dynamic>?>(
      future: HospitalService().getHospitalById(widget.hospitalId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!;
        if (!_initialized) {
          _nameController.text = data['name'] ?? '';
          _cityController.text = data['city'] ?? '';
          String phone = data['phone'] ?? '';
          if (phone.startsWith('+963')) {
            phone = phone.substring(4);
          }
          _phoneController.text = phone;
          _addressController.text = data['address'] ?? '';
          _initialized = true;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.updateHospitalInfo, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextFormField(controller: _nameController, decoration: InputDecoration(labelText: l10n.hospitalName, prefixIcon: const Icon(Icons.business)), validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null),
                const SizedBox(height: 16),
                TextFormField(controller: _cityController, enabled: false, decoration: InputDecoration(labelText: l10n.city, prefixIcon: const Icon(Icons.location_city))),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 9,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.inquiryPhone,
                    prefixIcon: const Icon(Icons.phone_in_talk),
                    prefixText: l10n.phonePrefix,
                    hintText: '9XXXXXXXX',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(controller: _addressController, maxLines: 2, decoration: InputDecoration(labelText: l10n.fullAddress, prefixIcon: const Icon(Icons.place), hintText: 'Street, Building, Near...')),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _loading ? null : () async {
                    if (!_formKey.currentState!.validate()) return;
                    if (_phoneController.text.trim().length != 9) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.invalidSyrianPhone)),
                      );
                      return;
                    }

                    setState(() => _loading = true);
                    final fullPhone = '+963${_phoneController.text.trim()}';
                    await ref.read(hospitalProfileControllerProvider).updateProfile(
                      context: context,
                      hospitalId: widget.hospitalId,
                      name: _nameController.text.trim(),
                      city: _cityController.text.trim(),
                      phone: fullPhone,
                      address: _addressController.text.trim(),
                    );
                    if (mounted) setState(() => _loading = false);
                  },
                  icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
                  label: Text(l10n.saveChanges),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

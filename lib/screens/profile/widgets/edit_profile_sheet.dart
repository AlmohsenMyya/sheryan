import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheryan/core/theme/app_design_constants.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/screens/profile/controllers/profile_controller.dart';

class EditProfileSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileSheet({super.key, required this.userData});

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _phone;
  String? _selectedCity;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.userData['name']);
    _phone = TextEditingController(text: widget.userData['phone']);
    _selectedCity = widget.userData['city'];
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.saveChanges, // Or an "Edit Profile" string if available
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: l10n.fullName,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (v) => v == null || v.isEmpty ? l10n.requiredField : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.phone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                validator: (v) => v == null || v.isEmpty ? l10n.requiredField : null,
              ),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('cities').orderBy('name').snapshots(),
                builder: (context, snapshot) {
                  final cities = snapshot.data?.docs ?? [];
                  return DropdownButtonFormField<String>(
                    value: _selectedCity,
                    decoration: InputDecoration(
                      labelText: l10n.city,
                      prefixIcon: const Icon(Icons.location_city_outlined),
                    ),
                    items: cities.map((c) => DropdownMenuItem(
                      value: c['name'] as String,
                      child: Text(c['name'] as String),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedCity = v),
                    validator: (v) => v == null ? l10n.requiredField : null,
                  );
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _loading ? null : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _loading = true);
                  await ref.read(profileControllerProvider).updateProfile(
                    context: context,
                    name: _name.text.trim(),
                    phone: _phone.text.trim(),
                    city: _selectedCity!,
                  );
                  if (mounted) Navigator.pop(context);
                },
                child: _loading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(l10n.saveChanges),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

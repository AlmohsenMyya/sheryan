import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/services/hospital_service.dart';
import 'sponsor_controller.dart';

class EditSponsorDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> sponsor;
  const EditSponsorDialog({super.key, required this.sponsor});

  @override
  ConsumerState<EditSponsorDialog> createState() => _EditSponsorDialogState();
}

class _EditSponsorDialogState extends ConsumerState<EditSponsorDialog> {
  late final TextEditingController _nameCtrl;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.sponsor['name']);
    _selectedCity = widget.sponsor['city'];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(sponsorProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(l10n.editSponsor),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(controller: _nameCtrl, decoration: InputDecoration(labelText: l10n.sponsorOrgName, prefixIcon: const Icon(Icons.store_outlined))),
            const SizedBox(height: 12),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: HospitalService().watchCities(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                final cities = snapshot.data!;
                return DropdownButtonFormField<String>(value: _selectedCity, decoration: InputDecoration(labelText: l10n.city, prefixIcon: const Icon(Icons.location_city_outlined)), items: cities.map((c) => DropdownMenuItem(value: c['name'] as String, child: Text(c['name']))).toList(), onChanged: (v) => setState(() => _selectedCity = v));
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: state.isLoading ? null : () {
            ref.read(sponsorProvider.notifier).updateSponsor(context: context, uid: widget.sponsor['id'], name: _nameCtrl.text.trim(), city: _selectedCity, onSuccess: () => Navigator.pop(context));
          },
          child: state.isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(l10n.saveChanges),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/services/hospital_service.dart';
import '../widgets/section_header.dart';
import '../widgets/empty_state.dart';
import '../widgets/admin_dialogs.dart';
import '../controllers/admin_general_controller.dart';

class HospitalManagerView extends ConsumerWidget {
  const HospitalManagerView({super.key});

  static const _color = Color(0xFF00838F);

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    String? selectedCity;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final l10n = AppLocalizations.of(ctx)!;
          final state = ref.watch(adminGeneralProvider);
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(l10n.addHospital),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(controller: nameCtrl, decoration: InputDecoration(labelText: l10n.hospitalName, prefixIcon: const Icon(Icons.local_hospital_outlined))),
                  const SizedBox(height: 12),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: HospitalService().watchCities(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const LinearProgressIndicator();
                      final cities = snapshot.data!;
                      return DropdownButtonFormField<String>(value: selectedCity, hint: Text(l10n.selectCity), decoration: InputDecoration(labelText: l10n.city, prefixIcon: const Icon(Icons.location_city_outlined)), items: cities.map((c) => DropdownMenuItem(value: c['name'] as String, child: Text(c['name']))).toList(), onChanged: (v) => setS(() => selectedCity = v));
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
              FilledButton(
                onPressed: state.isLoading ? null : () {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty || selectedCity == null) return;
                  ref.read(adminGeneralProvider.notifier).addHospital(context: context, name: name, city: selectedCity!, onSuccess: () => Navigator.pop(ctx));
                },
                child: state.isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(l10n.addHospital),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> hospital) {
    final nameCtrl = TextEditingController(text: hospital['name'] as String? ?? '');
    String? selectedCity = hospital['city'] as String?;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final l10n = AppLocalizations.of(ctx)!;
          final state = ref.watch(adminGeneralProvider);
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(l10n.editHospital),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(controller: nameCtrl, decoration: InputDecoration(labelText: l10n.hospitalName)),
                  const SizedBox(height: 12),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: HospitalService().watchCities(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const LinearProgressIndicator();
                      final cities = snapshot.data!;
                      return DropdownButtonFormField<String>(value: selectedCity, items: cities.map((c) => DropdownMenuItem(value: c['name'] as String, child: Text(c['name']))).toList(), onChanged: (v) => setS(() => selectedCity = v));
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
              FilledButton(
                onPressed: state.isLoading ? null : () {
                  if (selectedCity == null) return;
                  ref.read(adminGeneralProvider.notifier).updateHospital(context: context, id: hospital['id'] as String, name: nameCtrl.text.trim(), city: selectedCity!, onSuccess: () => Navigator.pop(ctx));
                },
                child: state.isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(l10n.saveChanges),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        SectionHeader(
          icon: Icons.local_hospital,
          color: _color,
          title: l10n.manageHospitals,
          subtitle: l10n.addHospital,
          action: FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: _color), onPressed: () => _showAddDialog(context, ref), icon: const Icon(Icons.add), label: Text(l10n.addHospital)),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: HospitalService().watchHospitals(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!;
              if (docs.isEmpty) return EmptyState(icon: Icons.local_hospital_outlined, message: l10n.noHospitalsFound);
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final h = docs[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(backgroundColor: _color.withOpacity(0.12), child: const Icon(Icons.local_hospital, color: _color, size: 20)),
                      title: Text(h['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Row(children: [const Icon(Icons.location_on_outlined, size: 13, color: Colors.grey), const SizedBox(width: 4), Text(h['city'] ?? '—', style: const TextStyle(fontSize: 12))]),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: Icon(Icons.edit_outlined, color: _color), onPressed: () => _showEditDialog(context, ref, h)),
                          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () async {
                            final confirmed = await confirmDelete(context, l10n.confirmDeleteBody);
                            if (confirmed == true) ref.read(adminGeneralProvider.notifier).deleteHospital(context, h['id'] as String);
                          }),
                        ],
                      ),
                    ),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/services/hospital_service.dart';
import '../widgets/section_header.dart';
import '../widgets/empty_state.dart';
import '../widgets/admin_dialogs.dart';
import '../controllers/admin_general_controller.dart';

class CityManagerView extends ConsumerWidget {
  const CityManagerView({super.key});

  static const _color = Color(0xFF2E7D32);

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        final state = ref.watch(adminGeneralProvider);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n.addCity),
          content: TextFormField(controller: nameCtrl, autofocus: true, decoration: InputDecoration(labelText: l10n.cityName, prefixIcon: const Icon(Icons.location_city_outlined))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: state.isLoading ? null : () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                ref.read(adminGeneralProvider.notifier).addCity(context: context, name: name, onSuccess: () => Navigator.pop(ctx));
              },
              child: state.isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(l10n.addCity),
            ),
          ],
        );
      },
    );
  }

  void _showEditCityDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> city) {
    final nameCtrl = TextEditingController(text: city['name'] as String? ?? '');
    showDialog(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        final state = ref.watch(adminGeneralProvider);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n.editCity),
          content: TextFormField(controller: nameCtrl, autofocus: true, decoration: InputDecoration(labelText: l10n.cityName, prefixIcon: const Icon(Icons.location_city_outlined))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: state.isLoading ? null : () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                ref.read(adminGeneralProvider.notifier).updateCity(context: context, id: city['id'] as String, name: name, onSuccess: () => Navigator.pop(ctx));
              },
              child: state.isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(l10n.saveChanges),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        SectionHeader(
          icon: Icons.location_city,
          color: _color,
          title: l10n.manageCities,
          subtitle: l10n.addCity,
          action: FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: _color), onPressed: () => _showAddDialog(context, ref), icon: const Icon(Icons.add), label: Text(l10n.addCity)),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: HospitalService().watchCities(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!;
              if (docs.isEmpty) return EmptyState(icon: Icons.location_city_outlined, message: l10n.noCitiesFound);
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final city = docs[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: _color.withOpacity(0.12), child: Icon(Icons.location_city, color: _color, size: 20)),
                      title: Text(city['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: Icon(Icons.edit_outlined, color: _color), onPressed: () => _showEditCityDialog(context, ref, city)),
                          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () async {
                            final confirmed = await confirmDelete(context, l10n.confirmDeleteBody);
                            if (confirmed == true) ref.read(adminGeneralProvider.notifier).deleteCity(context, city['id'] as String);
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

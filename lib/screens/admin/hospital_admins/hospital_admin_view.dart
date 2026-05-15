import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/services/hospital_service.dart';
import 'package:sheryan/services/user_service.dart';
import '../widgets/section_header.dart';
import '../widgets/empty_state.dart';
import '../widgets/admin_dialogs.dart';
import 'hospital_admin_controller.dart';
import 'create_hospital_admin_dialog.dart';
import 'edit_hospital_admin_dialog.dart';

class HospitalAdminManagerView extends ConsumerWidget {
  const HospitalAdminManagerView({super.key});

  static const _color = Color(0xFF6A1B9A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        SectionHeader(
          icon: Icons.admin_panel_settings,
          color: _color,
          title: l10n.manageHospitalAdmins,
          subtitle: l10n.manageHospitalAdminsSubtitle,
          action: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: _color),
            onPressed: () => showDialog(context: context, builder: (_) => const CreateHospitalAdminDialog()),
            icon: const Icon(Icons.add),
            label: Text(l10n.createAdmin),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: UserService().watchByRole('hospitalAdmin'),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!;
              if (docs.isEmpty) return EmptyState(icon: Icons.admin_panel_settings_outlined, message: l10n.noAdminsFound);
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final admin = docs[i];
                  final name = admin['name'] ?? '—';
                  final email = admin['email'] ?? '—';
                  final hospitalId = admin['hospitalId'] as String?;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(backgroundColor: _color.withOpacity(0.12), child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: _color, fontWeight: FontWeight.bold))),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(email, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          if (hospitalId != null && hospitalId.isNotEmpty)
                            FutureBuilder<Map<String, dynamic>?>(
                              future: HospitalService().getHospitalById(hospitalId),
                              builder: (_, snap) {
                                final hName = snap.data?['name'] as String? ?? '…';
                                return Row(children: [Icon(Icons.local_hospital_outlined, size: 11, color: _color.withOpacity(0.7)), const SizedBox(width: 3), Text(hName, style: TextStyle(fontSize: 11, color: _color.withOpacity(0.85)))]);
                              },
                            ),
                        ],
                      ),
                      isThreeLine: hospitalId != null && hospitalId.isNotEmpty,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: Icon(Icons.edit_outlined, color: _color), onPressed: () => showDialog(context: context, builder: (_) => EditHospitalAdminDialog(admin: admin))),
                          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () async {
                            final confirmed = await confirmDelete(context, l10n.confirmDeleteBody);
                            if (confirmed == true) ref.read(hospitalAdminProvider.notifier).deleteAdmin(context, admin['id'] as String);
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/services/user_service.dart';
import '../widgets/section_header.dart';
import '../widgets/empty_state.dart';
import '../widgets/admin_dialogs.dart';
import 'sponsor_controller.dart';
import 'create_sponsor_dialog.dart';
import 'edit_sponsor_dialog.dart';

class SponsorOrgManagerView extends ConsumerWidget {
  const SponsorOrgManagerView({super.key});

  static const _color = Color(0xFFE65100);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        SectionHeader(
          icon: Icons.store,
          color: _color,
          title: l10n.manageSponsorOrgs,
          subtitle: l10n.createSponsor,
          action: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: _color),
            onPressed: () => showDialog(context: context, builder: (_) => const CreateSponsorDialog()),
            icon: const Icon(Icons.add),
            label: Text(l10n.createSponsor),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: UserService().watchByRole('sponsorOrg'),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!;
              if (docs.isEmpty) return EmptyState(icon: Icons.store_outlined, message: l10n.noSponsorsFound);
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final sponsor = docs[i];
                  final name = sponsor['name'] ?? '—';
                  final city = sponsor['city'] ?? '—';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(backgroundColor: _color.withOpacity(0.12), child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: _color, fontWeight: FontWeight.bold))),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Row(children: [const Icon(Icons.location_on_outlined, size: 13, color: Colors.grey), const SizedBox(width: 4), Text(city, style: const TextStyle(fontSize: 12))]),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: Icon(Icons.edit_outlined, color: _color), onPressed: () => showDialog(context: context, builder: (_) => EditSponsorDialog(sponsor: sponsor))),
                          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () async {
                            final confirmed = await confirmDelete(context, l10n.confirmDeleteBody);
                            if (confirmed == true) ref.read(sponsorProvider.notifier).deleteSponsor(context, sponsor['id'] as String);
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

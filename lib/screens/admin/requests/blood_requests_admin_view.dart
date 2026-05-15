import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/services/request_service.dart';
import '../widgets/section_header.dart';
import '../widgets/empty_state.dart';
import '../widgets/admin_dialogs.dart';
import '../widgets/blood_group_badge.dart';
import '../widgets/status_badge.dart';

class BloodRequestsAdminView extends StatefulWidget {
  const BloodRequestsAdminView({super.key});

  @override
  State<BloodRequestsAdminView> createState() => _BloodRequestsAdminViewState();
}

class _BloodRequestsAdminViewState extends State<BloodRequestsAdminView> {
  static const _color = Color(0xFF6A1B9A);
  String _filterStatus = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        SectionHeader(icon: Icons.bloodtype, color: _color, title: l10n.allBloodRequests, subtitle: l10n.openRequests),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(label: l10n.allStatuses, selected: _filterStatus.isEmpty, color: _color, onTap: () => setState(() => _filterStatus = '')),
                const SizedBox(width: 8),
                _FilterChip(label: l10n.statusPending, selected: _filterStatus == 'pending', color: Colors.orange, onTap: () => setState(() => _filterStatus = 'pending')),
                const SizedBox(width: 8),
                _FilterChip(label: l10n.statusVerified, selected: _filterStatus == 'verified', color: Colors.blue, onTap: () => setState(() => _filterStatus = 'verified')),
                const SizedBox(width: 8),
                _FilterChip(label: l10n.statusDone, selected: _filterStatus == 'done', color: Colors.green, onTap: () => setState(() => _filterStatus = 'done')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: RequestService().watchAll(status: _filterStatus.isEmpty ? null : _filterStatus),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!;
              if (docs.isEmpty) return EmptyState(icon: Icons.bloodtype_outlined, message: l10n.noBloodRequestsFound);
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final req = docs[i];
                  final patient = req['patientName'] ?? l10n.unknownPatient;
                  final bg = req['bloodGroup'] ?? '?';
                  final city = req['city'] ?? '—';
                  final hospital = req['hospitalName'] ?? req['hospital'] ?? '—';
                  final status = req['status'] ?? 'pending';
                  final ts = req['createdAt'] as Timestamp?;
                  final date = ts != null ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}' : '—';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          BloodGroupBadge(bloodGroup: bg),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(patient, style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Row(children: [const Icon(Icons.local_hospital_outlined, size: 12, color: Colors.grey), const SizedBox(width: 4), Text(hospital, style: const TextStyle(fontSize: 11)), const SizedBox(width: 8), const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey), const SizedBox(width: 4), Text(city, style: const TextStyle(fontSize: 11))]),
                                Text(date, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(status: status),
                          const SizedBox(width: 8),
                          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () async {
                            final confirmed = await confirmDelete(context, l10n.confirmDeleteBody);
                            if (confirmed == true) await RequestService().deleteById(req['id'] as String);
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(color: selected ? color : color.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: selected ? color : color.withOpacity(0.3))),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : color, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

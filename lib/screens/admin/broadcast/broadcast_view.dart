import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/services/hospital_service.dart';
import 'package:sheryan/services/announcement_service.dart';
import '../widgets/section_header.dart';
import '../widgets/empty_state.dart';
import 'broadcast_controller.dart';

class BroadcastNotifView extends ConsumerStatefulWidget {
  const BroadcastNotifView({super.key});

  @override
  ConsumerState<BroadcastNotifView> createState() => _BroadcastNotifViewState();
}

class _BroadcastNotifViewState extends ConsumerState<BroadcastNotifView> {
  static const _color = Color(0xFFF57F17);
  final _formKey = GlobalKey<FormState>();
  final _titleArCtrl = TextEditingController();
  final _titleEnCtrl = TextEditingController();
  final _bodyArCtrl = TextEditingController();
  final _bodyEnCtrl = TextEditingController();

  bool _filterByCity = false;
  bool _filterByBloodGroup = false;
  String? _targetCity;
  String? _targetBloodGroup;

  static const _bloodGroups = ['A+', 'A−', 'B+', 'B−', 'AB+', 'AB−', 'O+', 'O−'];

  @override
  void dispose() {
    _titleArCtrl.dispose();
    _titleEnCtrl.dispose();
    _bodyArCtrl.dispose();
    _bodyEnCtrl.dispose();
    super.dispose();
  }

  void _resetForm() {
    _titleArCtrl.clear();
    _titleEnCtrl.clear();
    _bodyArCtrl.clear();
    _bodyEnCtrl.clear();
    setState(() {
      _filterByCity = false;
      _filterByBloodGroup = false;
      _targetCity = null;
      _targetBloodGroup = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final state = ref.watch(broadcastProvider);

    return Column(
      children: [
        SectionHeader(
          icon: Icons.campaign,
          color: _color,
          title: l10n.broadcastNotif,
          subtitle: l10n.targetAudience,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(l10n.sendNotif, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          const Text("Arabic Content (المحتوى العربي)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 8),
                          TextFormField(controller: _titleArCtrl, decoration: InputDecoration(labelText: "${l10n.notifTitleField} (Arabic)", prefixIcon: const Icon(Icons.title_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null),
                          const SizedBox(height: 12),
                          TextFormField(controller: _bodyArCtrl, maxLines: 2, decoration: InputDecoration(labelText: "${l10n.notifBodyField} (Arabic)", prefixIcon: const Icon(Icons.message_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 12),
                          const Text("English Content", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 8),
                          TextFormField(controller: _titleEnCtrl, decoration: InputDecoration(labelText: "${l10n.notifTitleField} (English)", prefixIcon: const Icon(Icons.title_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null),
                          const SizedBox(height: 12),
                          TextFormField(controller: _bodyEnCtrl, maxLines: 2, decoration: InputDecoration(labelText: "${l10n.notifBodyField} (English)", prefixIcon: const Icon(Icons.message_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null),
                          const SizedBox(height: 24),
                          Text(l10n.targetAudience, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilterChip(label: Text(l10n.targetAll), selected: !_filterByCity && !_filterByBloodGroup, onSelected: (val) { if (val) setState(() { _filterByCity = false; _filterByBloodGroup = false; }); }, selectedColor: _color.withOpacity(0.2), checkmarkColor: _color),
                              FilterChip(label: Text(l10n.targetByCity), selected: _filterByCity, onSelected: (val) { setState(() => _filterByCity = val); }, selectedColor: _color.withOpacity(0.2), checkmarkColor: _color),
                              FilterChip(label: Text(l10n.targetByBloodGroup), selected: _filterByBloodGroup, onSelected: (val) { setState(() => _filterByBloodGroup = val); }, selectedColor: _color.withOpacity(0.2), checkmarkColor: _color),
                            ],
                          ),
                          if (_filterByCity) ...[
                            const SizedBox(height: 16),
                            StreamBuilder<List<Map<String, dynamic>>>(
                              stream: HospitalService().watchCities(),
                              builder: (context, snap) {
                                final cities = snap.data ?? [];
                                return DropdownButtonFormField<String>(value: _targetCity, hint: Text(l10n.selectCity), decoration: InputDecoration(labelText: l10n.city, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), items: cities.map((c) => DropdownMenuItem(value: c['name'] as String, child: Text(c['name']))).toList(), onChanged: (v) => setState(() => _targetCity = v), validator: (v) => v == null ? l10n.requiredField : null);
                              },
                            ),
                          ],
                          if (_filterByBloodGroup) ...[
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(value: _targetBloodGroup, hint: Text(l10n.allBloodGroups), decoration: InputDecoration(labelText: l10n.bloodGroup, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), items: _bloodGroups.map((bg) => DropdownMenuItem(value: bg, child: Text(bg))).toList(), onChanged: (v) => setState(() => _targetBloodGroup = v), validator: (v) => v == null ? l10n.requiredField : null),
                          ],
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: _color, padding: const EdgeInsets.symmetric(vertical: 14)),
                            onPressed: state.isSending ? null : () {
                              if (_formKey.currentState!.validate()) {
                                ref.read(broadcastProvider.notifier).sendNotification(context: context, titleAr: _titleArCtrl.text, titleEn: _titleEnCtrl.text, bodyAr: _bodyArCtrl.text, bodyEn: _bodyEnCtrl.text, filterByCity: _filterByCity, filterByBloodGroup: _filterByBloodGroup, targetCity: _targetCity, targetBloodGroup: _targetBloodGroup, onSuccess: _resetForm);
                              }
                            },
                            icon: state.isSending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send_rounded),
                            label: Text(l10n.sendNotif, style: const TextStyle(fontSize: 15)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(l10n.announcementHistory, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: AnnouncementService().watchRecent(limit: 20),
                  builder: (context, snap) {
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                    final docs = snap.data!;
                    if (docs.isEmpty) return EmptyState(icon: Icons.campaign_outlined, message: l10n.noAnnouncementsYet);
                    return Column(
                      children: docs.map((d) {
                        final ts = d['createdAt'] as Timestamp?;
                        final date = ts != null ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year} ${ts.toDate().hour}:${ts.toDate().minute.toString().padLeft(2, '0')}' : '—';
                        final target = d['target'] ?? 'all';
                        final targetCity = d['targetCity'] ?? '';
                        final targetBg = d['targetBloodGroup'] ?? '';
                        String targetLabel = l10n.targetAll;
                        if (target == 'both') targetLabel = '${l10n.city}: $targetCity, ${l10n.bloodGroup}: $targetBg'; else if (target == 'city') targetLabel = '${l10n.city}: $targetCity'; else if (target == 'bloodGroup') targetLabel = '${l10n.bloodGroup}: $targetBg';
                        final title = (lang == 'ar') ? (d['titleAr'] ?? d['title'] ?? '—') : (d['titleEn'] ?? d['title'] ?? '—');
                        final body = (lang == 'ar') ? (d['bodyAr'] ?? d['body'] ?? '') : (d['bodyEn'] ?? d['body'] ?? '');
                        return Card(margin: const EdgeInsets.only(bottom: 8), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)), child: ListTile(leading: CircleAvatar(backgroundColor: _color.withOpacity(0.12), child: Icon(Icons.campaign, color: _color)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(body), Row(children: [Icon(Icons.people_outline, size: 12, color: _color.withOpacity(0.7)), const SizedBox(width: 4), Text(targetLabel, style: TextStyle(fontSize: 11, color: _color))])]), trailing: Text(date, style: TextStyle(fontSize: 10, color: Colors.grey[500]))));
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

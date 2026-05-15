import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/services/hospital_service.dart';
import 'package:sheryan/services/user_service.dart';
import '../widgets/section_header.dart';
import '../widgets/empty_state.dart';
import '../widgets/admin_dialogs.dart';
import '../widgets/blood_group_badge.dart';

class DonorManagerView extends StatefulWidget {
  const DonorManagerView({super.key});

  @override
  State<DonorManagerView> createState() => _DonorManagerViewState();
}

class _DonorManagerViewState extends State<DonorManagerView> {
  static const _color = AppColors.primaryRed;
  final _searchCtrl = TextEditingController();
  String _filterCity = '';
  String _filterBloodGroup = '';
  String _searchQuery = '';

  static const _bloodGroups = ['A+', 'A−', 'B+', 'B−', 'AB+', 'AB−', 'O+', 'O−'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _tierLabel(BuildContext context, int pts) {
    final l10n = AppLocalizations.of(context)!;
    if (pts >= 2000) return l10n.tierPlatinum;
    if (pts >= 1000) return l10n.tierGold;
    if (pts >= 500) return l10n.tierSilver;
    return l10n.tierBronze;
  }

  Color _tierColor(int pts) {
    if (pts >= 2000) return const Color(0xFF00BCD4);
    if (pts >= 1000) return const Color(0xFFFFD700);
    if (pts >= 500) return const Color(0xFF9E9E9E);
    return const Color(0xFF8D6E63);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        SectionHeader(icon: Icons.people, color: _color, title: l10n.manageDonors, subtitle: l10n.totalDonors),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(controller: _searchCtrl, decoration: InputDecoration(hintText: l10n.searchDonors, prefixIcon: const Icon(Icons.search, size: 20), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300))), onChanged: (v) => setState(() => _searchQuery = v.toLowerCase())),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: HospitalService().watchCities(),
                  builder: (context, snap) {
                    final cities = snap.data ?? [];
                    return DropdownButtonFormField<String>(value: _filterCity.isEmpty ? null : _filterCity, decoration: InputDecoration(hintText: l10n.allCities, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300))), items: [DropdownMenuItem(value: '', child: Text(l10n.allCities)), ...cities.map((c) => DropdownMenuItem(value: c['name'] as String, child: Text(c['name'])))], onChanged: (v) => setState(() => _filterCity = v ?? ''));
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(value: _filterBloodGroup.isEmpty ? null : _filterBloodGroup, decoration: InputDecoration(hintText: l10n.allBloodGroups, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300))), items: [DropdownMenuItem(value: '', child: Text(l10n.allBloodGroups)), ..._bloodGroups.map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))], onChanged: (v) => setState(() => _filterBloodGroup = v ?? '')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: UserService().watchByRole('donor'),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              var docs = snapshot.data!;
              if (_filterCity.isNotEmpty) docs = docs.where((d) => (d['city'] ?? '').toString() == _filterCity).toList();
              if (_filterBloodGroup.isNotEmpty) docs = docs.where((d) => (d['bloodGroup'] ?? '').toString() == _filterBloodGroup).toList();
              if (_searchQuery.isNotEmpty) docs = docs.where((d) => (d['name'] ?? '').toString().toLowerCase().contains(_searchQuery) || (d['email'] ?? '').toString().toLowerCase().contains(_searchQuery)).toList();
              if (docs.isEmpty) return EmptyState(icon: Icons.people_outline, message: l10n.noDonorsFound);

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final donor = docs[i];
                  final name = donor['name'] ?? '—';
                  final email = donor['email'] ?? '—';
                  final city = donor['city'] ?? '—';
                  final bg = donor['bloodGroup'] ?? '?';
                  final pts = (donor['points'] ?? 0) as int;
                  final tier = _tierLabel(context, pts);
                  final tierColor = _tierColor(pts);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          CircleAvatar(radius: 22, backgroundColor: _color.withOpacity(0.1), child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: _color, fontWeight: FontWeight.bold, fontSize: 16))),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text(email, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                const SizedBox(height: 4),
                                Row(children: [const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey), Text(city, style: const TextStyle(fontSize: 11)), const SizedBox(width: 8), const Icon(Icons.stars_outlined, size: 12, color: Colors.amber), Text('$pts pts', style: const TextStyle(fontSize: 11))]),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(children: [BloodGroupBadge(bloodGroup: bg), const SizedBox(height: 4), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: tierColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Text(tier, style: TextStyle(fontSize: 10, color: tierColor, fontWeight: FontWeight.bold)))]),
                          const SizedBox(width: 8),
                          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () async {
                            final confirmed = await confirmDelete(context, l10n.confirmDeleteBody);
                            if (confirmed == true) await UserService().deleteById(donor['id'] as String);
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

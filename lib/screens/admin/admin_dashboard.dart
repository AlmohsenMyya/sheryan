import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/services/auth_service.dart';
import 'package:sheryan/services/notification_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MAIN DASHBOARD
// ─────────────────────────────────────────────────────────────────────────────

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  static const _sectionIcons = [
    Icons.dashboard_outlined,
    Icons.admin_panel_settings_outlined,
    Icons.local_hospital_outlined,
    Icons.location_city_outlined,
    Icons.store_outlined,
    Icons.people_outlined,
    Icons.bloodtype_outlined,
    Icons.campaign_outlined,
  ];

  static const _sectionColors = [
    Color(0xFF1565C0),
    Color(0xFF6A1B9A),
    Color(0xFF00838F),
    Color(0xFF2E7D32),
    Color(0xFFE65100),
    AppColors.primaryRed,
    Color(0xFF6A1B9A),
    Color(0xFFF57F17),
  ];

  Widget _buildBody() {
    return switch (_selectedIndex) {
      0 => const _AdminOverview(),
      1 => const HospitalAdminManager(),
      2 => const HospitalManager(),
      3 => const CityManager(),
      4 => const SponsorOrgManager(),
      5 => const _DonorManager(),
      6 => const _BloodRequestsAdmin(),
      7 => const _BroadcastNotif(),
      _ => const _AdminOverview(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isWide = MediaQuery.of(context).size.width > 750;

    final labels = [
      l10n.adminOverview,
      l10n.manageHospitalAdmins,
      l10n.manageHospitals,
      l10n.manageCities,
      l10n.manageSponsorOrgs,
      l10n.manageDonors,
      l10n.allBloodRequests,
      l10n.broadcastNotif,
    ];

    return Scaffold(
      body: Row(
        children: [
          _AdminSidebar(
            selectedIndex: _selectedIndex,
            onSelect: (i) => setState(() => _selectedIndex = i),
            labels: labels,
            icons: _sectionIcons,
            colors: _sectionColors,
            isWide: isWide,
          ),
          Container(width: 1, color: Colors.grey.shade200),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}

// Custom sidebar — avoids NavigationRail's ImplicitlyAnimatedWidget internals
class _AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<String> labels;
  final List<IconData> icons;
  final List<Color> colors;
  final bool isWide;

  const _AdminSidebar({
    required this.selectedIndex,
    required this.onSelect,
    required this.labels,
    required this.icons,
    required this.colors,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    final sideWidth = isWide ? 210.0 : 68.0;

    return Container(
      width: sideWidth,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Logo + label
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.shield,
                      color: Colors.white, size: 26),
                ),
                if (isWide) ...[
                  const SizedBox(height: 6),
                  Text(
                    AppLocalizations.of(context)!.superAdminLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryRed,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(height: 1, color: Colors.grey.shade100),
          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: icons.length,
              itemBuilder: (ctx, i) {
                final isSelected = i == selectedIndex;
                final itemColor = isSelected ? colors[i] : Colors.grey[600]!;
                return GestureDetector(
                  onTap: () => onSelect(i),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 12 : 0,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors[i].withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? Border.all(color: colors[i].withOpacity(0.25))
                          : null,
                    ),
                    child: isWide
                        ? Row(
                            children: [
                              const SizedBox(width: 4),
                              Icon(icons[i], color: itemColor, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  labels[i],
                                  style: TextStyle(
                                    color: itemColor,
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        : Center(
                            child: Icon(icons[i], color: itemColor, size: 22),
                          ),
                  ),
                );
              },
            ),
          ),
          // Logout
          Container(height: 1, color: Colors.grey.shade100),
          GestureDetector(
            onTap: () async => await AuthService().logoutUser(),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: isWide
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded,
                            color: Colors.grey[500], size: 18),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.logout,
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 13),
                        ),
                      ],
                    )
                  : Icon(Icons.logout_rounded,
                      color: Colors.grey[500], size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED HELPERS
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget? action;

  const _SectionHeader({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        border: Border(bottom: BorderSide(color: color.withOpacity(0.15))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey[600])),
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message,
              style: TextStyle(color: Colors.grey[500], fontSize: 15)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String label;
    switch (status) {
      case 'done':
      case 'completed':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        label = AppLocalizations.of(context)!.statusDone;
      case 'verified':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        label = AppLocalizations.of(context)!.statusVerified;
      default:
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade700;
        label = AppLocalizations.of(context)!.statusPending;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _BloodGroupBadge extends StatelessWidget {
  final String bloodGroup;
  const _BloodGroupBadge(this.bloodGroup);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryRed.withOpacity(0.3)),
      ),
      child: Text(bloodGroup,
          style: const TextStyle(
              color: AppColors.primaryRed,
              fontSize: 12,
              fontWeight: FontWeight.bold)),
    );
  }
}

Future<bool?> _confirmDelete(BuildContext context, String body) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.red),
        const SizedBox(width: 8),
        Text(l10n.delete),
      ]),
      content: Text(body),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.yesDelete),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 0 — OVERVIEW / STATS
// ─────────────────────────────────────────────────────────────────────────────

class _AdminOverview extends StatelessWidget {
  const _AdminOverview();

  Stream<int> _count(Query q) =>
      q.snapshots().map((s) => s.docs.length);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fs = FirebaseFirestore.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          icon: Icons.dashboard,
          color: const Color(0xFF1565C0),
          title: l10n.adminOverview,
          subtitle: l10n.adminDashboard,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stat cards row
                LayoutBuilder(builder: (context, constraints) {
                  final crossAxis =
                      constraints.maxWidth > 600 ? 4 : 2;
                  return GridView.count(
                    crossAxisCount: crossAxis,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _StatCard(
                        icon: Icons.people,
                        color: AppColors.primaryRed,
                        label: l10n.totalDonors,
                        countStream: _count(fs
                            .collection('users')
                            .where('role', isEqualTo: 'donor')),
                      ),
                      _StatCard(
                        icon: Icons.local_hospital,
                        color: const Color(0xFF00838F),
                        label: l10n.totalHospitals,
                        countStream: _count(fs.collection('hospitals')),
                      ),
                      _StatCard(
                        icon: Icons.bloodtype,
                        color: const Color(0xFF6A1B9A),
                        label: l10n.openRequests,
                        countStream: _count(fs
                            .collection('blood_requests')
                            .where('status', isEqualTo: 'pending')),
                      ),
                      _StatCard(
                        icon: Icons.favorite,
                        color: const Color(0xFF2E7D32),
                        label: l10n.totalDonations,
                        countStream: _count(fs.collection('donations')),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 28),
                Text(l10n.announcementHistory,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: fs
                      .collection('announcements')
                      .orderBy('createdAt', descending: true)
                      .limit(5)
                      .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snap.data!.docs;
                    if (docs.isEmpty) {
                      return _EmptyState(
                          icon: Icons.campaign_outlined,
                          message: l10n.noAnnouncementsYet);
                    }
                    return Column(
                      children: docs.map((d) {
                        final ts = d['createdAt'] as Timestamp?;
                        final date = ts != null
                            ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}'
                            : '—';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                                color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFFFF8E1),
                              child: Icon(Icons.campaign,
                                  color: Color(0xFFF57F17)),
                            ),
                            title: Text(d['title'] ?? '—',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(d['body'] ?? ''),
                            trailing: Text(date,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[500])),
                          ),
                        );
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final Stream<int> countStream;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.countStream,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              StreamBuilder<int>(
                stream: countStream,
                builder: (ctx, snap) {
                  return Text(
                    snap.hasData ? snap.data!.toString() : '…',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  );
                },
              ),
            ],
          ),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 1 — HOSPITAL ADMIN MANAGER
// ─────────────────────────────────────────────────────────────────────────────

class HospitalAdminManager extends StatefulWidget {
  const HospitalAdminManager({super.key});

  @override
  State<HospitalAdminManager> createState() => _HospitalAdminManagerState();
}

class _HospitalAdminManagerState extends State<HospitalAdminManager> {
  final AuthService _auth = AuthService();
  static const _color = Color(0xFF6A1B9A);

  void _showCreateDialog() {
    final formKey = GlobalKey<FormState>();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String? selectedHospitalId;
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final l10n = AppLocalizations.of(ctx)!;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(l10n.createAdmin),
            content: SizedBox(
              width: 400,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                            labelText: l10n.fullName,
                            prefixIcon: const Icon(Icons.person_outline)),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? l10n.requiredField : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailCtrl,
                        decoration: InputDecoration(
                            labelText: l10n.email,
                            prefixIcon: const Icon(Icons.email_outlined)),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? l10n.requiredField : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passwordCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                            labelText: l10n.password,
                            prefixIcon: const Icon(Icons.lock_outline)),
                        validator: (v) =>
                            (v == null || v.length < 6) ? l10n.passwordMinLength : null,
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('hospitals')
                            .orderBy('name')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const LinearProgressIndicator();
                          }
                          final hospitals = snapshot.data!.docs;
                          return DropdownButtonFormField<String>(
                            value: selectedHospitalId,
                            decoration: InputDecoration(
                                labelText: l10n.hospitalName,
                                prefixIcon:
                                    const Icon(Icons.local_hospital_outlined)),
                            items: hospitals
                                .map((h) => DropdownMenuItem(
                                    value: h.id, child: Text(h['name'])))
                                .toList(),
                            onChanged: (v) =>
                                setS(() => selectedHospitalId = v),
                            validator: (v) =>
                                v == null ? l10n.requiredField : null,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel)),
              FilledButton(
                onPressed: loading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate() ||
                            selectedHospitalId == null) return;
                        setS(() => loading = true);
                        try {
                          final ok = await _auth.registerUser(
                            name: nameCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            password: passwordCtrl.text,
                            bloodGroup: '',
                            city: '',
                            role: 'hospitalAdmin',
                            phone: '',
                            hospitalId: selectedHospitalId,
                          );
                          if (ok && ctx.mounted) {
                            Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(l10n.adminCreated)));
                            }
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())));
                          }
                        } finally {
                          if (ctx.mounted) setS(() => loading = false);
                        }
                      },
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(l10n.createAdmin),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditDialog(DocumentSnapshot admin) {
    final nameCtrl = TextEditingController(text: admin['name']);
    String? hospitalId = admin['hospitalId'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final l10n = AppLocalizations.of(ctx)!;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(l10n.editAdmin),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration:
                        InputDecoration(labelText: l10n.fullName),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('hospitals')
                        .orderBy('name')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const LinearProgressIndicator();
                      }
                      final hospitals = snapshot.data!.docs;
                      return DropdownButtonFormField<String>(
                        value: hospitalId,
                        decoration: InputDecoration(
                            labelText: l10n.hospitalName),
                        items: hospitals
                            .map((h) => DropdownMenuItem(
                                value: h.id, child: Text(h['name'])))
                            .toList(),
                        onChanged: (v) => setS(() => hospitalId = v),
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel)),
              FilledButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(admin.id)
                      .update({
                    'name': nameCtrl.text.trim(),
                    'hospitalId': hospitalId,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.adminUpdated)));
                  }
                },
                child: Text(l10n.saveChanges),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteAdmin(String uid) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _confirmDelete(context, l10n.confirmDeleteBody);
    if (confirmed != true) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).delete();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.adminDeleted)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        _SectionHeader(
          icon: Icons.admin_panel_settings,
          color: _color,
          title: l10n.manageHospitalAdmins,
          subtitle: l10n.manageHospitalAdminsSubtitle,
          action: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: _color),
            onPressed: _showCreateDialog,
            icon: const Icon(Icons.add),
            label: Text(l10n.createAdmin),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'hospitalAdmin')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return _EmptyState(
                    icon: Icons.admin_panel_settings_outlined,
                    message: l10n.noAdminsFound);
              }
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: _color.withOpacity(0.12),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                              color: _color, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(email,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600])),
                          if (hospitalId != null && hospitalId.isNotEmpty)
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('hospitals')
                                  .doc(hospitalId)
                                  .get(),
                              builder: (_, snap) {
                                final hName =
                                    snap.data?.get('name') as String? ?? '…';
                                return Row(children: [
                                  Icon(Icons.local_hospital_outlined,
                                      size: 11,
                                      color: _color.withOpacity(0.7)),
                                  const SizedBox(width: 3),
                                  Text(hName,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: _color.withOpacity(0.85))),
                                ]);
                              },
                            ),
                        ],
                      ),
                      isThreeLine: hospitalId != null && hospitalId.isNotEmpty,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit_outlined, color: _color),
                            onPressed: () => _showEditDialog(admin),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () => _deleteAdmin(admin.id),
                          ),
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

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 2 — HOSPITAL MANAGER
// ─────────────────────────────────────────────────────────────────────────────

class HospitalManager extends StatefulWidget {
  const HospitalManager({super.key});

  @override
  State<HospitalManager> createState() => _HospitalManagerState();
}

class _HospitalManagerState extends State<HospitalManager> {
  static const _color = Color(0xFF00838F);
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    String? selectedCity;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final l10n = AppLocalizations.of(ctx)!;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(l10n.addHospital),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                        labelText: l10n.hospitalName,
                        prefixIcon: const Icon(Icons.local_hospital_outlined)),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: _fs
                        .collection('cities')
                        .orderBy('name')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const LinearProgressIndicator();
                      }
                      final cities = snapshot.data!.docs;
                      return DropdownButtonFormField<String>(
                        value: selectedCity,
                        hint: Text(l10n.selectCity),
                        decoration: InputDecoration(
                            labelText: l10n.city,
                            prefixIcon:
                                const Icon(Icons.location_city_outlined)),
                        items: cities
                            .map((c) => DropdownMenuItem(
                                value: c['name'] as String,
                                child: Text(c['name'])))
                            .toList(),
                        onChanged: (v) => setS(() => selectedCity = v),
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel)),
              FilledButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty || selectedCity == null) return;
                  await _fs.collection('hospitals').add({
                    'name': name,
                    'city': selectedCity,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.hospitalAdded)));
                  }
                },
                child: Text(l10n.addHospital),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditDialog(DocumentSnapshot hospital) {
    final nameCtrl = TextEditingController(text: hospital['name']);
    String? selectedCity = hospital['city'] as String?;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final l10n = AppLocalizations.of(ctx)!;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(l10n.editHospital),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration:
                        InputDecoration(labelText: l10n.hospitalName),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: _fs
                        .collection('cities')
                        .orderBy('name')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const LinearProgressIndicator();
                      }
                      final cities = snapshot.data!.docs;
                      return DropdownButtonFormField<String>(
                        value: selectedCity,
                        items: cities
                            .map((c) => DropdownMenuItem(
                                value: c['name'] as String,
                                child: Text(c['name'])))
                            .toList(),
                        onChanged: (v) => setS(() => selectedCity = v),
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel)),
              FilledButton(
                onPressed: () async {
                  await _fs
                      .collection('hospitals')
                      .doc(hospital.id)
                      .update({
                    'name': nameCtrl.text.trim(),
                    'city': selectedCity,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.hospitalUpdated)));
                  }
                },
                child: Text(l10n.saveChanges),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteHospital(String id) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _confirmDelete(context, l10n.confirmDeleteBody);
    if (confirmed != true) return;
    await _fs.collection('hospitals').doc(id).delete();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.hospitalDeleted)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        _SectionHeader(
          icon: Icons.local_hospital,
          color: _color,
          title: l10n.manageHospitals,
          subtitle: l10n.addHospital,
          action: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: _color),
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add),
            label: Text(l10n.addHospital),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _fs.collection('hospitals').orderBy('name').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return _EmptyState(
                    icon: Icons.local_hospital_outlined,
                    message: l10n.noHospitalsFound);
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final h = docs[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: _color.withOpacity(0.12),
                        child: Icon(Icons.local_hospital,
                            color: _color, size: 20),
                      ),
                      title: Text(h['name'],
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Row(children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(h['city'] ?? '—',
                            style: const TextStyle(fontSize: 12)),
                      ]),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit_outlined, color: _color),
                            onPressed: () => _showEditDialog(h),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () => _deleteHospital(h.id),
                          ),
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

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 3 — CITY MANAGER
// ─────────────────────────────────────────────────────────────────────────────

class CityManager extends StatefulWidget {
  const CityManager({super.key});

  @override
  State<CityManager> createState() => _CityManagerState();
}

class _CityManagerState extends State<CityManager> {
  static const _color = Color(0xFF2E7D32);
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  void _showAddDialog() {
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n.addCity),
          content: TextFormField(
            controller: nameCtrl,
            autofocus: true,
            decoration: InputDecoration(
                labelText: l10n.cityName,
                prefixIcon: const Icon(Icons.location_city_outlined)),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel)),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                await _fs.collection('cities').add({'name': name});
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.cityAdded)));
                }
              },
              child: Text(l10n.addCity),
            ),
          ],
        );
      },
    );
  }

  void _showEditCityDialog(DocumentSnapshot city) {
    final nameCtrl = TextEditingController(text: city['name'] as String?);

    showDialog(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n.editCity),
          content: TextFormField(
            controller: nameCtrl,
            autofocus: true,
            decoration: InputDecoration(
                labelText: l10n.cityName,
                prefixIcon: const Icon(Icons.location_city_outlined)),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel)),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                await _fs
                    .collection('cities')
                    .doc(city.id)
                    .update({'name': name});
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.cityUpdated)));
                }
              },
              child: Text(l10n.saveChanges),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCity(String id) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _confirmDelete(context, l10n.confirmDeleteBody);
    if (confirmed != true) return;
    await _fs.collection('cities').doc(id).delete();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.cityDeleted)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        _SectionHeader(
          icon: Icons.location_city,
          color: _color,
          title: l10n.manageCities,
          subtitle: l10n.addCity,
          action: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: _color),
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add),
            label: Text(l10n.addCity),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _fs.collection('cities').orderBy('name').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return _EmptyState(
                    icon: Icons.location_city_outlined,
                    message: l10n.noCitiesFound);
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final city = docs[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _color.withOpacity(0.12),
                        child: Icon(Icons.location_city,
                            color: _color, size: 20),
                      ),
                      title: Text(city['name'],
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit_outlined, color: _color),
                            onPressed: () => _showEditCityDialog(city),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () => _deleteCity(city.id),
                          ),
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

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 4 — SPONSOR ORG MANAGER
// ─────────────────────────────────────────────────────────────────────────────

class SponsorOrgManager extends StatefulWidget {
  const SponsorOrgManager({super.key});

  @override
  State<SponsorOrgManager> createState() => _SponsorOrgManagerState();
}

class _SponsorOrgManagerState extends State<SponsorOrgManager> {
  static const _color = Color(0xFFE65100);
  final AuthService _auth = AuthService();

  void _showCreateDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String? selectedCity;
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final l10n = AppLocalizations.of(ctx)!;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(l10n.createSponsor),
            content: SizedBox(
              width: 400,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                            labelText: l10n.sponsorOrgName,
                            prefixIcon: const Icon(Icons.store_outlined)),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? l10n.requiredField : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailCtrl,
                        decoration: InputDecoration(
                            labelText: l10n.email,
                            prefixIcon: const Icon(Icons.email_outlined)),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? l10n.requiredField : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                            labelText: l10n.password,
                            prefixIcon: const Icon(Icons.lock_outline)),
                        validator: (v) =>
                            (v == null || v.length < 6) ? l10n.passwordMinLength : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneCtrl,
                        decoration: InputDecoration(
                            labelText: l10n.sponsorPhone,
                            prefixIcon: const Icon(Icons.phone_outlined)),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? l10n.requiredField : null,
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('cities')
                            .orderBy('name')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const LinearProgressIndicator();
                          }
                          final cities = snapshot.data!.docs;
                          return DropdownButtonFormField<String>(
                            value: selectedCity,
                            hint: Text(l10n.selectCity),
                            decoration: InputDecoration(
                                prefixIcon:
                                    const Icon(Icons.location_city_outlined)),
                            items: cities
                                .map((c) => DropdownMenuItem(
                                    value: c['name'] as String,
                                    child: Text(c['name'])))
                                .toList(),
                            onChanged: (v) => setS(() => selectedCity = v),
                            validator: (v) =>
                                v == null ? l10n.requiredField : null,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel)),
              FilledButton(
                onPressed: loading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate() ||
                            selectedCity == null) return;
                        setS(() => loading = true);
                        try {
                          final ok = await _auth.registerUser(
                            name: nameCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            password: passCtrl.text,
                            bloodGroup: '',
                            city: selectedCity!,
                            role: 'sponsorOrg',
                            phone: phoneCtrl.text.trim(),
                          );
                          if (ok && ctx.mounted) {
                            Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(l10n.sponsorCreated)));
                            }
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())));
                          }
                        } finally {
                          if (ctx.mounted) setS(() => loading = false);
                        }
                      },
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(l10n.createSponsor),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditSponsorDialog(DocumentSnapshot sponsor) {
    final nameCtrl =
        TextEditingController(text: sponsor['name'] as String? ?? '');
    String? selectedCity = sponsor['city'] as String?;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final l10n = AppLocalizations.of(ctx)!;
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(l10n.editSponsor),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                        labelText: l10n.sponsorOrgName,
                        prefixIcon: const Icon(Icons.store_outlined)),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('cities')
                        .orderBy('name')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const LinearProgressIndicator();
                      }
                      final cities = snapshot.data!.docs;
                      return DropdownButtonFormField<String>(
                        value: selectedCity,
                        decoration: InputDecoration(
                            labelText: l10n.city,
                            prefixIcon:
                                const Icon(Icons.location_city_outlined)),
                        items: cities
                            .map((c) => DropdownMenuItem(
                                value: c['name'] as String,
                                child: Text(c['name'])))
                            .toList(),
                        onChanged: (v) => setS(() => selectedCity = v),
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel)),
              FilledButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(sponsor.id)
                      .update({'name': name, 'city': selectedCity});
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.sponsorUpdated)));
                  }
                },
                child: Text(l10n.saveChanges),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteSponsor(String uid) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _confirmDelete(context, l10n.confirmDeleteBody);
    if (confirmed != true) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).delete();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.sponsorDeleted)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        _SectionHeader(
          icon: Icons.store,
          color: _color,
          title: l10n.manageSponsorOrgs,
          subtitle: l10n.createSponsor,
          action: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: _color),
            onPressed: _showCreateDialog,
            icon: const Icon(Icons.add),
            label: Text(l10n.createSponsor),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'sponsorOrg')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return _EmptyState(
                    icon: Icons.store_outlined,
                    message: l10n.noSponsorsFound);
              }
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: _color.withOpacity(0.12),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                              color: _color, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Row(children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(city,
                            style: const TextStyle(fontSize: 12)),
                      ]),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit_outlined, color: _color),
                            onPressed: () => _showEditSponsorDialog(sponsor),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () => _deleteSponsor(sponsor.id),
                          ),
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

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 5 — DONOR MANAGER (NEW)
// ─────────────────────────────────────────────────────────────────────────────

class _DonorManager extends StatefulWidget {
  const _DonorManager();

  @override
  State<_DonorManager> createState() => _DonorManagerState();
}

class _DonorManagerState extends State<_DonorManager> {
  static const _color = AppColors.primaryRed;
  final _searchCtrl = TextEditingController();
  String _filterCity = '';
  String _filterBloodGroup = '';
  String _searchQuery = '';

  static const _bloodGroups = [
    'A+', 'A−', 'B+', 'B−', 'AB+', 'AB−', 'O+', 'O−',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _deleteDonor(String uid) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _confirmDelete(context, l10n.confirmDeleteBody);
    if (confirmed != true) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).delete();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.donorDeleted)));
    }
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
        _SectionHeader(
          icon: Icons.people,
          color: _color,
          title: l10n.manageDonors,
          subtitle: l10n.totalDonors,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: l10n.searchDonors,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                  onChanged: (v) =>
                      setState(() => _searchQuery = v.toLowerCase()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('cities')
                      .orderBy('name')
                      .snapshots(),
                  builder: (context, snap) {
                    final cities = snap.data?.docs ?? [];
                    return DropdownButtonFormField<String>(
                      value: _filterCity.isEmpty ? null : _filterCity,
                      decoration: InputDecoration(
                        hintText: l10n.allCities,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: Colors.grey.shade300)),
                      ),
                      items: [
                        DropdownMenuItem(
                            value: '',
                            child: Text(l10n.allCities)),
                        ...cities.map((c) => DropdownMenuItem(
                            value: c['name'] as String,
                            child: Text(c['name']))),
                      ],
                      onChanged: (v) =>
                          setState(() => _filterCity = v ?? ''),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _filterBloodGroup.isEmpty
                      ? null
                      : _filterBloodGroup,
                  decoration: InputDecoration(
                    hintText: l10n.allBloodGroups,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Colors.grey.shade300)),
                  ),
                  items: [
                    DropdownMenuItem(
                        value: '',
                        child: Text(l10n.allBloodGroups)),
                    ..._bloodGroups.map((bg) =>
                        DropdownMenuItem(value: bg, child: Text(bg))),
                  ],
                  onChanged: (v) =>
                      setState(() => _filterBloodGroup = v ?? ''),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'donor')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              var docs = snapshot.data!.docs;

              // Client-side filters
              if (_filterCity.isNotEmpty) {
                docs = docs
                    .where((d) =>
                        (d['city'] ?? '').toString() == _filterCity)
                    .toList();
              }
              if (_filterBloodGroup.isNotEmpty) {
                docs = docs
                    .where((d) =>
                        (d['bloodGroup'] ?? '').toString() ==
                        _filterBloodGroup)
                    .toList();
              }
              if (_searchQuery.isNotEmpty) {
                docs = docs
                    .where((d) =>
                        (d['name'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(_searchQuery) ||
                        (d['email'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(_searchQuery))
                    .toList();
              }

              if (docs.isEmpty) {
                return _EmptyState(
                    icon: Icons.people_outline,
                    message: l10n.noDonorsFound);
              }

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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: _color.withOpacity(0.1),
                            child: Text(
                              name.isNotEmpty
                                  ? name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  color: _color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                Text(email,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600])),
                                const SizedBox(height: 4),
                                Row(children: [
                                  const Icon(Icons.location_on_outlined,
                                      size: 12, color: Colors.grey),
                                  Text(city,
                                      style: const TextStyle(fontSize: 11)),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.stars_outlined,
                                      size: 12, color: Colors.amber),
                                  Text('$pts pts',
                                      style: const TextStyle(fontSize: 11)),
                                ]),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            children: [
                              _BloodGroupBadge(bg),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: tierColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(tier,
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: tierColor,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () => _deleteDonor(donor.id),
                          ),
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

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 6 — BLOOD REQUESTS ADMIN (NEW)
// ─────────────────────────────────────────────────────────────────────────────

class _BloodRequestsAdmin extends StatefulWidget {
  const _BloodRequestsAdmin();

  @override
  State<_BloodRequestsAdmin> createState() => _BloodRequestsAdminState();
}

class _BloodRequestsAdminState extends State<_BloodRequestsAdmin> {
  static const _color = Color(0xFF6A1B9A);
  String _filterStatus = '';

  Future<void> _deleteRequest(String id) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _confirmDelete(context, l10n.confirmDeleteBody);
    if (confirmed != true) return;
    await FirebaseFirestore.instance
        .collection('blood_requests')
        .doc(id)
        .delete();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.requestDeletedSuccess)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        _SectionHeader(
          icon: Icons.bloodtype,
          color: _color,
          title: l10n.allBloodRequests,
          subtitle: l10n.openRequests,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                    label: l10n.allStatuses,
                    selected: _filterStatus.isEmpty,
                    color: _color,
                    onTap: () => setState(() => _filterStatus = '')),
                const SizedBox(width: 8),
                _FilterChip(
                    label: l10n.statusPending,
                    selected: _filterStatus == 'pending',
                    color: Colors.orange,
                    onTap: () =>
                        setState(() => _filterStatus = 'pending')),
                const SizedBox(width: 8),
                _FilterChip(
                    label: l10n.statusVerified,
                    selected: _filterStatus == 'verified',
                    color: Colors.blue,
                    onTap: () =>
                        setState(() => _filterStatus = 'verified')),
                const SizedBox(width: 8),
                _FilterChip(
                    label: l10n.statusDone,
                    selected: _filterStatus == 'done',
                    color: Colors.green,
                    onTap: () => setState(() => _filterStatus = 'done')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _filterStatus.isEmpty
                ? FirebaseFirestore.instance
                    .collection('blood_requests')
                    .orderBy('createdAt', descending: true)
                    .snapshots()
                : _filterStatus == 'done'
                    ? FirebaseFirestore.instance
                        .collection('blood_requests')
                        .where('status', whereIn: ['done', 'completed'])
                        .orderBy('createdAt', descending: true)
                        .snapshots()
                    : FirebaseFirestore.instance
                        .collection('blood_requests')
                        .where('status', isEqualTo: _filterStatus)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return _EmptyState(
                    icon: Icons.bloodtype_outlined,
                    message: l10n.noBloodRequestsFound);
              }
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
                  final date = ts != null
                      ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}'
                      : '—';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          _BloodGroupBadge(bg),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(patient,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Row(children: [
                                  const Icon(Icons.local_hospital_outlined,
                                      size: 12, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(hospital,
                                      style: const TextStyle(fontSize: 11)),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.location_on_outlined,
                                      size: 12, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(city,
                                      style: const TextStyle(fontSize: 11)),
                                ]),
                                Text(date,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500])),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(status),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () => _deleteRequest(req.id),
                          ),
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

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : color.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 7 — BROADCAST NOTIFICATIONS (NEW)
// ─────────────────────────────────────────────────────────────────────────────

class _BroadcastNotif extends StatefulWidget {
  const _BroadcastNotif();

  @override
  State<_BroadcastNotif> createState() => _BroadcastNotifState();
}

class _BroadcastNotifState extends State<_BroadcastNotif> {
  static const _color = Color(0xFFF57F17);
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _target = 'all';
  String? _targetCity;
  String? _targetBloodGroup;
  bool _sending = false;

  static const _bloodGroups = [
    'A+', 'A−', 'B+', 'B−', 'AB+', 'AB−', 'O+', 'O−',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    final l10n = AppLocalizations.of(context)!;

    try {
      // Save to Firestore announcements collection
      await FirebaseFirestore.instance.collection('announcements').add({
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
        'target': _target,
        'targetCity': _targetCity,
        'targetBloodGroup': _targetBloodGroup,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Attempt push delivery via NotificationService
      if (_target == 'city' && _targetCity != null) {
        await NotificationService().sendEmergencyNotification(
          city: _targetCity!,
          bloodGroup: _targetBloodGroup ?? '',
          requestId: 'broadcast_${DateTime.now().millisecondsSinceEpoch}',
        );
      } else if (_target == 'bloodGroup' && _targetBloodGroup != null) {
        await NotificationService().sendEmergencyNotification(
          city: '',
          bloodGroup: _targetBloodGroup!,
          requestId: 'broadcast_${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      if (mounted) {
        _titleCtrl.clear();
        _bodyCtrl.clear();
        setState(() {
          _target = 'all';
          _targetCity = null;
          _targetBloodGroup = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.notifSent),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        _SectionHeader(
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
                // Compose form
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(l10n.sendNotif,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _titleCtrl,
                            decoration: InputDecoration(
                              labelText: l10n.notifTitleField,
                              prefixIcon:
                                  const Icon(Icons.title_outlined),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            validator: (v) =>
                                (v == null || v.isEmpty)
                                    ? l10n.requiredField
                                    : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _bodyCtrl,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: l10n.notifBodyField,
                              prefixIcon:
                                  const Icon(Icons.message_outlined),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            validator: (v) =>
                                (v == null || v.isEmpty)
                                    ? l10n.requiredField
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          Text(l10n.targetAudience,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                          const SizedBox(height: 8),
                          // Target selector
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _FilterChip(
                                label: l10n.targetAll,
                                selected: _target == 'all',
                                color: _color,
                                onTap: () =>
                                    setState(() => _target = 'all'),
                              ),
                              _FilterChip(
                                label: l10n.targetByCity,
                                selected: _target == 'city',
                                color: _color,
                                onTap: () =>
                                    setState(() => _target = 'city'),
                              ),
                              _FilterChip(
                                label: l10n.targetByBloodGroup,
                                selected: _target == 'bloodGroup',
                                color: _color,
                                onTap: () =>
                                    setState(() => _target = 'bloodGroup'),
                              ),
                            ],
                          ),
                          if (_target == 'city') ...[
                            const SizedBox(height: 12),
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('cities')
                                  .orderBy('name')
                                  .snapshots(),
                              builder: (context, snap) {
                                final cities = snap.data?.docs ?? [];
                                return DropdownButtonFormField<String>(
                                  value: _targetCity,
                                  hint: Text(l10n.selectCity),
                                  decoration: InputDecoration(
                                    labelText: l10n.city,
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                  items: cities
                                      .map((c) => DropdownMenuItem(
                                          value: c['name'] as String,
                                          child: Text(c['name'])))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _targetCity = v),
                                  validator: (v) =>
                                      v == null ? l10n.requiredField : null,
                                );
                              },
                            ),
                          ],
                          if (_target == 'bloodGroup') ...[
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _targetBloodGroup,
                              hint: Text(l10n.allBloodGroups),
                              decoration: InputDecoration(
                                labelText: l10n.bloodGroup,
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(10)),
                              ),
                              items: _bloodGroups
                                  .map((bg) => DropdownMenuItem(
                                      value: bg, child: Text(bg)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _targetBloodGroup = v),
                              validator: (v) =>
                                  v == null ? l10n.requiredField : null,
                            ),
                          ],
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                                backgroundColor: _color,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14)),
                            onPressed: _sending ? null : _sendNotification,
                            icon: _sending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.send_rounded),
                            label: Text(l10n.sendNotif,
                                style: const TextStyle(fontSize: 15)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // History
                Text(l10n.announcementHistory,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('announcements')
                      .orderBy('createdAt', descending: true)
                      .limit(20)
                      .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snap.data!.docs;
                    if (docs.isEmpty) {
                      return _EmptyState(
                          icon: Icons.campaign_outlined,
                          message: l10n.noAnnouncementsYet);
                    }
                    return Column(
                      children: docs.map((d) {
                        final ts = d['createdAt'] as Timestamp?;
                        final date = ts != null
                            ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year} ${ts.toDate().hour}:${ts.toDate().minute.toString().padLeft(2, '0')}'
                            : '—';
                        final target = d['target'] ?? 'all';
                        final targetCity = d['targetCity'] ?? '';
                        final targetBg = d['targetBloodGroup'] ?? '';
                        String targetLabel = l10n.targetAll;
                        if (target == 'city' && targetCity.isNotEmpty) {
                          targetLabel = '${l10n.city}: $targetCity';
                        } else if (target == 'bloodGroup' &&
                            targetBg.isNotEmpty) {
                          targetLabel = '${l10n.bloodGroup}: $targetBg';
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _color.withOpacity(0.12),
                              child:
                                  Icon(Icons.campaign, color: _color),
                            ),
                            title: Text(d['title'] ?? '—',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(d['body'] ?? ''),
                                Row(children: [
                                  Icon(Icons.people_outline,
                                      size: 12,
                                      color: _color.withOpacity(0.7)),
                                  const SizedBox(width: 4),
                                  Text(targetLabel,
                                      style: TextStyle(
                                          fontSize: 11, color: _color)),
                                ]),
                              ],
                            ),
                            trailing: Text(date,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[500])),
                          ),
                        );
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

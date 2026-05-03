import 'package:sheryan/events/app_event.dart';
import 'package:sheryan/events/notification_engine.dart';
import 'package:sheryan/services/points_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/core/theme/app_design_constants.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/providers/auth/auth_provider.dart';

// ─── Main Dashboard ───────────────────────────────────────────────────────────

class HospitalDashboard extends ConsumerStatefulWidget {
  const HospitalDashboard({super.key});

  @override
  ConsumerState<HospitalDashboard> createState() => _HospitalDashboardState();
}

class _HospitalDashboardState extends ConsumerState<HospitalDashboard>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _openScanner(BuildContext context, {required bool isVerifyOnly}) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ScannerScreen(isVerifyOnly: isVerifyOnly)),
    );
  }

  void _openBloodGroupVerification(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => const BloodGroupVerificationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final adminProfile = ref.watch(userProfileProvider).value;
    final hospitalId = adminProfile?['hospitalId'] as String?;
    final hospitalName = adminProfile?['name'] as String? ?? '';
    final adminUid = adminProfile?['uid'] as String? ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.hospitalAdminDashboard),
        bottom: TabBar(
          controller: _tab,
          tabs: [
            Tab(icon: const Icon(Icons.list_alt), text: l10n.incomingRequests),
            Tab(icon: const Icon(Icons.history), text: l10n.donationHistory),
          ],
        ),
      ),
      body: hospitalId == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _StatsBar(hospitalId: hospitalId),
                Container(height: 1, color: Colors.grey.shade200),
                Expanded(
                  child: TabBarView(
                    controller: _tab,
                    children: [
                      _RequestsTab(
                        hospitalId: hospitalId,
                        hospitalName: hospitalName,
                        adminUid: adminUid,
                        onOpenScanner: (isVerifyOnly) =>
                            _openScanner(context, isVerifyOnly: isVerifyOnly),
                        onVerifyBloodGroup: () =>
                            _openBloodGroupVerification(context),
                      ),
                      _DonationHistoryTab(hospitalId: hospitalId),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Stats Bar ────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  final String hospitalId;
  const _StatsBar({required this.hospitalId});

  Stream<int> _count(Query q) => q.snapshots().map((s) => s.docs.length);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fs = FirebaseFirestore.instance;
    final base = fs
        .collection('blood_requests')
        .where('hospitalId', isEqualTo: hospitalId);

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          _HospitalStatCard(
            icon: Icons.assignment_outlined,
            color: const Color(0xFF1565C0),
            label: l10n.totalRequests,
            stream: _count(base),
          ),
          _HospitalStatCard(
            icon: Icons.pending_actions_outlined,
            color: Colors.orange,
            label: l10n.openRequests,
            stream: _count(base.where('status', isEqualTo: 'pending')),
          ),
          _HospitalStatCard(
            icon: Icons.verified_outlined,
            color: Colors.blue,
            label: l10n.verifiedLabel,
            stream: _count(base.where('isVerified', isEqualTo: true)),
          ),
          _HospitalStatCard(
            icon: Icons.check_circle_outline,
            color: AppColors.success,
            label: l10n.fulfilledLabel,
            stream: _count(
                base.where('status', whereIn: ['done', 'completed'])),
          ),
        ],
      ),
    );
  }
}

class _HospitalStatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final Stream<int> stream;

  const _HospitalStatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            StreamBuilder<int>(
              stream: stream,
              builder: (_, snap) => Text(
                snap.hasData ? snap.data!.toString() : '…',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Requests Tab ─────────────────────────────────────────────────────────────

class _RequestsTab extends StatelessWidget {
  final String hospitalId;
  final String hospitalName;
  final String adminUid;
  final void Function(bool isVerifyOnly) onOpenScanner;
  final VoidCallback onVerifyBloodGroup;

  const _RequestsTab({
    required this.hospitalId,
    required this.hospitalName,
    required this.adminUid,
    required this.onOpenScanner,
    required this.onVerifyBloodGroup,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  icon: Icons.verified_user,
                  label: l10n.verifyRequest,
                  color: Theme.of(context).colorScheme.primary,
                  onTap: () => onOpenScanner(true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionBtn(
                  icon: Icons.handshake,
                  label: l10n.registerDonation,
                  color: AppColors.success,
                  onTap: () => onOpenScanner(false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionBtn(
                  icon: Icons.bloodtype,
                  label: l10n.verifyDonorBloodGroup,
                  color: Colors.deepPurple,
                  onTap: onVerifyBloodGroup,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 1, color: Colors.grey.shade200),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('blood_requests')
                .where('hospitalId', isEqualTo: hospitalId)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined,
                          size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(l10n.noRequestsFound,
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 15)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final isDone = data['status'] == 'done' ||
                      data['status'] == 'completed';
                  final isVerified =
                      (data['isVerified'] ?? false) as bool;
                  final isUrgent = (data['isUrgent'] ?? false) as bool;

                  return _RequestCard(
                    doc: docs[i],
                    isDone: isDone,
                    isVerified: isVerified,
                    isUrgent: isUrgent,
                    hospitalName: hospitalName,
                    adminUid: adminUid,
                    hospitalId: hospitalId,
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

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
            borderRadius: AppDesignConstants.borderRadiusMedium),
      ),
      icon: Icon(icon, color: Colors.white, size: 16),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 11),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ─── Request Card ─────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final DocumentSnapshot doc;
  final bool isDone;
  final bool isVerified;
  final bool isUrgent;
  final String hospitalName;
  final String adminUid;
  final String hospitalId;

  const _RequestCard({
    required this.doc,
    required this.isDone,
    required this.isVerified,
    required this.isUrgent,
    required this.hospitalName,
    required this.adminUid,
    required this.hospitalId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = doc.data() as Map<String, dynamic>;
    final patientName = data['patientName'] ?? '—';
    final bloodGroup = data['bloodGroup'] ?? '?';
    final units = data['units']?.toString() ?? '1';
    final ts = data['createdAt'] as Timestamp?;
    final dateStr = ts != null
        ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}'
        : '—';

    final Color statusColor;
    final IconData statusIcon;
    if (isDone) {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle;
    } else if (isVerified) {
      statusColor = Colors.blue;
      statusIcon = Icons.verified;
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.pending;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isUrgent
              ? Colors.red.withOpacity(0.4)
              : Colors.grey.shade200,
          width: isUrgent ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetailSheet(context),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.primaryRed.withOpacity(0.3)),
                ),
                alignment: Alignment.center,
                child: Text(
                  bloodGroup,
                  style: const TextStyle(
                    color: AppColors.primaryRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            patientName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (isUrgent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: Colors.red.shade200),
                            ),
                            child: Text(
                              l10n.urgentLabel,
                              style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$bloodGroup • $units ${l10n.units}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      dateStr,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(statusIcon, color: statusColor, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RequestDetailSheet(
        doc: doc,
        isDone: isDone,
        isVerified: isVerified,
        hospitalName: hospitalName,
        adminUid: adminUid,
        hospitalId: hospitalId,
      ),
    );
  }
}

// ─── Request Detail Sheet ─────────────────────────────────────────────────────

class _RequestDetailSheet extends ConsumerStatefulWidget {
  final DocumentSnapshot doc;
  final bool isDone;
  final bool isVerified;
  final String hospitalName;
  final String adminUid;
  final String hospitalId;

  const _RequestDetailSheet({
    required this.doc,
    required this.isDone,
    required this.isVerified,
    required this.hospitalName,
    required this.adminUid,
    required this.hospitalId,
  });

  @override
  ConsumerState<_RequestDetailSheet> createState() =>
      _RequestDetailSheetState();
}

class _RequestDetailSheetState
    extends ConsumerState<_RequestDetailSheet> {
  bool _loading = false;

  Future<void> _markVerified() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _loading = true);
    try {
      final data = widget.doc.data() as Map<String, dynamic>;
      await widget.doc.reference.update({'isVerified': true});

      final requesterId = data['userId'] as String?;
      NotificationEngine().dispatch(BloodRequestVerifiedEvent(
        requestId: widget.doc.id,
        requesterId: requesterId,
        city: data['city'] ?? '',
        bloodGroup: data['bloodGroup'] ?? '',
      ));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.verifySuccess),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openManualFulfill() {
    showDialog(
      context: context,
      builder: (_) => _ManualFulfillDialog(
        requestDoc: widget.doc,
        hospitalName: widget.hospitalName,
        adminUid: widget.adminUid,
        hospitalId: widget.hospitalId,
        onDone: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = widget.doc.data() as Map<String, dynamic>;

    final patientName = data['patientName'] ?? '—';
    final bloodGroup = data['bloodGroup'] ?? '?';
    final units = data['units']?.toString() ?? '1';
    final city = data['city'] ?? '—';
    final phone = (data['phone'] ?? data['contactPhone'] ?? '') as String;
    final isUrgent = (data['isUrgent'] ?? false) as bool;
    final ts = data['createdAt'] as Timestamp?;
    final dateStr = ts != null
        ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}  '
            '${ts.toDate().hour}:${ts.toDate().minute.toString().padLeft(2, '0')}'
        : '—';

    final String statusKey;
    if (widget.isDone) {
      statusKey = 'done';
    } else if (widget.isVerified) {
      statusKey = 'verified';
    } else {
      statusKey = 'pending';
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollCtrl) => ListView(
        controller: scrollCtrl,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.requestDetails,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              _StatusChip(statusKey: statusKey),
              if (isUrgent) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Text(
                    l10n.urgentLabel,
                    style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 20),

          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.primaryRed.withOpacity(0.3)),
              ),
              child: Text(
                bloodGroup,
                style: const TextStyle(
                  color: AppColors.primaryRed,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          _DetailRow(
              icon: Icons.person_outline,
              label: l10n.patientName,
              value: patientName),
          _DetailRow(
              icon: Icons.water_drop_outlined,
              label: l10n.units,
              value: '$units ${l10n.units}'),
          _DetailRow(
              icon: Icons.location_city_outlined,
              label: l10n.city,
              value: city),
          _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: l10n.requestDate,
              value: dateStr),
          if (phone.isNotEmpty)
            _DetailRow(
                icon: Icons.phone_outlined,
                label: l10n.phone,
                value: phone),

          if (!widget.isDone) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.manualOverrideNote,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (!widget.isVerified)
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: _loading ? null : _markVerified,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.verified_outlined),
                label: Text(l10n.markAsVerified),
              ),
            if (widget.isVerified && !widget.isDone) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: _openManualFulfill,
                icon: const Icon(Icons.handshake_outlined),
                label: Text(l10n.manualDonationTitle),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String statusKey;
  const _StatusChip({required this.statusKey});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final Color bg;
    final Color fg;
    final String label;
    switch (statusKey) {
      case 'done':
      case 'completed':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        label = l10n.statusCompleted;
      case 'verified':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        label = l10n.statusVerified;
      default:
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade700;
        label = l10n.statusUnverified;
    }
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label,
          style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Manual Fulfill Dialog ────────────────────────────────────────────────────

class _ManualFulfillDialog extends StatefulWidget {
  final DocumentSnapshot requestDoc;
  final String hospitalName;
  final String adminUid;
  final String hospitalId;
  final VoidCallback onDone;

  const _ManualFulfillDialog({
    required this.requestDoc,
    required this.hospitalName,
    required this.adminUid,
    required this.hospitalId,
    required this.onDone,
  });

  @override
  State<_ManualFulfillDialog> createState() =>
      _ManualFulfillDialogState();
}

class _ManualFulfillDialogState extends State<_ManualFulfillDialog> {
  final _formKey = GlobalKey<FormState>();
  final _donorIdCtrl = TextEditingController();
  bool _loading = false;
  String? _donorName;

  @override
  void dispose() {
    _donorIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookupDonor() async {
    final l10n = AppLocalizations.of(context)!;
    final uid = _donorIdCtrl.text.trim();
    if (uid.isEmpty) return;
    setState(() => _loading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!doc.exists) throw Exception(l10n.donorNotFound);
      setState(
          () => _donorName = doc.data()?['name'] as String? ?? uid);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error));
        setState(() => _donorName = null);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _completeDonation() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    if (_donorName == null) {
      await _lookupDonor();
      if (_donorName == null) return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmDonationTitle),
        content: Text(l10n.confirmDonationBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.confirm)),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      final donorId = _donorIdCtrl.text.trim();
      final requestId = widget.requestDoc.id;
      final requestData =
          widget.requestDoc.data() as Map<String, dynamic>;

      final batch = FirebaseFirestore.instance.batch();

      batch.update(widget.requestDoc.reference, {'status': 'done'});

      final donorRef = FirebaseFirestore.instance
          .collection('users')
          .doc(donorId);
      batch.update(donorRef,
          {'lastDonated': DateTime.now().toIso8601String()});

      final donationRef =
          FirebaseFirestore.instance.collection('donations').doc();
      batch.set(donationRef, {
        'donorId': donorId,
        'requestId': requestId,
        'hospitalId': widget.hospitalId,
        'hospitalName': widget.hospitalName,
        'timestamp': FieldValue.serverTimestamp(),
        'verifiedBy': widget.adminUid,
        'manualOverride': true,
      });

      await batch.commit();

      final donorDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(donorId)
          .get();
      final donorBloodGroup =
          donorDoc.data()?['bloodGroup'] as String? ?? '';
      final isUrgent = requestData['isUrgent'] == true;

      await PointsService().awardDonationPoints(
        donorId,
        widget.hospitalName,
        isEmergency: isUrgent,
        donorBloodGroup: donorBloodGroup,
      );

      final recipientUid = requestData['userId'] as String?;
      NotificationEngine().dispatch(DonationRegisteredEvent(
        donorId: donorId,
        requestId: requestId,
        requesterId: recipientUid,
      ));

      if (mounted) {
        Navigator.pop(context);
        widget.onDone();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.donationSuccess),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        const Icon(Icons.handshake, color: AppColors.success),
        const SizedBox(width: 8),
        Expanded(child: Text(l10n.manualDonationTitle)),
      ]),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.enterDonorId,
                style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _donorIdCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.donorId,
                      prefixIcon:
                          const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? l10n.requiredField
                        : null,
                    onChanged: (_) =>
                        setState(() => _donorName = null),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _loading ? null : _lookupDonor,
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2))
                      : const Icon(Icons.search),
                  style: IconButton.styleFrom(
                      backgroundColor: Colors.blue.shade50),
                ),
              ],
            ),
            if (_donorName != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(children: [
                  const Icon(Icons.person_outline,
                      color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _donorName!,
                      style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ]),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.success),
          onPressed: _loading ? null : _completeDonation,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Text(l10n.markAsDone),
        ),
      ],
    );
  }
}

// ─── Donation History Tab ─────────────────────────────────────────────────────

class _DonationHistoryTab extends StatelessWidget {
  final String hospitalId;
  const _DonationHistoryTab({required this.hospitalId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('donations')
          .where('hospitalId', isEqualTo: hospitalId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(l10n.noDonationsYet,
                    style: TextStyle(
                        color: Colors.grey[500], fontSize: 15)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final donorId = data['donorId'] as String?;
            final requestId = data['requestId'] as String?;
            final ts = data['timestamp'] as Timestamp?;
            final isManual = data['manualOverride'] == true;
            final dateStr = ts != null
                ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}'
                    '  ${ts.toDate().hour}:${ts.toDate().minute.toString().padLeft(2, '0')}'
                : '—';

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.favorite,
                          color: AppColors.success, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (donorId != null)
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(donorId)
                                  .get(),
                              builder: (_, snap) {
                                final name = snap.data
                                        ?.get('name') as String? ??
                                    (snap.connectionState ==
                                            ConnectionState.done
                                        ? donorId
                                        : '…');
                                final bg = snap.data
                                        ?.get('bloodGroup')
                                    as String? ??
                                    '';
                                return Row(children: [
                                  Expanded(
                                    child: Text(name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                  ),
                                  if (bg.isNotEmpty)
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryRed
                                            .withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(bg,
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColors.primaryRed,
                                              fontWeight:
                                                  FontWeight.bold)),
                                    ),
                                ]);
                              },
                            ),
                          if (requestId != null)
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('blood_requests')
                                  .doc(requestId)
                                  .get(),
                              builder: (_, snap) {
                                final patient = snap.data
                                        ?.get('patientName')
                                    as String? ??
                                    '';
                                if (patient.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return Text(
                                  '${l10n.patientName}: $patient',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600]),
                                );
                              },
                            ),
                          const SizedBox(height: 4),
                          Row(children: [
                            Icon(Icons.schedule,
                                size: 12, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(dateStr,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500])),
                            if (isManual) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius:
                                      BorderRadius.circular(4),
                                  border: Border.all(
                                      color: Colors.amber.shade200),
                                ),
                                child: Text(
                                  l10n.manualBadge,
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.amber.shade800),
                                ),
                              ),
                            ],
                          ]),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle,
                        color: AppColors.success, size: 18),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SCANNER SCREENS (unchanged)
// ═════════════════════════════════════════════════════════════════════════════

class ScannerScreen extends ConsumerStatefulWidget {
  final bool isVerifyOnly;
  const ScannerScreen({super.key, required this.isVerifyOnly});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  String? donorId;
  String? requestId;
  bool isProcessing = false;

  void _onDetect(BarcodeCapture capture) async {
    if (isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() => isProcessing = true);

    if (widget.isVerifyOnly) {
      await _handleVerifyRequest(code);
    } else {
      if (donorId == null) {
        await _handleDonorScan(code);
      } else {
        await _handleRequestScan(code);
      }
    }

    if (mounted) setState(() => isProcessing = false);
  }

  Future<void> _handleVerifyRequest(String id) async {
    final l10n = AppLocalizations.of(context)!;
    final adminProfile = ref.read(userProfileProvider).value;
    final myHospitalId = adminProfile?['hospitalId'];

    try {
      final doc = await FirebaseFirestore.instance
          .collection('blood_requests')
          .doc(id)
          .get();
      if (!doc.exists) throw Exception(l10n.invalidQr);

      if (doc.data()?['hospitalId'] != myHospitalId) {
        throw Exception(l10n.invalidHospital);
      }

      await doc.reference.update({'isVerified': true});

      final requestData = doc.data() as Map<String, dynamic>;
      final requesterId = requestData['userId'] as String?;
      NotificationEngine().dispatch(BloodRequestVerifiedEvent(
        requestId: id,
        requesterId: requesterId,
        city: requestData['city'] ?? '',
        bloodGroup: requestData['bloodGroup'] ?? '',
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.verifySuccess)));
        Navigator.pop(context);
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _handleDonorScan(String id) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(id)
          .get();
      if (!doc.exists) throw Exception(l10n.invalidQr);

      setState(() {
        donorId = id;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n
                .donorDetected(doc.data()?['name'] ?? l10n.unknown))),
      );
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _handleRequestScan(String id) async {
    final l10n = AppLocalizations.of(context)!;
    final adminProfile = ref.read(userProfileProvider).value;
    final myHospitalId = adminProfile?['hospitalId'];

    try {
      final doc = await FirebaseFirestore.instance
          .collection('blood_requests')
          .doc(id)
          .get();
      if (!doc.exists) throw Exception(l10n.invalidQr);

      if (doc.data()?['hospitalId'] != myHospitalId) {
        throw Exception(l10n.invalidHospital);
      }

      setState(() => requestId = id);

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.confirmDonationTitle),
          content: Text(l10n.confirmDonationBody),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel)),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.confirm)),
          ],
        ),
      );

      if (confirm == true) {
        await _completeDonation();
      } else {
        setState(() => requestId = null);
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _completeDonation() async {
    final l10n = AppLocalizations.of(context)!;
    final adminProfile = ref.read(userProfileProvider).value;

    try {
      final batch = FirebaseFirestore.instance.batch();

      final requestRef = FirebaseFirestore.instance
          .collection('blood_requests')
          .doc(requestId);
      batch.update(requestRef, {'status': 'done'});

      final donorRef = FirebaseFirestore.instance
          .collection('users')
          .doc(donorId);
      batch.update(donorRef,
          {'lastDonated': DateTime.now().toIso8601String()});

      final donationRef =
          FirebaseFirestore.instance.collection('donations').doc();
      batch.set(donationRef, {
        'donorId': donorId,
        'requestId': requestId,
        'hospitalId': adminProfile?['hospitalId'],
        'hospitalName': adminProfile?['name'],
        'timestamp': FieldValue.serverTimestamp(),
        'verifiedBy': adminProfile?['uid'],
      });

      await batch.commit();

      final donorDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(donorId)
          .get();
      final donorBloodGroup =
          donorDoc.data()?['bloodGroup'] as String? ?? '';
      final hospitalName = adminProfile?['name'] as String? ?? '';

      final requestDoc = await FirebaseFirestore.instance
          .collection('blood_requests')
          .doc(requestId)
          .get();
      final recipientUid = requestDoc.data()?['userId'];
      final isUrgent = requestDoc.data()?['isUrgent'] == true;

      await PointsService().awardDonationPoints(
        donorId!,
        hospitalName,
        isEmergency: isUrgent,
        donorBloodGroup: donorBloodGroup,
      );

      if (donorId != null) {
        NotificationEngine().dispatch(DonationRegisteredEvent(
          donorId: donorId!,
          requestId: requestId!,
          requesterId: recipientUid as String?,
        ));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.donationSuccess)));
        Navigator.pop(context);
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final String title = widget.isVerifyOnly
        ? l10n.verifyRequest
        : (donorId == null ? l10n.step1Of2 : l10n.step2Of2);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.isVerifyOnly
                    ? l10n.scanRequestQr
                    : (donorId == null
                        ? l10n.waitingForDonor
                        : l10n.waitingForRequest),
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          if (isProcessing)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

// ─── Blood Group Verification Screen ─────────────────────────────────────────

class BloodGroupVerificationScreen extends ConsumerStatefulWidget {
  const BloodGroupVerificationScreen({super.key});

  @override
  ConsumerState<BloodGroupVerificationScreen> createState() =>
      _BloodGroupVerificationScreenState();
}

class _BloodGroupVerificationScreenState
    extends ConsumerState<BloodGroupVerificationScreen> {
  bool _isProcessing = false;
  Map<String, dynamic>? _scannedDonor;
  String? _scannedDonorId;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _scannedDonor != null) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null) return;

    setState(() => _isProcessing = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(code)
          .get();

      if (!doc.exists) throw Exception('Invalid QR code');

      final data = doc.data()!;
      if (data['role'] != 'donor') {
        throw Exception('This QR does not belong to a donor');
      }

      setState(() {
        _scannedDonorId = code;
        _scannedDonor = data;
      });

      if (mounted) await _showVerificationDialog(data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showVerificationDialog(
      Map<String, dynamic> donor) async {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final alreadyVerified = donor['bloodGroupVerified'] == true;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: AppDesignConstants.borderRadiusLarge),
        title: Text(l10n.bloodGroupVerificationTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (alreadyVerified)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.success, size: 18),
                    const SizedBox(width: 8),
                    Text(l10n.bloodGroupAlreadyVerified,
                        style: const TextStyle(
                            color: AppColors.success)),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            _infoRow(Icons.person, l10n.name, donor['name'] ?? '—'),
            const SizedBox(height: 8),
            _infoRow(Icons.bloodtype, l10n.bloodGroup,
                donor['bloodGroup'] ?? '—'),
            const SizedBox(height: 8),
            _infoRow(
                Icons.location_city, l10n.city, donor['city'] ?? '—'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple),
            icon: const Icon(Icons.verified, size: 18),
            label: Text(l10n.confirmBloodGroupVerification),
          ),
        ],
      ),
    );

    if (confirm == true) await _verify(donor);
    setState(() => _scannedDonor = null);
  }

  Future<void> _verify(Map<String, dynamic> donor) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_scannedDonorId)
          .update({'bloodGroupVerified': true});

      final updatedSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(_scannedDonorId)
          .get();
      if (updatedSnap.exists) {
        await PointsService().checkAndAwardProfileMilestones(
          _scannedDonorId!,
          updatedSnap.data()!,
        );
      }

      NotificationEngine().dispatch(BloodGroupVerifiedEvent(
        donorId: _scannedDonorId!,
        bloodGroup: donor['bloodGroup'] as String? ?? '',
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.bloodGroupVerifiedSuccess),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Widget _infoRow(IconData icon, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon,
            size: 18,
            color: colorScheme.onSurface.withOpacity(0.5)),
        const SizedBox(width: 8),
        Text('$label: ',
            style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.5),
                fontSize: 13)),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.verifyDonorBloodGroup),
        backgroundColor: Colors.deepPurple,
      ),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l10n.scanDonorQrForVerification,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          if (_isProcessing)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/core/theme/app_design_constants.dart';
import 'package:sheryan/core/utils/points_ui_utils.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/services/points_service.dart';

class MedicalHistoryScreen extends StatefulWidget {
  final Map<String, dynamic> existingData;
  const MedicalHistoryScreen({super.key, required this.existingData});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  final _lastDonatedCtrl = TextEditingController();
  final _chronicCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  bool _loading = false;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    final d = widget.existingData;
    _lastDonatedCtrl.text = d['lastDonated'] ?? '';
    _chronicCtrl.text = d['chronicDiseases'] ?? '';
    _allergiesCtrl.text = d['allergies'] ?? '';
    _isLocked = d['isLedgerLocked'] == true;
  }

  @override
  void dispose() {
    _lastDonatedCtrl.dispose();
    _chronicCtrl.dispose();
    _allergiesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final dt = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 90)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primaryRed),
        ),
        child: child!,
      ),
    );
    if (dt != null) {
      setState(() {
        _lastDonatedCtrl.text = DateFormat('yyyy-MM-dd').format(dt);
      });
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_lastDonatedCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectLastDonationDate)),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'lastDonated': _lastDonatedCtrl.text.trim(),
        'chronicDiseases': _chronicCtrl.text.trim(),
        'allergies': _allergiesCtrl.text.trim(),
      });

      // Award points for completed milestones
      final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final profile = snap.data() ?? {};
      final pts = await PointsService().checkAndAwardProfileMilestones(uid, profile);

      if (mounted) {
        if (pts > 0) showPointsGainedSnack(context, pts);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.medicalHistoryTitle)),
      body: SingleChildScrollView(
        padding: AppDesignConstants.edgeInsetsMedium,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(
                Icons.medical_services_outlined,
                l10n.medicalHistoryTitle,
                l10n.medicalHistorySubtitle,
                theme),
            const SizedBox(height: 20),

            TextFormField(
              controller: _lastDonatedCtrl,
              readOnly: true,
              onTap: _isLocked ? null : _pickDate,
              decoration: InputDecoration(
                labelText: l10n.lastDonated,
                prefixIcon: const Icon(Icons.calendar_today),
                suffixIcon: _isLocked 
                  ? const Icon(Icons.lock_outline, color: Colors.orange, size: 20)
                  : const Icon(Icons.edit_calendar_outlined),
                helperText: _isLocked ? l10n.ledgerLockedNote : null,
                helperStyle: _isLocked ? const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold) : null,
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _chronicCtrl,
              decoration: InputDecoration(
                labelText: l10n.chronicDiseases,
                prefixIcon: const Icon(Icons.local_hospital_outlined),
                hintText: l10n.chronicDiseasesHint,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _allergiesCtrl,
              decoration: InputDecoration(
                labelText: l10n.allergies,
                prefixIcon: const Icon(Icons.warning_amber_outlined),
                hintText: l10n.allergiesHint,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.noneKnown,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5)),
            ),
            const SizedBox(height: 28),

            ElevatedButton.icon(
              onPressed: _loading ? null : _save,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(l10n.saveChanges),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      IconData icon, String title, String subtitle, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryRed.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryRed, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurface.withOpacity(0.5))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

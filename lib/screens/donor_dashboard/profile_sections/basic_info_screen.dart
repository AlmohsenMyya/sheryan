import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/core/theme/app_design_constants.dart';
import 'package:sheryan/core/utils/points_ui_utils.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/services/points_service.dart';

class BasicInfoScreen extends StatefulWidget {
  final Map<String, dynamic> existingData;
  const BasicInfoScreen({super.key, required this.existingData});

  @override
  State<BasicInfoScreen> createState() => _BasicInfoScreenState();
}

class _BasicInfoScreenState extends State<BasicInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  String? _bloodGroup;
  bool _loading = false;

  final List<String> _bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];

  @override
  void initState() {
    super.initState();
    final d = widget.existingData;
    _nameCtrl.text = d['name'] ?? '';
    _phoneCtrl.text = d['phone'] ?? '';
    _cityCtrl.text = d['city'] ?? '';
    _dobCtrl.text = d['dateOfBirth'] ?? '';
    _bloodGroup = d['bloodGroup'];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final dt = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 16)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primaryRed),
        ),
        child: child!,
      ),
    );
    if (dt != null && mounted) {
      setState(() {
        _dobCtrl.text = DateFormat('yyyy-MM-dd').format(dt);
      });
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_bloodGroup == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.requiredField)));
      return;
    }

    final oldBloodGroup = widget.existingData['bloodGroup'];
    final isVerified = widget.existingData['bloodGroupVerified'] == true;
    bool shouldResetVerification = false;

    // Check if blood group changed and it was previously verified
    if (isVerified && _bloodGroup != oldBloodGroup) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.confirmBloodGroupVerification), // Reuse existing key or generic title
          content: Text(l10n.confirm_changing_blood),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.confirm),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      shouldResetVerification = true;
    }

    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final Map<String, dynamic> updateData = {
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'bloodGroup': _bloodGroup,
        'dateOfBirth': _dobCtrl.text.trim(),
      };

      if (shouldResetVerification) {
        updateData['bloodGroupVerified'] = false;
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).update(updateData);

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
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isVerified = widget.existingData['bloodGroupVerified'] == true;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.basicInfoTitle)),
      body: SingleChildScrollView(
        padding: AppDesignConstants.edgeInsetsMedium,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(theme, l10n),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: l10n.fullName,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? l10n.requiredField : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.phoneNumber,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? l10n.requiredField : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cityCtrl,
                decoration: InputDecoration(
                  labelText: l10n.city,
                  prefixIcon: const Icon(Icons.location_city_outlined),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? l10n.requiredField : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dobCtrl,
                readOnly: true,
                onTap: _pickDob,
                decoration: InputDecoration(
                  labelText: l10n.dateOfBirth,
                  prefixIcon: const Icon(Icons.cake_outlined),
                  suffixIcon: const Icon(Icons.edit_calendar_outlined),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(l10n.bloodGroup, style: theme.textTheme.titleSmall),
                  if (isVerified) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.verified, color: AppColors.success, size: 16),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _bloodTypes.map((bg) {
                  final selected = _bloodGroup == bg;
                  return ChoiceChip(
                    label: Text(bg),
                    selected: selected,
                    onSelected: (_) => setState(() => _bloodGroup = bg),
                    selectedColor: AppColors.primaryRed,
                    backgroundColor:
                        theme.colorScheme.surfaceContainerHighest,
                    labelStyle: TextStyle(
                      color: selected
                          ? Colors.white
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  );
                }).toList(),
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
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, AppLocalizations l10n) {
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
            child: const Icon(Icons.person_outline,
                color: AppColors.primaryRed, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.basicInfoTitle, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  l10n.basicInfoSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

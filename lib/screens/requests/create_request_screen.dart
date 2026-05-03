import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/core/theme/app_design_constants.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/events/app_event.dart';
import 'package:sheryan/events/notification_engine.dart';
import 'package:sheryan/services/hospital_service.dart';
import 'package:sheryan/services/pending_actions_service.dart';
import 'package:sheryan/services/request_service.dart';
import 'package:intl/intl.dart';

class RequestBloodScreen extends StatefulWidget {
  const RequestBloodScreen({super.key});

  @override
  State<RequestBloodScreen> createState() => _RequestBloodScreenState();
}

class _RequestBloodScreenState extends State<RequestBloodScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _patientName = TextEditingController();
  final TextEditingController _units = TextEditingController();
  final TextEditingController _phone = TextEditingController();

  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'
  ];
  String _selectedGroup = 'A+';
  String? _selectedCity;
  String? _selectedHospitalId;
  String? _selectedHospitalName;
  DateTime? _neededAt;
  bool _loading = false;

  @override
  void dispose() {
    _patientName.dispose();
    _units.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickNeededDateTime() async {
    final now = DateTime.now();
    final colorScheme = Theme.of(context).colorScheme;
    final date = await showDatePicker(
      context: context,
      initialDate: _neededAt ?? now,
      firstDate: now,
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: colorScheme.copyWith(
            primary: AppColors.primaryRed,
            onPrimary: colorScheme.onPrimary,
            surface: colorScheme.surface,
            onSurface: colorScheme.onSurface,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_neededAt ?? now),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: colorScheme.copyWith(
            primary: AppColors.primaryRed,
            onPrimary: colorScheme.onPrimary,
            surface: colorScheme.surface,
            onSurface: colorScheme.onSurface,
          ),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    setState(() {
      _neededAt = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate() ||
        _selectedCity == null ||
        _selectedHospitalId == null) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    setState(() => _loading = true);

    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline =
        connectivityResult.any((r) => r != ConnectivityResult.none);

    final neededAtFormatted = _neededAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(_neededAt!)
        : l10n.notSpecified;

    if (!isOnline) {
      await PendingActionsService().saveRequest({
        'patientName': _patientName.text.trim(),
        'hospitalId': _selectedHospitalId,
        'hospital': _selectedHospitalName ?? '',
        'city': _selectedCity,
        'bloodGroup': _selectedGroup,
        'units': _units.text.trim(),
        'phone': _phone.text.trim(),
        'neededAt': neededAtFormatted,
      });

      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.requestSavedOffline),
            backgroundColor: Colors.orange.shade800,
            duration: const Duration(seconds: 5),
          ),
        );
        Navigator.pop(context);
      }
      return;
    }

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final requestId = await RequestService().create({
        'userId': uid,
        'patientName': _patientName.text.trim(),
        'hospitalId': _selectedHospitalId,
        'hospital': _selectedHospitalName ?? '',
        'city': _selectedCity,
        'bloodGroup': _selectedGroup,
        'units': _units.text.trim(),
        'phone': _phone.text.trim(),
        'neededAt': neededAtFormatted,
      });

      NotificationEngine().dispatch(BloodRequestCreatedEvent(
        hospitalId: _selectedHospitalId!,
        hospitalName: _selectedHospitalName ?? '',
        patientName: _patientName.text.trim(),
        bloodGroup: _selectedGroup,
        requestId: requestId,
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.requestSubmittedSuccessfully)));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.requestSubmittingError(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.requestBlood)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppDesignConstants.edgeInsetsMedium,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.createBloodRequest,
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 14),

                // Patient name
                TextFormField(
                  controller: _patientName,
                  decoration: InputDecoration(labelText: l10n.patientName),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? l10n.requiredField : null,
                ),
                const SizedBox(height: 12),

                // City Dropdown
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: HospitalService().watchCities(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const LinearProgressIndicator();
                    final cities = snapshot.data!;
                    return DropdownButtonFormField<String>(
                      value: _selectedCity,
                      decoration: InputDecoration(labelText: l10n.city),
                      hint: Text(l10n.selectCity),
                      items: cities
                          .map((c) => DropdownMenuItem(
                                value: c['name'] as String,
                                child: Text(c['name']),
                              ))
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedCity = v;
                          _selectedHospitalId = null;
                          _selectedHospitalName = null;
                        });
                      },
                      validator: (v) =>
                          v == null ? l10n.requiredField : null,
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Hospital Dropdown (filtered by city)
                if (_selectedCity != null)
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: HospitalService().watchHospitalsByCity(_selectedCity!),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const LinearProgressIndicator();
                      final hospitals = snapshot.data!;
                      return DropdownButtonFormField<String>(
                        value: _selectedHospitalId,
                        decoration:
                            InputDecoration(labelText: l10n.hospitalName),
                        hint: Text(l10n.hospitalName),
                        items: hospitals
                            .map((h) => DropdownMenuItem(
                                  value: h['id'] as String,
                                  child: Text(h['name']),
                                ))
                            .toList(),
                        onChanged: (v) {
                          final selected =
                              hospitals.firstWhere((h) => h['id'] == v);
                          setState(() {
                            _selectedHospitalId = v;
                            _selectedHospitalName =
                                selected['name'] as String?;
                          });
                        },
                        validator: (v) =>
                            v == null ? l10n.requiredField : null,
                      );
                    },
                  ),
                const SizedBox(height: 12),

                // Phone
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration:
                      InputDecoration(labelText: l10n.phoneNumber),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? l10n.requiredField : null,
                ),
                const SizedBox(height: 12),

                // Blood group + units row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedGroup,
                        dropdownColor: colorScheme.surface,
                        decoration:
                            InputDecoration(labelText: l10n.bloodGroup),
                        items: _bloodGroups
                            .map((g) => DropdownMenuItem(
                                value: g, child: Text(g)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedGroup = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _units,
                        keyboardType: TextInputType.number,
                        decoration:
                            InputDecoration(labelText: l10n.units),
                        validator: (v) =>
                            (v == null || v.isEmpty)
                                ? l10n.requiredField
                                : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Needed-at picker
                GestureDetector(
                  onTap: _pickNeededDateTime,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: AppDesignConstants.borderRadiusMedium,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _neededAt == null
                                ? l10n.whenBloodNeededTap
                                : l10n.neededAtValue(DateFormat(
                                        'dd MMM yyyy, hh:mm a')
                                    .format(_neededAt!)),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        const Icon(Icons.access_time,
                            color: AppColors.primaryRed),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submitRequest,
                    child: _loading
                        ? CircularProgressIndicator(
                            color: colorScheme.onPrimary)
                        : Text(l10n.submitRequest),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

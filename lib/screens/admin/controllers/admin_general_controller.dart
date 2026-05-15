import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sheryan/services/hospital_service.dart';
import 'package:sheryan/l10n/app_localizations.dart';

class AdminGeneralState {
  final bool isLoading;
  AdminGeneralState({this.isLoading = false});
}

// 1. التغيير إلى StateNotifier
class AdminGeneralNotifier extends StateNotifier<AdminGeneralState> {
  // 2. إضافة المشيّد وتمرير الحالة الابتدائية
  AdminGeneralNotifier() : super(AdminGeneralState());

  final HospitalService _service = HospitalService();

  Future<void> addHospital({
    required BuildContext context,
    required String name,
    required String city,
    required VoidCallback onSuccess,
  }) async {
    // حماية: التأكد من أن المتحكم لا يزال يعمل
    if (!mounted) return;

    state = AdminGeneralState(isLoading: true);
    final l10n = AppLocalizations.of(context)!;
    try {
      await _service.addHospital(name: name, city: city);
      if (context.mounted) {
        onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.hospitalAdded)));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      // حماية قبل إعادة الحالة
      if (mounted) {
        state = AdminGeneralState(isLoading: false);
      }
    }
  }

  Future<void> updateHospital({
    required BuildContext context,
    required String id,
    required String name,
    required String city,
    required VoidCallback onSuccess,
  }) async {
    if (!mounted) return;

    state = AdminGeneralState(isLoading: true);
    final l10n = AppLocalizations.of(context)!;
    try {
      await _service.updateHospital(id, name: name, city: city);
      if (context.mounted) {
        onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.hospitalUpdated)));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        state = AdminGeneralState(isLoading: false);
      }
    }
  }

  Future<void> deleteHospital(BuildContext context, String id) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _service.deleteHospital(id);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.hospitalDeleted)));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> addCity({
    required BuildContext context,
    required String name,
    required VoidCallback onSuccess,
  }) async {
    if (!mounted) return;

    state = AdminGeneralState(isLoading: true);
    final l10n = AppLocalizations.of(context)!;
    try {
      await _service.addCity(name);
      if (context.mounted) {
        onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.cityAdded)));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        state = AdminGeneralState(isLoading: false);
      }
    }
  }

  Future<void> updateCity({
    required BuildContext context,
    required String id,
    required String name,
    required VoidCallback onSuccess,
  }) async {
    if (!mounted) return;

    state = AdminGeneralState(isLoading: true);
    final l10n = AppLocalizations.of(context)!;
    try {
      await _service.updateCity(id, name);
      if (context.mounted) {
        onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.cityUpdated)));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        state = AdminGeneralState(isLoading: false);
      }
    }
  }

  Future<void> deleteCity(BuildContext context, String id) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _service.deleteCity(id);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.cityDeleted)));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

// 3. التغيير إلى StateNotifierProvider
final adminGeneralProvider = StateNotifierProvider.autoDispose<AdminGeneralNotifier, AdminGeneralState>((ref) {
  return AdminGeneralNotifier();
});
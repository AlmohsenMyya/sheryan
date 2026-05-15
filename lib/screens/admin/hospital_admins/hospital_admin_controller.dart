import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sheryan/services/auth_service.dart';
import 'package:sheryan/services/user_service.dart';
import 'package:sheryan/l10n/app_localizations.dart';

class HospitalAdminState {
  final bool isLoading;
  HospitalAdminState({this.isLoading = false});
}

// 1. التغيير إلى StateNotifier
class HospitalAdminNotifier extends StateNotifier<HospitalAdminState> {
  // 2. إضافة المشيّد (Constructor) وتمرير الحالة الابتدائية
  HospitalAdminNotifier() : super(HospitalAdminState());

  Future<void> createAdmin({
    required BuildContext context,
    required String name,
    required String email,
    required String password,
    required String hospitalId,
    required VoidCallback onSuccess,
  }) async {
    // حماية: التأكد من أن المتحكم لا يزال يعمل قبل تغيير الحالة
    if (!mounted) return;

    state = HospitalAdminState(isLoading: true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final ok = await AuthService().registerUser(
        name: name,
        email: email,
        password: password,
        bloodGroup: '',
        city: '',
        role: 'hospitalAdmin',
        phone: '',
        hospitalId: hospitalId,
      );
      if (ok && context.mounted) {
        onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.adminCreated)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      // حماية: التأكد من أن المتحكم لا يزال يعمل قبل إعادة الحالة للوضع الطبيعي
      if (mounted) {
        state = HospitalAdminState(isLoading: false);
      }
    }
  }

  Future<void> updateAdmin({
    required BuildContext context,
    required String uid,
    required String name,
    required String? hospitalId,
    required VoidCallback onSuccess,
  }) async {
    if (!mounted) return;

    state = HospitalAdminState(isLoading: true);
    final l10n = AppLocalizations.of(context)!;
    try {
      await UserService().updateFields(uid, {'name': name, 'hospitalId': hospitalId});
      if (context.mounted) {
        onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.adminUpdated)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        state = HospitalAdminState(isLoading: false);
      }
    }
  }

  Future<void> deleteAdmin(BuildContext context, String uid) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await UserService().deleteById(uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.adminDeleted)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

// 3. التغيير إلى StateNotifierProvider
final hospitalAdminProvider = StateNotifierProvider.autoDispose<HospitalAdminNotifier, HospitalAdminState>((ref) {
  return HospitalAdminNotifier();
});
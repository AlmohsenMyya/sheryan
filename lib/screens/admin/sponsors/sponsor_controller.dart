import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sheryan/services/auth_service.dart';
import 'package:sheryan/services/user_service.dart';
import 'package:sheryan/l10n/app_localizations.dart';

class SponsorState {
  final bool isLoading;
  SponsorState({this.isLoading = false});
}

// 1. التغيير إلى StateNotifier
class SponsorNotifier extends StateNotifier<SponsorState> {
  // 2. إضافة المشيّد
  SponsorNotifier() : super(SponsorState());

  Future<void> createSponsor({
    required BuildContext context,
    required String name,
    required String email,
    required String password,
    required String phone,
    required String city,
    required VoidCallback onSuccess,
  }) async {
    // حماية ضد الـ Memory Leaks
    if (!mounted) return;

    state = SponsorState(isLoading: true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final ok = await AuthService().registerUser(
        name: name,
        email: email,
        password: password,
        bloodGroup: '',
        city: city,
        role: 'sponsorOrg',
        phone: phone,
      );
      if (ok && context.mounted) {
        onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.sponsorCreated)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      // التأكد من وجود العنصر قبل إرجاع حالة التحميل
      if (mounted) {
        state = SponsorState(isLoading: false);
      }
    }
  }

  Future<void> updateSponsor({
    required BuildContext context,
    required String uid,
    required String name,
    required String? city,
    required VoidCallback onSuccess,
  }) async {
    if (!mounted) return;

    state = SponsorState(isLoading: true);
    final l10n = AppLocalizations.of(context)!;
    try {
      await UserService().updateFields(uid, {'name': name, 'city': city});
      if (context.mounted) {
        onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.sponsorUpdated)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        state = SponsorState(isLoading: false);
      }
    }
  }

  Future<void> deleteSponsor(BuildContext context, String uid) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await UserService().deleteById(uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.sponsorDeleted)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

// 3. التحديث إلى StateNotifierProvider
final sponsorProvider = StateNotifierProvider.autoDispose<SponsorNotifier, SponsorState>((ref) {
  return SponsorNotifier();
});
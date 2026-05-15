import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheryan/services/user_service.dart';
import 'package:sheryan/providers/auth/auth_provider.dart';
import 'package:sheryan/l10n/app_localizations.dart';

final profileControllerProvider = Provider((ref) => ProfileController(ref));

class ProfileController {
  final Ref _ref;
  final UserService _userService = UserService();

  ProfileController(this._ref);

  Future<void> updateProfile({
    required BuildContext context,
    required String name,
    required String phone,
    required String city,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final uid = _ref.read(userProfileProvider).asData?.value?['uid'];

    if (uid == null) return;

    try {
      await _userService.updateFields(uid, {
        'name': name,
        'phone': phone,
        'city': city,
      });

      _ref.invalidate(userProfileProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profileUpdatedSuccessfully)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.genericError(e.toString()))),
        );
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sheryan/services/auth_service.dart';
import 'package:sheryan/services/notification_service.dart';
import 'package:sheryan/services/pending_actions_service.dart';
import 'package:sheryan/providers/auth/auth_provider.dart';
import 'package:sheryan/screens/auth/sign_in_screen.dart';
import 'package:sheryan/l10n/app_localizations.dart';

final homeControllerProvider = Provider((ref) => HomeController(ref));

class HomeController {
  final Ref _ref;
  HomeController(this._ref);

  void initNotifications(BuildContext context, Map<String, dynamic> profile) {
    NotificationService().init(context);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    NotificationService().sendUserTags(
      uid: uid,
      city: profile['city'] as String? ?? 'unknown',
      bloodGroup: profile['bloodGroup'] as String? ?? 'unknown',
      role: profile['role'] as String? ?? 'user',
    );
  }

  Future<void> syncPendingRequests(BuildContext context) async {
    final count = await PendingActionsService().getPendingCount();
    if (count == 0) return;
    
    final synced = await PendingActionsService().syncPendingRequests();
    if (synced > 0 && context.mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pendingRequestsSynced),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
  }

  Future<void> signOut(BuildContext context) async {
    try {
      await NotificationService().logout();
      await _ref.read(authServiceProvider).logoutUser();
    } catch (_) {
      await AuthService().logoutUser();
    }
    _ref.read(roleProvider.notifier).clearRole();
    
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}

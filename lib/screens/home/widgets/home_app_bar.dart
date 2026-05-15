import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheryan/core/enums/user_role.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/widgets/notification_badge.dart';

class HomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final UserRole role;

  const HomeAppBar({super.key, required this.role});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    String title = l10n.appTitle;
    if (role == UserRole.donor) title = l10n.donorDashboard;

    return AppBar(
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          Image.asset('assets/logo.png', height: 32),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      actions: [
        if (userId != null) NotificationBadge(userId: userId),
        const SizedBox(width: 8),
      ],
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheryan/core/enums/user_role.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/core/theme/app_design_constants.dart';
import 'package:sheryan/providers/theme/theme_provider.dart';
import 'package:sheryan/services/notification_service.dart';
import 'package:sheryan/screens/misc/notifications_screen.dart';
import 'package:sheryan/screens/home/controllers/home_controller.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/screens/settings/userside_settings_screen.dart';
import 'package:sheryan/screens/donor_dashboard/donor_settings.dart';

class HomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final UserRole role;
  final VoidCallback onLanguageTap;

  const HomeAppBar({super.key, required this.role, required this.onLanguageTap});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    String title = l10n.appTitle;
    if (role == UserRole.donor) title = l10n.donorDashboard;
    if (role == UserRole.hospitalAdmin) title = l10n.hospitalAdminDashboard;

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
        IconButton(
          icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 22),
          onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
        ),
        if (userId != null) _NotificationBadge(userId: userId),
        IconButton(
          tooltip: l10n.changeLanguage,
          icon: const Icon(Icons.translate_outlined, size: 22),
          onPressed: onLanguageTap,
        ),
        _MenuButton(role: role),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _NotificationBadge extends StatelessWidget {
  final String userId;
  const _NotificationBadge({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: NotificationService().getUnreadCountStream(userId),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 22),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
            ),
            if (count > 0)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.bloodRed,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Theme.of(context).colorScheme.surface, width: 1.5),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MenuButton extends ConsumerWidget {
  final UserRole role;
  const _MenuButton({required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(borderRadius: AppDesignConstants.borderRadiusMedium),
      icon: const Icon(Icons.more_vert_outlined, size: 22),
      onSelected: (v) {
        if (v == 'settings') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => role == UserRole.donor
                  ? const DonorSettingsScreen()
                  : const SettingsScreen(),
            ),
          );
        } else if (v == 'logout') {
          ref.read(homeControllerProvider).signOut(context);
        }
      },
      itemBuilder: (ctx) => [
        if (role != UserRole.hospitalAdmin)
          PopupMenuItem(
            value: 'settings',
            child: Row(
              children: [
                const Icon(Icons.settings_outlined, size: 20),
                const SizedBox(width: 12),
                Text(l10n.settings),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout_outlined, color: AppColors.bloodRed, size: 20),
              const SizedBox(width: 12),
              Text(l10n.logout, style: const TextStyle(color: AppColors.bloodRed)),
            ],
          ),
        ),
      ],
    );
  }
}

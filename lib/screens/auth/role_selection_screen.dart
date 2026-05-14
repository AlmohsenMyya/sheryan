import 'package:sheryan/core/enums/user_role.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/core/theme/app_design_constants.dart';
import 'package:sheryan/providers/auth/auth_provider.dart';
import 'package:sheryan/screens/auth/sign_in_screen.dart';
import 'package:sheryan/screens/auth/sign_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});


  void _onRoleTap(BuildContext context, WidgetRef ref, UserRole role) {
  // Save role using provider
  ref.read(roleProvider.notifier).setRole(role);

  // Navigate to role-specific signup
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => SignupScreen(role: role)),
  );
}

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Center(
                child: Image.asset(
                  'assets/logo.png',
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 30),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.roleWhoAreYou, 
                  style: theme.textTheme.displayMedium,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.roleSelectContinue, 
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RoleCard(
                      icon: Icons.bloodtype,
                      title: l10n.roleDonor,
                      subtitle: l10n.roleDonorSubtitle,
                      onTap: () => _onRoleTap(context, ref, UserRole.donor),
                    ),
                    const SizedBox(height: 16),
                    _RoleCard(
                      icon: Icons.person,
                      title: l10n.roleUser,
                      subtitle: l10n.roleUserSubtitle,
                      onTap: () => _onRoleTap(context, ref, UserRole.recipient),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
                child: Text(
                  l10n.alreadyHaveAccountLogin, 
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _RoleCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppDesignConstants.edgeInsetsMedium,
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppDesignConstants.borderRadiusMedium,
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Row(
          children: [
            Icon(icon, size: 34, color: AppColors.primaryRed),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                title, 
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle, 
                style: theme.textTheme.bodyMedium,
              ),
            ])),
            Icon(Icons.arrow_forward_ios, color: theme.colorScheme.onSurface.withOpacity(0.5), size: 16),
          ],
        ),
      ),
    );
  }
}

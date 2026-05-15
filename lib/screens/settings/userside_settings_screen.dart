import 'package:sheryan/core/enums/user_role.dart';
import 'package:sheryan/screens/home/providers/home_providers.dart';
import 'package:sheryan/providers/locale/locale_provider.dart';
import 'package:sheryan/providers/theme/theme_provider.dart';
import 'package:sheryan/services/notification_service.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/core/theme/app_design_constants.dart';
import 'package:sheryan/screens/auth/sign_in_screen.dart';
import 'package:sheryan/screens/home/controllers/home_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final userRole = ref.watch(currentUserRoleProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          _buildSection(context, l10n.account, [
            _buildCard(
              context: context,
              icon: Icons.account_circle_outlined,
              title: l10n.account,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountScreen()),
                );
              },
            ),
            if (userRole == UserRole.recipient)
              _buildCard(
                context: context,
                icon: Icons.history,
                title: l10n.resetRequests,
                onTap: () => _resetRequests(context),
              ),
          ]),

          _buildSection(context, l10n.appPreferences, [
            _ThemeToggle(),
            _LanguageTile(),
            _NotificationToggle(),
          ]),

          _buildSection(context, l10n.helpSupport, [
            _buildCard(
              context: context,
              icon: Icons.support_agent_outlined,
              title: l10n.contactSupport,
              onTap: () => _contactSupport(context),
            ),
          ]),

          _buildSection(context, l10n.privacyLegal, [
            _buildCard(
              context: context,
              icon: Icons.privacy_tip_outlined,
              title: l10n.privacyPolicy,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacyTermsScreen(isPrivacy: true)),
                );
              },
            ),
            _buildCard(
              context: context,
              icon: Icons.article_outlined,
              title: l10n.termsConditions,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacyTermsScreen(isPrivacy: false)),
                );
              },
            ),
          ]),

          _buildSection(context, l10n.about, [
            _buildCard(
              context: context,
              icon: Icons.info_outline,
              title: l10n.aboutApp,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                );
              },
            ),
          ]),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: OutlinedButton.icon(
              onPressed: () => _signOut(context, ref),
              icon: const Icon(Icons.logout, color: AppColors.bloodRed),
              label: Text(l10n.logout, style: const TextStyle(color: AppColors.bloodRed, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.bloodRed),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: AppDesignConstants.borderRadiusMedium),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textGrey),
        onTap: onTap,
      ),
    );
  }

  Future<void> _resetRequests(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.resetAllRequests),
        content: Text(l10n.confirmResetRequests),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.bloodRed),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.yesDelete),
          ),
        ],
      ),
    );

    if (confirm == true && user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('blood_requests')
          .where('userId', isEqualTo: user.uid)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.allRequestsDeleted)),
        );
      }
    }
  }

  Future<void> _contactSupport(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final Uri email = Uri(
      scheme: 'mailto',
      path: 'almohsen@gmail.com',
      query: 'subject=${l10n.supportEmailSubject}',
    );
    if (await canLaunchUrl(email)) {
      await url_launcher.launchUrl(email);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorEmailApp)),
      );
    }
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.signOut),
        content: Text(l10n.confirmSignOut),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.bloodRed),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(homeControllerProvider).signOut(context);
    }
  }
}

class _ThemeToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Card(
      child: SwitchListTile(
        secondary: Icon(
          isDark ? Icons.dark_mode : Icons.light_mode,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(l10n.theme),
        subtitle: Text(isDark ? l10n.darkMode : l10n.appTitle), // Reuse keys if possible, or just text
        value: isDark,
        onChanged: (v) => ref.read(themeModeProvider.notifier).toggle(),
      ),
    );
  }
}

class _LanguageTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);
    final languageName = currentLocale?.languageCode == 'ar' ? l10n.languageArabic : l10n.languageEnglish;

    return Card(
      child: ListTile(
        leading: Icon(Icons.translate, color: Theme.of(context).colorScheme.primary),
        title: Text(l10n.language),
        subtitle: Text(languageName),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textGrey),
        onTap: () => _showLanguageSheet(context, ref),
      ),
    );
  }

  void _showLanguageSheet(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final currentCode = ref.read(localeProvider)?.languageCode;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDesignConstants.radiusExtraLarge),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(l10n.changeLanguage, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              ListTile(
                leading: const Text('🇺🇸', style: TextStyle(fontSize: 22)),
                title: Text(l10n.languageEnglish, style: Theme.of(context).textTheme.bodyLarge),
                trailing: currentCode == 'en'
                    ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () async {
                  await ref.read(localeProvider.notifier).setLocale(const Locale('en'));
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Text('🇸🇦', style: TextStyle(fontSize: 22)),
                title: Text(l10n.languageArabic, style: Theme.of(context).textTheme.bodyLarge),
                trailing: currentCode == 'ar'
                    ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () async {
                  await ref.read(localeProvider.notifier).setLocale(const Locale('ar'));
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationToggle extends StatefulWidget {
  @override
  State<_NotificationToggle> createState() => _NotificationToggleState();
}

class _NotificationToggleState extends State<_NotificationToggle> {
  bool _isEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  void _loadStatus() async {
    final status = await NotificationService().isNotificationEnabled();
    setState(() => _isEnabled = status);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: SwitchListTile(
        secondary: Icon(
          _isEnabled ? Icons.notifications_active : Icons.notifications_off,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(l10n.notifications),
        subtitle: Text(l10n.receiveAlerts),
        value: _isEnabled,
        onChanged: (v) async {
          setState(() => _isEnabled = v);
          await NotificationService().setNotificationEnabled(v);
        },
      ),
    );
  }
}

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _changePassword() async {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController oldPass = TextEditingController();
    final TextEditingController newPass = TextEditingController();
    bool loading = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(l10n.changePassword),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPass,
                  obscureText: true,
                  decoration: InputDecoration(hintText: l10n.enterCurrentPassword),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: newPass,
                  obscureText: true,
                  decoration: InputDecoration(hintText: l10n.enterNewPassword),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  oldPass.dispose();
                  newPass.dispose();
                  Navigator.pop(context);
                },
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                        final oldP = oldPass.text.trim();
                        final newP = newPass.text.trim();

                        if (oldP.isEmpty || newP.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.fillBothPasswords)),
                          );
                          return;
                        }
                        if (newP.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.passwordMinLength)),
                          );
                          return;
                        }

                        setStateDialog(() => loading = true);

                        try {
                          final cred = EmailAuthProvider.credential(
                            email: user!.email!,
                            password: oldP,
                          );
                          await user!.reauthenticateWithCredential(cred);
                          await user!.updatePassword(newP);

                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.passwordUpdated)),
                            );
                          }
                        } on FirebaseAuthException catch (e) {
                          String message = e.message ?? 'Error';
                          if (e.code == 'wrong-password') message = l10n.currentPasswordIncorrect;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                        } finally {
                          setStateDialog(() => loading = false);
                        }
                      },
                child: loading ? const CircularProgressIndicator() : Text(l10n.change),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _forgotPassword() async {
    final l10n = AppLocalizations.of(context)!;
    final email = user?.email;
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noEmailFound)),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.resetPassword),
        content: Text(l10n.resetPasswordConfirm(email)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.send)),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.passwordResetSent)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.genericError(e.toString()))),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    if (user == null) return;
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController passwordController = TextEditingController();
    bool loading = false;

    final reauthOk = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(l10n.confirmPassword),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.confirmPasswordToDelete),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(hintText: l10n.currentPassword),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
              ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                        final pw = passwordController.text.trim();
                        if (pw.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.enterPassword)),
                          );
                          return;
                        }
                        setStateDialog(() => loading = true);
                        try {
                          final cred = EmailAuthProvider.credential(
                            email: user!.email!,
                            password: pw,
                          );
                          await user!.reauthenticateWithCredential(cred);
                          Navigator.pop(context, true);
                        } on FirebaseAuthException catch (e) {
                          String msg = e.message ?? 'Error';
                          if (e.code == 'wrong-password') msg = l10n.passwordIncorrect;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                          setStateDialog(() => loading = false);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                          setStateDialog(() => loading = false);
                        }
                      },
                child: loading ? const CircularProgressIndicator() : Text(l10n.confirm),
              ),
            ],
          );
        },
      ),
    );

    if (reauthOk != true) return;

    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.deleteAccount),
        content: Text(l10n.confirmDeleteAccount),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.delete)),
        ],
      ),
    );

    if (confirmDelete != true) return;

    try {
      final uid = user!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).delete().catchError((_) {});
      await user!.delete();
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String message = e.message ?? 'Error deleting account';
      if (e.code == 'requires-recent-login') message = l10n.reLoginRequired;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.genericError(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final email = user?.email ?? l10n.notAvailable;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.account)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(Icons.email_outlined, color: Theme.of(context).colorScheme.primary),
              title: Text(l10n.email),
              subtitle: Text(email),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.primary),
              title: Text(l10n.changePassword),
              onTap: _changePassword,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: Icon(Icons.mail_outline, color: Theme.of(context).colorScheme.primary),
              title: Text(l10n.forgotPassword),
              subtitle: Text(l10n.sendResetLinkTo(email)),
              onTap: _forgotPassword,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_forever_outlined, color: AppColors.bloodRed),
              title: Text(l10n.deleteAccount, style: const TextStyle(color: AppColors.bloodRed)),
              subtitle: Text(l10n.permanentlyDeleteData),
              onTap: _deleteAccount,
            ),
          ),
        ],
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.about)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.appTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(l10n.aboutDescription, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 20),
            Text(l10n.developedBy("Almohsen Shams"), style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class PrivacyTermsScreen extends StatelessWidget {
  final bool isPrivacy;
  const PrivacyTermsScreen({super.key, required this.isPrivacy});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final title = isPrivacy ? l10n.privacyPolicy : l10n.termsConditions;
    final text = isPrivacy ? l10n.privacyPolicyContent : l10n.termsConditionsContent;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(text, style: theme.textTheme.bodyLarge?.copyWith(height: 1.6)),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/core/theme/app_design_constants.dart';
import 'package:sheryan/l10n/app_localizations.dart';

class DeveloperProfileScreen extends StatelessWidget {
  const DeveloperProfileScreen({super.key});

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch URL')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.developerProfileTitle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            // Profile Header
            Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.primary, width: 2),
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: colorScheme.primary.withOpacity(0.1),
                  child: Icon(Icons.person, size: 70, color: colorScheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.developerName,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                l10n.developerBio,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Social Links Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildSocialCard(
                    context: context,
                    icon: Icons.code_rounded,
                    title: 'GitHub',
                    subtitle: '@AlmohsenMyya',
                    color: Colors.black,
                    onTap: () => _launchUrl(context, 'https://github.com/AlmohsenMyya'),
                  ),
                  const SizedBox(height: 12),
                  _buildSocialCard(
                    context: context,
                    icon: Icons.work_outline_rounded,
                    title: 'LinkedIn',
                    subtitle: 'Almohsen Myya',
                    color: const Color(0xFF0077B5),
                    onTap: () => _launchUrl(context, 'https://www.linkedin.com/in/almohsen-myya-79230022b'),
                  ),
                  const SizedBox(height: 12),
                  _buildSocialCard(
                    context: context,
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'WhatsApp',
                    subtitle: '+963 996 367 749',
                    color: const Color(0xFF25D366),
                    onTap: () {
                      final whatsappUrl = "https://wa.me/963996367749?text=${Uri.encodeComponent(l10n.whatsappSupportMessage)}";
                      _launchUrl(context, whatsappUrl);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppDesignConstants.borderRadiusMedium,
        side: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
        trailing: const Icon(Icons.open_in_new_rounded, size: 18),
        onTap: onTap,
      ),
    );
  }
}

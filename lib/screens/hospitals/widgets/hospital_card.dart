import 'package:flutter/material.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/core/theme/app_design_constants.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class HospitalCard extends StatelessWidget {
  final Map<String, dynamic> hospital;

  const HospitalCard({super.key, required this.hospital});

  Future<void> _makeCall(BuildContext context, String? phone) async {
    final l10n = AppLocalizations.of(context)!;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noPhoneNumber)),
      );
      return;
    }
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cannotMakeCall)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final name = hospital['name'] as String? ?? l10n.unknown;
    final city = hospital['city'] as String? ?? '';
    final phone = hospital['phone'] as String?;
    final address = hospital['address'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.medicalBlue.withOpacity(0.1),
                borderRadius: AppDesignConstants.borderRadiusMedium,
              ),
              child: const Icon(Icons.local_hospital, color: AppColors.medicalBlue, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          address ?? city,
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (phone != null && phone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone_in_talk, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          phone,
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.phone, color: AppColors.success),
              onPressed: () => _makeCall(context, phone),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.success.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sheryan/core/enums/user_role.dart';
import 'package:sheryan/core/theme/app_design_constants.dart';
import 'package:sheryan/l10n/app_localizations.dart';

class UserWelcomeHeader extends StatelessWidget {
  final Map<String, dynamic> userData;
  final UserRole role;

  const UserWelcomeHeader({super.key, required this.userData, required this.role});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = userData['name'] as String? ?? l10n.friend;
    final bloodGroup = userData['bloodGroup'] as String? ?? '-';
    final city = userData['city'] as String? ?? '-';
    
    final hour = DateTime.now().hour;
    final greetingPrefix = hour < 12
        ? l10n.goodMorning
        : hour < 18
            ? l10n.goodAfternoon
            : l10n.goodEvening;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppDesignConstants.borderRadiusLarge,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greetingPrefix,',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      city,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              _headerStatItem(l10n.bloodGroup, bloodGroup, Icons.bloodtype_outlined),
              const SizedBox(width: 20),
              _headerStatItem(
                role == UserRole.donor ? l10n.myPoints : l10n.myRequests,
                role == UserRole.donor ? '${userData['points'] ?? 0}' : '${userData['requestCount'] ?? 0}',
                role == UserRole.donor ? Icons.stars_outlined : Icons.favorite_border,
              ),
              const Spacer(),
              Center(
                child: Image.asset(
                  'assets/logo.png',
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStatItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

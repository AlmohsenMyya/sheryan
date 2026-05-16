import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/providers/emergency/emergency_provider.dart';
import 'package:sheryan/screens/donors/request_response_screen.dart';

class EmergencyAlertsTab extends ConsumerWidget {
  const EmergencyAlertsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestId = ref.watch(lastEmergencyRequestIdProvider);
    final l10n = AppLocalizations.of(context)!;

    if (requestId == null) {
      return _buildEmptyState(context, l10n);
    }

    // In a real production scenario, RequestResponseScreen might need a "isEmbedded" flag 
    // to hide its Scaffold/AppBar, but for this refactor we'll push the screen or 
    // display it. The blueprint says "embed or push". We will push it for better UX 
    // if the user interacts, but since it's a tab, we'll embed the CONTENT.
    return RequestResponseScreen(requestId: requestId);
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 80,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.allClearTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.allClearSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Optional: Button to refresh or check nearby history
          ],
        ),
      ),
    );
  }
}

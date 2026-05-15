import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/core/theme/app_design_constants.dart';
import 'package:sheryan/l10n/app_localizations.dart';

class MotivationalBanner extends ConsumerStatefulWidget {
  const MotivationalBanner({super.key});

  @override
  ConsumerState<MotivationalBanner> createState() => _MotivationalBannerState();
}

class _MotivationalBannerState extends ConsumerState<MotivationalBanner> {
  String _currentQuote = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (_currentQuote.isEmpty) {
      final quotes = [
        l10n.quote1, l10n.quote2, l10n.quote3, l10n.quote4,
        l10n.quote5, l10n.quote6, l10n.quote7,
      ];
      _currentQuote = (List.from(quotes)..shuffle()).first;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bloodRedLight.withOpacity(0.3),
        borderRadius: AppDesignConstants.borderRadiusMedium,
        border: Border.all(color: AppColors.bloodRed.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.format_quote, color: AppColors.bloodRed, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.motivationTitle,
                  style: const TextStyle(
                    color: AppColors.bloodRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentQuote,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

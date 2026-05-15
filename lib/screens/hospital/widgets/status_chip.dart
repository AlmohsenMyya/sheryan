import 'package:flutter/material.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/l10n/app_localizations.dart';

class StatusChip extends StatelessWidget {
  final String statusKey;

  const StatusChip({super.key, required this.statusKey});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final Color bg;
    final Color fg;
    final String label;

    switch (statusKey) {
      case 'done':
      case 'completed':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        label = l10n.statusCompleted;
        break;
      case 'verified':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        label = l10n.statusVerified;
        break;
      default:
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade700;
        label = l10n.statusUnverified;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

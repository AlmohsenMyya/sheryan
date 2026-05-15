import 'package:flutter/material.dart';
import 'package:sheryan/l10n/app_localizations.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String label;
    switch (status) {
      case 'done':
      case 'completed':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        label = AppLocalizations.of(context)!.statusDone;
      case 'verified':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        label = AppLocalizations.of(context)!.statusVerified;
      default:
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade700;
        label = AppLocalizations.of(context)!.statusPending;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/providers/connectivity/connectivity_provider.dart';

class OfflineBanner extends ConsumerStatefulWidget {
  const OfflineBanner({super.key});

  @override
  ConsumerState<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends ConsumerState<OfflineBanner> {
  bool _prevOnline = true;
  bool _showBackOnline = false;

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(connectivityProvider);
    final l10n = AppLocalizations.of(context)!;

    if (!_prevOnline && isOnline && !_showBackOnline) {
      _showBackOnline = true;
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showBackOnline = false);
      });
    }
    _prevOnline = isOnline;

    if (isOnline && !_showBackOnline) return const SizedBox.shrink();

    if (_showBackOnline && isOnline) {
      return Container(
        width: double.infinity,
        color: Colors.green.shade700,
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.wifi, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              l10n.backOnlineMessage,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      color: Colors.orange.shade800,
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.offlineBannerTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  l10n.offlineBannerSubtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

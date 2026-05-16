import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/screens/requests/providers/staged_notification_provider.dart';
import 'package:sheryan/services/staged_notification_service.dart';

class StagedCooldownBanner extends ConsumerStatefulWidget {
  final String requestId;

  const StagedCooldownBanner({super.key, required this.requestId});

  @override
  ConsumerState<StagedCooldownBanner> createState() => _StagedCooldownBannerState();
}

class _StagedCooldownBannerState extends ConsumerState<StagedCooldownBanner> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _isProcessing = false;
  bool _poolExhausted = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateRemaining();
    });
  }

  void _calculateRemaining() {
    final requestAsync = ref.read(requestStreamProvider(widget.requestId));
    requestAsync.whenData((data) {
      if (data == null) return;

      final Timestamp? lastSent = data['lastNotificationSentAt'];
      if (lastSent == null) {
        if (mounted) setState(() => _remaining = Duration.zero);
        return;
      }

      final DateTime targetTime = lastSent.toDate().add(const Duration(minutes: 30));
      final DateTime now = DateTime.now();
      
      final diff = targetTime.difference(now);
      if (mounted) {
        setState(() {
          _remaining = diff.isNegative ? Duration.zero : diff;
        });
      }
    });
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  Future<void> _notifyMore() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await StagedNotificationService().dispatchNextBatch(widget.requestId);
    } catch (e) {
      // Logic inside service handles "pool exhausted" via logging, 
      // but we can catch errors if the transaction fails or custom flags are added.
      if (e.toString().contains("No more eligible donors")) {
        setState(() => _poolExhausted = true);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final requestAsync = ref.watch(requestStreamProvider(widget.requestId));

    return requestAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
      data: (data) {
        if (data == null) return const SizedBox.shrink();

        // 🛑 Hard Blocker: Hide if status is done/completed or request isn't verified yet
        final String status = data['status'] ?? 'pending';
        final bool isVerified = data['isVerified'] ?? false;
        if (status == 'done' || status == 'completed' || !isVerified) {
          return const SizedBox.shrink();
        }

        final int notifiedCount = (data['notifiedDonorIds'] as List?)?.length ?? 0;
        final bool isCooldown = _remaining.inSeconds > 0;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.campaign_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.stagedNotifiedCount(notifiedCount),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildActionButton(l10n, isCooldown),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(AppLocalizations l10n, bool isCooldown) {
    if (_poolExhausted) {
      return OutlinedButton(
        onPressed: null,
        child: Text(l10n.allDonorsNotified),
      );
    }

    if (_isProcessing) {
      return FilledButton(
        onPressed: null,
        child: const SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );
    }

    if (isCooldown) {
      return FilledButton.tonal(
        onPressed: null,
        child: Text(l10n.nextBatchAvailable(_formatDuration(_remaining))),
      );
    }

    return FilledButton.icon(
      onPressed: _notifyMore,
      icon: const Icon(Icons.send_rounded, size: 18),
      label: Text(l10n.notifyMoreDonors),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/core/theme/app_design_constants.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/services/points_service.dart';

class ScanRedeemScreen extends StatefulWidget {
  final Map<String, dynamic> reward;
  const ScanRedeemScreen({super.key, required this.reward});

  @override
  State<ScanRedeemScreen> createState() => _ScanRedeemScreenState();
}

class _ScanRedeemScreenState extends State<ScanRedeemScreen> {
  final MobileScannerController _scanner = MobileScannerController();
  final PointsService _pts = PointsService();
  bool _processing = false;
  bool _done = false;
  String? _statusMsg;
  bool _success = false;

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _handleScan(String donorUid) async {
    if (_processing || _done) return;
    setState(() => _processing = true);
    _scanner.stop();

    final l10n = AppLocalizations.of(context)!;
    final sponsorUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final required =
        (widget.reward['pointsRequired'] as int?) ?? 0;
    final rewardId = widget.reward['id'] as String? ?? '';
    final rewardTitle = widget.reward['title'] as String? ?? '';

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(donorUid)
          .get();

      if (!userDoc.exists) {
        setState(() {
          _statusMsg = l10n.invalidQr;
          _success = false;
          _done = true;
          _processing = false;
        });
        return;
      }

      final donorName = userDoc.data()?['name'] as String? ?? donorUid;
      final hasDonated = (userDoc.data()?['hasDonated'] as bool?) ?? false;

      if (!hasDonated) {
        setState(() {
          _success = false;
          _statusMsg = '${l10n.redeemLockedMessage}\n($donorName)';
          _done = true;
          _processing = false;
        });
        return;
      }

      final ok = await _pts.deductPoints(
        donorUid: donorUid,
        sponsorUid: sponsorUid,
        rewardId: rewardId,
        rewardTitle: rewardTitle,
        pointsRequired: required,
      );

      setState(() {
        _success = ok;
        _statusMsg = ok
            ? '${l10n.redeemSuccess}\n$donorName'
            : '${l10n.insufficientPoints}\n$donorName';
        _done = true;
        _processing = false;
      });
    } catch (e) {
      setState(() {
        _statusMsg = e.toString();
        _success = false;
        _done = true;
        _processing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final required = (widget.reward['pointsRequired'] as int?) ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.scanDonorQrRedeem)),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.primaryRed.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.card_giftcard,
                    color: AppColors.primaryRed, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.reward['title'] as String? ?? '',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$required ⭐ ${l10n.pointsRequired}',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.primaryRed),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!_done) ...[
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: MobileScanner(
                      controller: _scanner,
                      onDetect: (capture) {
                        final code =
                            capture.barcodes.firstOrNull?.rawValue;
                        if (code != null) _handleScan(code);
                      },
                    ),
                  ),
                  if (_processing)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                          child: CircularProgressIndicator(
                              color: Colors.white)),
                    ),
                  Positioned(
                    bottom: 24,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          l10n.scanDonorQrRedeem,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Expanded(
              child: Center(
                child: Padding(
                  padding: AppDesignConstants.edgeInsetsMedium,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _success
                            ? Icons.check_circle
                            : Icons.cancel,
                        size: 80,
                        color:
                            _success ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _statusMsg ?? '',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: Text(l10n.close),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

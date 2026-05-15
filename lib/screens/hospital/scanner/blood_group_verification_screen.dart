import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import '../controllers/scanner_controller.dart';

class BloodGroupVerificationScreen extends ConsumerWidget {
  const BloodGroupVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(scannerProvider);
    final controller = ref.read(scannerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.verifyDonorBloodGroup), backgroundColor: Colors.deepPurple),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final code = capture.barcodes.firstOrNull?.rawValue;
              if (code != null) {
                controller.handleBloodGroupVerify(context, code);
              }
            },
          ),
          Center(child: Container(width: 250, height: 250, decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2), borderRadius: BorderRadius.circular(12)))),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
              child: Text(l10n.scanDonorQrForVerification, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
          if (state.isProcessing) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

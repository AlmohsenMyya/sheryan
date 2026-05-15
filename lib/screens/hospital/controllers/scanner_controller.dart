import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sheryan/events/app_event.dart';
import 'package:sheryan/events/notification_engine.dart';
import 'package:sheryan/services/donation_service.dart';
import 'package:sheryan/services/request_service.dart';
import 'package:sheryan/services/user_service.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/providers/auth/auth_provider.dart';

// ─── Scanner State ──────────────────────────────────────────────────────────
class ScannerState {
  final String? donorId;
  final String? requestId;
  final bool isProcessing;

  ScannerState({
    this.donorId,
    this.requestId,
    this.isProcessing = false,
  });

  ScannerState copyWith({
    String? donorId,
    String? requestId,
    bool? isProcessing,
  }) {
    return ScannerState(
      donorId: donorId ?? this.donorId,
      requestId: requestId ?? this.requestId,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

// ─── Scanner Notifier (Controller) ──────────────────────────────────────────
class ScannerNotifier extends StateNotifier<ScannerState> {
  // تمرير الـ ref هنا لكي نتمكن من قراءة البروفايدرات الأخرى (مثل userProfileProvider)
  final Ref ref;

  ScannerNotifier(this.ref) : super(ScannerState());

  Future<void> handleScan({
    required BuildContext context,
    required String code,
    required bool isVerifyOnly,
    required bool isGeneral,
  }) async {
    if (state.isProcessing) return;
    state = state.copyWith(isProcessing: true);

    if (isVerifyOnly) {
      await _handleVerifyRequest(context, code);
    } else if (isGeneral) {
      await _handleGeneralDonationScan(context, code);
    } else {
      if (state.donorId == null) {
        await _handleDonorScan(context, code);
      } else {
        await _handleRequestScan(context, code);
      }
    }

    // التأكد من أن المكون لم يتم تدميره قبل تحديث الحالة
    if (mounted) {
      state = state.copyWith(isProcessing: false);
    }
  }

  Future<void> _handleVerifyRequest(BuildContext context, String id) async {
    final l10n = AppLocalizations.of(context)!;
    final adminProfile = ref.read(userProfileProvider).value;
    final myHospitalId = adminProfile?['hospitalId'];

    try {
      final requestData = await RequestService().getById(id);
      if (requestData == null) throw Exception(l10n.invalidQr);
      if (requestData['hospitalId'] != myHospitalId) {
        throw Exception(l10n.invalidHospital);
      }

      await RequestService().markVerified(id);
      NotificationEngine().dispatch(BloodRequestVerifiedEvent(
        requestId: id,
        requesterId: requestData['userId'] as String?,
        city: requestData['city'] ?? '',
        bloodGroup: requestData['bloodGroup'] ?? '',
      ));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.verifySuccess)));
        Navigator.pop(context);
      }
    } catch (e) {
      _showError(context, e.toString());
    }
  }

  Future<void> _handleDonorScan(BuildContext context, String id) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final doc = await UserService().getById(id);
      if (doc == null) throw Exception(l10n.invalidQr);
      if (doc['role'] != 'donor') {
        throw Exception('QR does not belong to a donor');
      }

      if (mounted) {
        state = state.copyWith(donorId: id);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.donorDetected(doc['name'] ?? l10n.unknown))),
        );
      }
    } catch (e) {
      _showError(context, e.toString());
    }
  }

  Future<void> _handleGeneralDonationScan(BuildContext context, String id) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final doc = await UserService().getById(id);
      if (doc == null) throw Exception(l10n.invalidQr);
      if (doc['role'] != 'donor') {
        throw Exception('QR does not belong to a donor');
      }

      if (!context.mounted) return;

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.confirmGeneralDonationTitle),
          content: Text(l10n.confirmGeneralDonationBody),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel)),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.confirm)),
          ],
        ),
      );

      if (confirm == true) {
        final adminProfile = ref.read(userProfileProvider).value;
        await DonationService().registerGeneralDonation(
          donorId: id,
          hospitalId: adminProfile?['hospitalId'] as String? ?? '',
          hospitalName: adminProfile?['name'] as String? ?? '',
          adminUid: adminProfile?['uid'] as String? ?? '',
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.generalDonationSuccess)));
          Navigator.pop(context);
        }
      }
    } catch (e) {
      _showError(context, e.toString());
    }
  }

  Future<void> _handleRequestScan(BuildContext context, String id) async {
    final l10n = AppLocalizations.of(context)!;
    final adminProfile = ref.read(userProfileProvider).value;
    final myHospitalId = adminProfile?['hospitalId'];

    try {
      final requestData = await RequestService().getById(id);
      if (requestData == null) throw Exception(l10n.invalidQr);
      if (requestData['hospitalId'] != myHospitalId) {
        throw Exception(l10n.invalidHospital);
      }

      if (!context.mounted) return;

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.confirmDonationTitle),
          content: Text(l10n.confirmDonationBody),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel)),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.confirm)),
          ],
        ),
      );

      if (confirm == true) {
        final result = await DonationService().registerDonation(
          donorId: state.donorId!,
          requestId: id,
          hospitalId: adminProfile?['hospitalId'] as String? ?? '',
          hospitalName: adminProfile?['name'] as String? ?? '',
          adminUid: adminProfile?['uid'] as String? ?? '',
        );

        NotificationEngine().dispatch(DonationRegisteredEvent(
          donorId: state.donorId!,
          requestId: id,
          requesterId: result.requestData?['userId'] as String?,
        ));

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.donationSuccess)));
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          state = state.copyWith(requestId: null);
        }
      }
    } catch (e) {
      _showError(context, e.toString());
    }
  }

  Future<void> handleBloodGroupVerify(BuildContext context, String code) async {
    if (state.isProcessing) return;
    if (mounted) {
      state = state.copyWith(isProcessing: true);
    }

    final l10n = AppLocalizations.of(context)!;

    try {
      final data = await UserService().getById(code);
      if (data == null) throw Exception(l10n.invalidQr);
      if (data['role'] != 'donor') {
        throw Exception('This QR does not belong to a donor');
      }

      if (context.mounted) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.bloodGroupVerificationTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data['bloodGroupVerified'] == true)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      const Icon(Icons.check_circle,
                          color: AppColors.success, size: 18),
                      const SizedBox(width: 8),
                      Text(l10n.bloodGroupAlreadyVerified,
                          style: const TextStyle(color: AppColors.success))
                    ]),
                  ),
                const SizedBox(height: 12),
                _infoRow(context, Icons.person, l10n.name, data['name'] ?? '—'),
                const SizedBox(height: 8),
                _infoRow(context, Icons.bloodtype, l10n.bloodGroup,
                    data['bloodGroup'] ?? '—'),
                const SizedBox(height: 8),
                _infoRow(context, Icons.location_city, l10n.city,
                    data['city'] ?? '—'),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.cancel)),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple),
                icon: const Icon(Icons.verified, size: 18),
                label: Text(l10n.confirmBloodGroupVerification),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await UserService().markBloodGroupVerified(code);
          NotificationEngine().dispatch(BloodGroupVerifiedEvent(
            donorId: code,
            bloodGroup: data['bloodGroup'] as String? ?? '',
          ));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(l10n.bloodGroupVerifiedSuccess),
                backgroundColor: AppColors.success));
            Navigator.pop(context);
          }
        }
      }
    } catch (e) {
      _showError(context, e.toString());
    } finally {
      if (mounted) {
        state = state.copyWith(isProcessing: false);
      }
    }
  }

  Widget _infoRow(
      BuildContext context, IconData icon, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurface.withOpacity(0.5)),
        const SizedBox(width: 8),
        Text('$label: ',
            style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.5), fontSize: 13)),
        Expanded(
            child: Text(value,
                style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.bold))),
      ],
    );
  }

  void _showError(BuildContext context, String msg) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(msg.replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error),
      );
    }
  }
}

// ─── Provider Declaration ───────────────────────────────────────────────────
final scannerProvider =
StateNotifierProvider.autoDispose<ScannerNotifier, ScannerState>((ref) {
  return ScannerNotifier(ref);
});
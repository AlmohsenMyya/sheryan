import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheryan/events/app_event.dart';
import 'package:sheryan/events/notification_engine.dart';
import 'package:sheryan/services/request_service.dart';
import 'package:sheryan/services/user_service.dart';
import 'package:sheryan/services/donation_service.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/core/theme/app_colors.dart';

final hospitalRequestsProvider = Provider((ref) => HospitalRequestsController(ref));

class HospitalRequestsController {
  final Ref _ref;
  final RequestService _requestService = RequestService();
  final UserService _userService = UserService();
  final DonationService _donationService = DonationService();

  HospitalRequestsController(this._ref);

  Future<void> markVerified(BuildContext context, Map<String, dynamic> doc) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final requestId = doc['id'] as String;
      await _requestService.markVerified(requestId);

      NotificationEngine().dispatch(BloodRequestVerifiedEvent(
        requestId: requestId,
        requesterId: doc['userId'] as String?,
        city: doc['city'] ?? '',
        bloodGroup: doc['bloodGroup'] ?? '',
      ));

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.verifySuccess), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> lookupDonor(BuildContext context, String uid) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final doc = await _userService.getById(uid);
      if (doc == null) throw Exception(l10n.donorNotFound);
      return doc;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error),
        );
      }
      return null;
    }
  }

  Future<void> completeManualDonation({
    required BuildContext context,
    required String donorId,
    required String requestId,
    required String hospitalId,
    required String hospitalName,
    required String adminUid,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final result = await _donationService.registerDonation(
        donorId: donorId,
        requestId: requestId,
        hospitalId: hospitalId,
        hospitalName: hospitalName,
        adminUid: adminUid,
        manualOverride: true,
      );

      NotificationEngine().dispatch(DonationRegisteredEvent(
        donorId: donorId,
        requestId: requestId,
        requesterId: result.requestData?['userId'] as String?,
      ));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.donationSuccess), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }
}

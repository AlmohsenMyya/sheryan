import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheryan/services/hospital_service.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/core/theme/app_colors.dart';

final hospitalProfileControllerProvider = Provider((ref) => HospitalProfileController());

class HospitalProfileController {
  final HospitalService _service = HospitalService();

  Future<void> updateProfile({
    required BuildContext context,
    required String hospitalId,
    required String name,
    required String city,
    required String phone,
    required String address,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _service.updateHospital(
        hospitalId,
        name: name,
        city: city,
        phone: phone,
        address: address,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.hospitalInfoUpdated)),
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

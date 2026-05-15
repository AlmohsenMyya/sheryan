import 'package:flutter/material.dart';
import 'package:sheryan/core/theme/app_colors.dart';

class BloodGroupBadge extends StatelessWidget {
  final String bloodGroup;
  const BloodGroupBadge({super.key, required this.bloodGroup});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryRed.withOpacity(0.3)),
      ),
      child: Text(bloodGroup,
          style: const TextStyle(
              color: AppColors.primaryRed,
              fontSize: 12,
              fontWeight: FontWeight.bold)),
    );
  }
}

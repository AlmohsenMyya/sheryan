import 'package:flutter/material.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/core/theme/app_design_constants.dart';

class ProfileHeader extends StatelessWidget {
  final String name;
  final String bloodGroup;
  final String email;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.bloodGroup,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.medicalBlue, Color(0xFF0E7490)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppDesignConstants.borderRadiusLarge,
        boxShadow: [
          BoxShadow(
            color: AppColors.medicalBlue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // استخدمنا Row بدلاً من Column لحل مشكلة التكديس
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. الصورة الشخصية مع شارة زمرة الدم
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 35, // تصغير بسيط لتتناسب مع التخطيط الأفقي
                  backgroundColor: AppColors.medicalBlue.withOpacity(0.1),
                  child: const Icon(Icons.person, size: 40, color: AppColors.medicalBlue),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.bloodRed,
                  shape: BoxShape.circle,
                  // إضافة حدود بيضاء للشارة لتبدو بارزة وجميلة
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  bloodGroup,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          // 2. بيانات المستخدم (الاسم والإيميل)
          // استخدمنا Expanded لمنع طفح النص (Overflow) إذا كان الاسم طويلاً
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // محاذاة النصوص للبداية
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // يأخذ أقل مساحة عمودية
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // 3. لوغو التطبيق
          // وضعه داخل حاوية شفافة يعطيه مظهراً أنيقاً كعلامة مائية
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              'assets/logo.png',
              height: 35,
              width: 35,
              fit: BoxFit.contain,
            ),

          ),

        ],
      ),
    );
  }
}